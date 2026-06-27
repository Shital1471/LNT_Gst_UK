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
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _activePreset = '30days';

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
      buffer.writeln('Date,Invoice No,Customer,GSTIN,Taxable Subtotal (Rs.),CGST (Rs.),SGST (Rs.),Total GST (Rs.),Grand Total (Rs.)');
      for (final inv in filtered) {
        final gstin = inv.customerGstNumber ?? '';
        buffer.writeln(
          '"${_df.format(inv.invoiceDate)}",${inv.invoiceNumber},"${inv.customerName}","$gstin",${inv.subTotal},${inv.cgst},${inv.sgst},${inv.totalGst},${inv.grandTotal}',
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
      final subtotal = filtered.fold(0.0, (s, i) => s + i.subTotal);
      final cgst = filtered.fold(0.0, (s, i) => s + i.cgst);
      final sgst = filtered.fold(0.0, (s, i) => s + i.sgst);
      final totalGst = filtered.fold(0.0, (s, i) => s + i.totalGst);
      final grandTotal = filtered.fold(0.0, (s, i) => i.grandTotal + s);

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
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfBodyCell(subtotal.toStringAsFixed(2)),
                      _pdfBodyCell(cgst.toStringAsFixed(2)),
                      _pdfBodyCell(sgst.toStringAsFixed(2)),
                      _pdfBodyCell(totalGst.toStringAsFixed(2)),
                      _pdfBodyCell(grandTotal.toStringAsFixed(2), isBold: true),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text("Transaction Log Summary", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(45),
                  1: const pw.FixedColumnWidth(55),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FixedColumnWidth(60),
                  4: const pw.FixedColumnWidth(55),
                  5: const pw.FixedColumnWidth(60),
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
                    ],
                  ),
                  ...filtered.map((inv) => pw.TableRow(
                    children: [
                      _pdfBodyCell(_df.format(inv.invoiceDate)),
                      _pdfBodyCell(inv.invoiceNumber),
                      _pdfBodyCell(inv.customerName),
                      _pdfBodyCell(inv.subTotal.toStringAsFixed(2), align: pw.TextAlign.right),
                      _pdfBodyCell(inv.totalGst.toStringAsFixed(2), align: pw.TextAlign.right),
                      _pdfBodyCell(inv.grandTotal.toStringAsFixed(2), align: pw.TextAlign.right),
                    ],
                  )),
                ],
              ),
            ];
          },
        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      appBar: AppBar(
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => layoutScaffoldKey.currentState?.openDrawer(),
              ),
        title: Row(
          children: [
            Text(
              'Reports ',
              style: AppTheme.displayFont(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.paperDark : AppTheme.paperLight,
              ),
            ),
            Text(
              '& Taxation',
              style: AppTheme.displayFont(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.paperDark : AppTheme.paperLight,
              ),
            ),
          ],
        ),
        actions: [
          _buildExportCsvButton(context, invoicesVal, shortcuts),
          const SizedBox(width: 8),
          _buildExportPdfButton(context, invoicesVal, shortcuts),
          const SizedBox(width: 16),
        ],
      ),
      body: invoicesVal.when(
        data: (list) {
          final startNormal = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
          final endNormal = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
          final filtered = list
              .where((inv) =>
                  inv.invoiceDate.isAfter(startNormal) &&
                  inv.invoiceDate.isBefore(endNormal))
              .toList();

          final totalTaxable = filtered.fold(0.0, (s, i) => s + i.subTotal);
          final totalCgst = filtered.fold(0.0, (s, i) => s + i.cgst);
          final totalSgst = filtered.fold(0.0, (s, i) => s + i.sgst);
          final totalGst = filtered.fold(0.0, (s, i) => s + i.totalGst);
          final totalRevenue = filtered.fold(0.0, (s, i) => s + i.grandTotal);

          final Map<ShortcutActivator, VoidCallback> bindings = {};
          final excelShortcut = shortcuts['exportExcel'];
          if (excelShortcut != null) {
            bindings[SingleActivator(excelShortcut.key,
                control: excelShortcut.control,
                shift: excelShortcut.shift,
                alt: excelShortcut.alt)] = () {
              if (filtered.isNotEmpty) _exportCsv(filtered);
            };
          }
          final pdfReportShortcut = shortcuts['exportPdfReport'];
          if (pdfReportShortcut != null) {
            bindings[SingleActivator(pdfReportShortcut.key,
                control: pdfReportShortcut.control,
                shift: pdfReportShortcut.shift,
                alt: pdfReportShortcut.alt)] = () {
              if (filtered.isNotEmpty) _exportPdf(filtered);
            };
          }

          return Focus(
            autofocus: true,
            child: CallbackShortcuts(
              bindings: bindings,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Date Preset Filter Bar ──────────────────────────────
                    _buildPresetFilterBar(context),
                    const SizedBox(height: 20),

                    // ── Summary Stat Cards ──────────────────────────────────
                    _buildStatCardsRow(context, totalTaxable, totalCgst, totalSgst, totalGst, totalRevenue),
                    const SizedBox(height: 24),

                    // ── Sales Ledger Table ──────────────────────────────────
                    _buildLedgerTable(context, filtered),
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

  // ─── Export CSV button ─────────────────────────────────────────────────────
  Widget _buildExportCsvButton(BuildContext context, AsyncValue<List<Invoice>> invoicesVal, Map shortcuts) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final excelShortcut = shortcuts['exportExcel'];
    final filtered = _getFiltered(invoicesVal);
    return Tooltip(
      message: excelShortcut != null
          ? 'Export Excel/CSV (${excelShortcut.displayString})'
          : 'Export Excel/CSV',
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppTheme.paperDark : AppTheme.paperLight,
          side: BorderSide(
            color: isDark ? AppTheme.hairlineStrongDark : AppTheme.hairlineStrongLight,
            width: 1.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: filtered.isEmpty ? null : () => _exportCsv(filtered),
        icon: const Icon(Icons.download_rounded, size: 16),
        label: const Text('Export CSV', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ─── Export PDF button ─────────────────────────────────────────────────────
  Widget _buildExportPdfButton(BuildContext context, AsyncValue<List<Invoice>> invoicesVal, Map shortcuts) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pdfReportShortcut = shortcuts['exportPdfReport'];
    final filtered = _getFiltered(invoicesVal);
    return Tooltip(
      message: pdfReportShortcut != null
          ? 'Export PDF Report (${pdfReportShortcut.displayString})'
          : 'Export PDF Report',
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppTheme.saffronDark : AppTheme.saffronLight,
          foregroundColor: isDark ? AppTheme.voidDark : AppTheme.onAccentLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: filtered.isEmpty ? null : () => _exportPdf(filtered),
        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
        label: const Text('Export PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  List<Invoice> _getFiltered(AsyncValue<List<Invoice>> invoicesVal) {
    if (invoicesVal.value == null) return [];
    final startNormal = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
    final endNormal = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    return invoicesVal.value!
        .where((inv) => inv.invoiceDate.isAfter(startNormal) && inv.invoiceDate.isBefore(endNormal))
        .toList();
  }

  // ─── Preset Filter Bar ─────────────────────────────────────────────────────
  Widget _buildPresetFilterBar(BuildContext context) {
    final customLabel =
        'Custom range: ${DateFormat('dd/MM').format(_startDate)} – ${DateFormat('dd/MM/yyyy').format(_endDate)}';

    final presets = [
      ('Today', 'today'),
      ('Last 30 days', '30days'),
      ('This month', 'thismonth'),
      ('This year', 'thisyear'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...presets.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _presetChip(p.$1, p.$2),
              )),
          _customRangeChip(customLabel),
        ],
      ),
    );
  }

  Widget _presetChip(String label, String preset) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _activePreset == preset;

    return GestureDetector(
      onTap: () => _applyPreset(preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.saffronDark : AppTheme.saffronLight)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppTheme.hairlineStrongDark : AppTheme.hairlineStrongLight),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.uiFont(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? (isDark ? AppTheme.voidDark : AppTheme.onAccentLight)
                : (isDark ? AppTheme.mistDark : AppTheme.mistLight),
          ),
        ),
      ),
    );
  }

  Widget _customRangeChip(String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _activePreset == 'custom';

    return GestureDetector(
      onTap: () => _selectCustomRange(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.saffronDark : AppTheme.saffronLight)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppTheme.hairlineStrongDark : AppTheme.hairlineStrongLight,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.uiFont(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? (isDark ? AppTheme.voidDark : AppTheme.onAccentLight)
                : (isDark ? AppTheme.mistDark : AppTheme.mistLight),
          ),
        ),
      ),
    );
  }

  // ─── Summary Stat Cards ────────────────────────────────────────────────────
  Widget _buildStatCardsRow(
    BuildContext context,
    double taxable,
    double cgst,
    double sgst,
    double totalGst,
    double revenue,
  ) {
    final cards = [
      _StatCardData('Taxable Value', taxable, _StatCardAccent.blue),
      _StatCardData('CGST Collected', cgst, _StatCardAccent.green),
      _StatCardData('SGST Collected', sgst, _StatCardAccent.green),
      _StatCardData('Total GST', totalGst, _StatCardAccent.orange),
      _StatCardData('Total Revenue', revenue, _StatCardAccent.orange, isHighlight: true),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 900) {
        return Row(
          children: cards
              .map((d) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: d == cards.last ? 0 : 10),
                      child: _statCard(context, d),
                    ),
                  ))
              .toList(),
        );
      } else if (constraints.maxWidth >= 560) {
        return Column(
          children: [
            Row(
              children: cards.sublist(0, 2).map((d) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: d == cards[1] ? 0 : 10),
                      child: _statCard(context, d),
                    ),
                  )).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: cards.sublist(2, 4).map((d) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: d == cards[3] ? 0 : 10),
                      child: _statCard(context, d),
                    ),
                  )).toList(),
            ),
            const SizedBox(height: 10),
            _statCard(context, cards[4]),
          ],
        );
      } else {
        return Column(
          children: cards
              .map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _statCard(context, d),
                  ))
              .toList(),
        );
      }
    });
  }

  Widget _statCard(BuildContext context, _StatCardData data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color accentColor;
    switch (data.accent) {
      case _StatCardAccent.blue:
        accentColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
        break;
      case _StatCardAccent.green:
        accentColor = isDark ? AppTheme.jadeDark : AppTheme.jadeLight;
        break;
      case _StatCardAccent.orange:
        accentColor = isDark ? AppTheme.saffronDark : AppTheme.saffronLight;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.panelDark : AppTheme.panelLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored top accent line
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.label,
            style: AppTheme.uiFont(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.mistDark : AppTheme.mistLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currency.format(data.value),
            style: AppTheme.monoFont(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: data.isHighlight
                  ? accentColor
                  : (isDark ? AppTheme.paperDark : AppTheme.paperLight),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sales Ledger Table ────────────────────────────────────────────────────
  Widget _buildLedgerTable(BuildContext context, List<Invoice> filtered) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentOrange = isDark ? AppTheme.saffronDark : AppTheme.saffronLight;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.panelDark : AppTheme.panelLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accentOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Sales Ledger Log',
                  style: AppTheme.uiFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.paperDark : AppTheme.paperLight,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight),

          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No invoices found in selected date range.',
                  style: AppTheme.uiFont(
                    fontSize: 13,
                    color: isDark ? AppTheme.mistDimDark : AppTheme.mistDimLight,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTable(context, filtered, isDark, accentOrange),
            ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<Invoice> filtered, bool isDark, Color accentOrange) {
    final headerColor = isDark ? AppTheme.mistDimDark : AppTheme.mistLight;
    final textColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final dividerColor = isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight;
    final rowHoverColor = isDark
        ? Colors.white.withValues(alpha: 0.025)
        : Colors.black.withValues(alpha: 0.025);

    const colWidths = [110.0, 150.0, 160.0, 160.0, 130.0, 150.0];
    const headers = ['DATE', 'INVOICE NO', 'CUSTOMER', 'TAXABLE VALUE', 'TOTAL GST', 'GRAND TOTAL'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column header row
        Container(
          color: isDark ? const Color(0xFF0D1017) : const Color(0xFFF8F9FA),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: List.generate(headers.length, (i) {
                final isLast = i == headers.length - 1;
                return SizedBox(
                  width: colWidths[i],
                  child: Text(
                    headers[i],
                    textAlign: isLast ? TextAlign.right : TextAlign.left,
                    style: AppTheme.uiFont(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isLast ? accentOrange : headerColor,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        Divider(height: 1, color: dividerColor),

        // Data rows
        ...filtered.asMap().entries.map((entry) {
          final inv = entry.value;
          final isEven = entry.key % 2 == 0;

          return Column(
            children: [
              Container(
                color: isEven ? Colors.transparent : rowHoverColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  child: Row(
                    children: [
                      SizedBox(
                        width: colWidths[0],
                        child: Text(
                          _df.format(inv.invoiceDate),
                          style: AppTheme.uiFont(fontSize: 13, color: textColor),
                        ),
                      ),
                      SizedBox(
                        width: colWidths[1],
                        child: Text(
                          inv.invoiceNumber,
                          style: AppTheme.monoFont(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: colWidths[2],
                        child: Text(
                          inv.customerName,
                          style: AppTheme.uiFont(fontSize: 13, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: colWidths[3],
                        child: Text(
                          _currency.format(inv.subTotal),
                          style: AppTheme.monoFont(fontSize: 13, color: textColor),
                        ),
                      ),
                      SizedBox(
                        width: colWidths[4],
                        child: Text(
                          _currency.format(inv.totalGst),
                          style: AppTheme.monoFont(fontSize: 13, color: textColor),
                        ),
                      ),
                      SizedBox(
                        width: colWidths[5],
                        child: Text(
                          _currency.format(inv.grandTotal),
                          textAlign: TextAlign.right,
                          style: AppTheme.monoFont(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: accentOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: dividerColor),
            ],
          );
        }),
      ],
    );
  }
}

enum _StatCardAccent { blue, green, orange }

class _StatCardData {
  final String label;
  final double value;
  final _StatCardAccent accent;
  final bool isHighlight;

  const _StatCardData(this.label, this.value, this.accent, {this.isHighlight = false});
}
