import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../invoice/views/invoice_history_screen.dart';
import '../../../core/providers/shortcuts_provider.dart';
import '../../../core/utils/navigation.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _df = DateFormat('dd/MM/yyyy');
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _activePreset = '30days'; // 'today', 'thismonth', 'thisyear', '30days', 'custom'

  void _applyPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _activePreset = preset;
      if (preset == 'today') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
      } else if (preset == 'thismonth') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      } else if (preset == 'thisyear') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
      } else if (preset == '30days') {
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
      }
    });
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _activePreset = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _exportCsv(List<Invoice> filtered) async {
    try {
      final buffer = StringBuffer();
      // CSV Headers
      buffer.writeln('Date,Invoice No,Customer,GSTIN,Taxable Subtotal (Rs.),CGST (Rs.),SGST (Rs.),Total GST (Rs.),Grand Total (Rs.)');

      // Row Data
      for (final inv in filtered) {
        final gstin = inv.customerGstNumber ?? '';
        buffer.writeln(
          '"${_df.format(inv.invoiceDate)}",${inv.invoiceNumber},"${inv.customerName}","${gstin}",${inv.subTotal},${inv.cgst},${inv.sgst},${inv.totalGst},${inv.grandTotal}',
        );
      }

      final csvContent = buffer.toString();
      final path = await FilePicker.saveFile(
        dialogTitle: 'Export CSV Report',
        fileName: 'gst_tax_report_${DateFormat('yyyyMMdd').format(_startDate)}_to_${DateFormat('yyyyMMdd').format(_endDate)}.csv',
      );

      if (path != null) {
        await File(path).writeAsString(csvContent);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report exported to $path'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportPdf(List<Invoice> filtered) async {
    try {
      final pdf = pw.Document();

      // Metrics
      final subtotal = filtered.fold(0.0, (s, i) => s + i.subTotal);
      final cgst = filtered.fold(0.0, (s, i) => s + i.cgst);
      final sgst = filtered.fold(0.0, (s, i) => s + i.sgst);
      final totalGst = filtered.fold(0.0, (s, i) => s + i.totalGst);
      final grandTotal = filtered.fold(0.0, (s, i) => s + i.grandTotal);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              pw.Text(
                "GST SALES TAX REPORT",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0B3B60)),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Reporting Period: ${_df.format(_startDate)} to ${_df.format(_endDate)}",
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 16),
              
              // Totals summary grid in PDF
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF499F34)),
                    children: [
                      _pdfHeaderCell("Taxable Amt"),
                      _pdfHeaderCell("CGST Collected"),
                      _pdfHeaderCell("SGST Collected"),
                      _pdfHeaderCell("Total GST"),
                      _pdfHeaderCell("Grand Total"),
                    ]
                  ),
                  pw.TableRow(
                    children: [
                      _pdfBodyCell(subtotal.toStringAsFixed(2)),
                      _pdfBodyCell(cgst.toStringAsFixed(2)),
                      _pdfBodyCell(sgst.toStringAsFixed(2)),
                      _pdfBodyCell(totalGst.toStringAsFixed(2)),
                      _pdfBodyCell(grandTotal.toStringAsFixed(2), isBold: true),
                    ]
                  )
                ]
              ),
              pw.SizedBox(height: 24),

              pw.Text("Transaction Log Summary", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.SizedBox(height: 8),

              // Transaction table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(45), // Date
                  1: const pw.FixedColumnWidth(55), // Inv No
                  2: const pw.FlexColumnWidth(2),  // Customer
                  3: const pw.FixedColumnWidth(60), // Subtotal
                  4: const pw.FixedColumnWidth(55), // Tax
                  5: const pw.FixedColumnWidth(60), // Total
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _pdfHeaderCell("Date", color: PdfColors.black),
                      _pdfHeaderCell("Invoice No", color: PdfColors.black),
                      _pdfHeaderCell("Customer", color: PdfColors.black),
                      _pdfHeaderCell("Taxable (Rs.)", color: PdfColors.black),
                      _pdfHeaderCell("GST (Rs.)", color: PdfColors.black),
                      _pdfHeaderCell("Total (Rs.)", color: PdfColors.black),
                    ]
                  ),
                  ...filtered.map((inv) => pw.TableRow(
                    children: [
                      _pdfBodyCell(_df.format(inv.invoiceDate)),
                      _pdfBodyCell(inv.invoiceNumber),
                      _pdfBodyCell(inv.customerName),
                      _pdfBodyCell(inv.subTotal.toStringAsFixed(2), align: pw.TextAlign.right),
                      _pdfBodyCell(inv.totalGst.toStringAsFixed(2), align: pw.TextAlign.right),
                      _pdfBodyCell(inv.grandTotal.toStringAsFixed(2), align: pw.TextAlign.right),
                    ]
                  ))
                ]
              )
            ];
          }
        )
      );

      final pdfBytes = await pdf.save();
      final path = await FilePicker.saveFile(
        dialogTitle: 'Export PDF Report',
        fileName: 'gst_tax_report_${DateFormat('yyyyMMdd').format(_startDate)}_to_${DateFormat('yyyyMMdd').format(_endDate)}.pdf',
      );

      if (path != null) {
        await File(path).writeAsBytes(pdfBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report exported to $path'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  pw.Widget _pdfHeaderCell(String text, {PdfColor color = PdfColors.white}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _pdfBodyCell(String text, {pw.TextAlign align = pw.TextAlign.center, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: align,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoicesVal = ref.watch(invoicesStreamProvider);
    final shortcuts = ref.watch(shortcutsProvider);

    final isWide = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Taxation'),
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => layoutScaffoldKey.currentState?.openDrawer(),
              ),
      ),
      body: invoicesVal.when(
        data: (list) {
          // Normalize start and end times to encompass full days
          final startNormal = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
          final endNormal = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

          final filtered = list.where((inv) =>
              inv.invoiceDate.isAfter(startNormal) &&
              inv.invoiceDate.isBefore(endNormal)).toList();

          // Calculate aggregate metrics
          final totalTaxable = filtered.fold(0.0, (s, i) => s + i.subTotal);
          final totalCgst = filtered.fold(0.0, (s, i) => s + i.cgst);
          final totalSgst = filtered.fold(0.0, (s, i) => s + i.sgst);
          final totalGst = filtered.fold(0.0, (s, i) => s + i.totalGst);
          final totalRevenue = filtered.fold(0.0, (s, i) => s + i.grandTotal);

          // Local shortcut bindings
          final Map<ShortcutActivator, VoidCallback> bindings = {};
          final excelShortcut = shortcuts['exportExcel'];
          if (excelShortcut != null) {
            bindings[SingleActivator(excelShortcut.key, control: excelShortcut.control, shift: excelShortcut.shift, alt: excelShortcut.alt)] = () {
              if (filtered.isNotEmpty) {
                _exportCsv(filtered);
              }
            };
          }
          final pdfReportShortcut = shortcuts['exportPdfReport'];
          if (pdfReportShortcut != null) {
            bindings[SingleActivator(pdfReportShortcut.key, control: pdfReportShortcut.control, shift: pdfReportShortcut.shift, alt: pdfReportShortcut.alt)] = () {
              if (filtered.isNotEmpty) {
                _exportPdf(filtered);
              }
            };
          }

          return Focus(
            autofocus: true,
            child: CallbackShortcuts(
              bindings: bindings,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filter presets and export actions
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 950;
                        final theme = Theme.of(context);
                        
                        final presetList = [
                          _presetButton('Today', 'today'),
                          _presetButton('Last 30 Days', '30days'),
                          _presetButton('This Month', 'thismonth'),
                          _presetButton('This Year', 'thisyear'),
                           _buildChoiceChip(
                            label: 'Custom Range: ${_df.format(_startDate)} - ${_df.format(_endDate)}',
                            selected: _activePreset == 'custom',
                            onSelected: (_) => _selectCustomRange(),
                          ),
                        ];

                        final exportButtons = [
                          Tooltip(
                            message: excelShortcut != null
                                ? 'Export Excel/CSV (${excelShortcut.displayString})'
                                : 'Export Excel/CSV',
                            child: ElevatedButton.icon(
                              onPressed: filtered.isEmpty ? null : () => _exportCsv(filtered),
                              icon: const Icon(Icons.table_view_rounded, size: 18),
                              label: const Text('Export CSV'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: pdfReportShortcut != null
                                ? 'Export PDF Report (${pdfReportShortcut.displayString})'
                                : 'Export PDF Report',
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              onPressed: filtered.isEmpty ? null : () => _exportPdf(filtered),
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                              label: const Text('Export PDF'),
                            ),
                          ),
                        ];

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: presetList,
                                ),
                              ),
                              Row(children: exportButtons),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: presetList,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: exportButtons,
                              ),
                            ],
                          );
                        }
                      },
                    ),
                
                    const SizedBox(height: 24),
                
                    // Aggregate Metrics Cards Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 1100;
                        final isMedium = constraints.maxWidth >= 650 && constraints.maxWidth < 1100;
                        final theme = Theme.of(context);

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: _summaryCard('Taxable Value', totalTaxable, Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _summaryCard('CGST Collected', totalCgst, AppTheme.accentOrange),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _summaryCard('SGST Collected', totalSgst, AppTheme.accentOrange),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _summaryCard('Total GST Collected', totalGst, theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _summaryCard('Total Revenue', totalRevenue, theme.colorScheme.primary, isRevenue: true),
                              ),
                            ],
                          );
                        } else if (isMedium) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _summaryCard('Taxable Value', totalTaxable, Colors.blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _summaryCard('Total GST Collected', totalGst, theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _summaryCard('CGST Collected', totalCgst, AppTheme.accentOrange),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _summaryCard('SGST Collected', totalSgst, AppTheme.accentOrange),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _summaryCard('Total Revenue', totalRevenue, theme.colorScheme.primary, isRevenue: true),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _summaryCard('Taxable Value', totalTaxable, Colors.blue),
                              const SizedBox(height: 10),
                              _summaryCard('CGST Collected', totalCgst, AppTheme.accentOrange),
                              const SizedBox(height: 10),
                              _summaryCard('SGST Collected', totalSgst, AppTheme.accentOrange),
                              const SizedBox(height: 10),
                              _summaryCard('Total GST Collected', totalGst, theme.colorScheme.primary),
                              const SizedBox(height: 10),
                              _summaryCard('Total Revenue', totalRevenue, theme.colorScheme.primary, isRevenue: true),
                            ],
                          );
                        }
                      },
                    ),
                    
                    const SizedBox(height: 28),

                    // Transactions Log List
                    Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Sales Ledger Log',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.2,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Expanded(
                      child: Card(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No invoices found in selected date range.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(12),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topLeft,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                        Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white.withOpacity(0.02)
                                            : Colors.black.withOpacity(0.01),
                                      ),
                                      columns: [
                                        DataColumn(
                                          label: Text(
                                            'Date',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(context).colorScheme.onSurface),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Invoice No',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(context).colorScheme.onSurface),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Customer',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(context).colorScheme.onSurface),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Taxable Value',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(context).colorScheme.onSurface),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Total GST',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(context).colorScheme.onSurface),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Grand Total',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(context).colorScheme.onSurface),
                                          ),
                                        ),
                                      ],
                                      rows: filtered.map((inv) {
                                        final theme = Theme.of(context);
                                        final rowTextStyle = TextStyle(color: theme.colorScheme.onSurface);
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(_df.format(inv.invoiceDate), style: rowTextStyle)),
                                            DataCell(
                                              Text(
                                                inv.invoiceNumber,
                                                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                              ),
                                            ),
                                            DataCell(Text(inv.customerName, style: rowTextStyle)),
                                            DataCell(Text(_currency.format(inv.subTotal), style: rowTextStyle)),
                                            DataCell(Text(_currency.format(inv.totalGst), style: rowTextStyle)),
                                            DataCell(
                                              Text(
                                                _currency.format(inv.grandTotal),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading reports: $err')),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: selected
            ? (isDark ? Colors.black : Colors.white)
            : theme.colorScheme.onSurface.withOpacity(0.8),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: onSelected,
    );
  }

  Widget _presetButton(String label, String preset) {
    return _buildChoiceChip(
      label: label,
      selected: _activePreset == preset,
      onSelected: (selected) {
        if (selected) {
          _applyPreset(preset);
        }
      },
    );
  }

  Widget _summaryCard(String label, double value, Color accentColor, {bool isRevenue = false}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currency.format(value),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: isRevenue ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
