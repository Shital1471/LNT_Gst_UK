import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import 'package:drift/drift.dart' hide Column;
import '../providers/invoice_form_provider.dart';
import '../../company/providers/company_provider.dart';
import 'invoice_preview_screen.dart';

final invoicesStreamProvider = StreamProvider<List<Invoice>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.invoices)..orderBy([(t) => OrderingTerm.desc(t.invoiceDate)])).watch();
});

class InvoiceHistoryScreen extends ConsumerStatefulWidget {
  final Function(int) onTabChange; // Allows navigating back to Form editor tab
  const InvoiceHistoryScreen({super.key, required this.onTabChange});

  @override
  ConsumerState<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends ConsumerState<InvoiceHistoryScreen> {
  final _df = DateFormat('dd/MM/yyyy');
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

  String _searchQuery = '';
  String _sortField = 'date'; // 'date', 'total', 'number'
  bool _ascending = false;
  String _filterTemplate = 'all'; // 'all', 'tourism', 'standard'

  Future<void> _viewInvoice(Invoice invoice) async {
    final db = ref.read(databaseProvider);
    final items = await (db.select(db.invoiceItems)..where((t) => t.invoiceId.equals(invoice.id))).get();
    
    final companyVal = ref.read(companyProfileStateProvider);
    final company = companyVal.value;

    if (company == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company profile not configured'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoicePreviewScreen(
            invoice: invoice,
            items: items,
            company: company,
          ),
        ),
      );
    }
  }

  Future<void> _downloadPdf(Invoice invoice) async {
    if (invoice.pdfPath == null) return;
    try {
      final file = File(invoice.pdfPath!);
      if (!await file.exists()) {
        throw Exception('Source file not found at local storage');
      }

      final destPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF File',
        fileName: '${invoice.invoiceNumber}.pdf',
      );

      if (destPath != null) {
        await file.copy(destPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF downloaded to $destPath'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _duplicateInvoice(Invoice invoice) async {
    final db = ref.read(databaseProvider);
    final items = await (db.select(db.invoiceItems)..where((t) => t.invoiceId.equals(invoice.id))).get();

    // Load template details into form notifier
    final notifier = ref.read(invoiceFormProvider.notifier);
    notifier.loadFromInvoice(invoice, items);

    // Switch tab index to the form tab
    widget.onTabChange(1);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded ${invoice.invoiceNumber} as new Draft. Modify and generate.'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to permanently delete invoice ${invoice.invoiceNumber}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Delete actual files from filesystem
      if (invoice.pdfPath != null) {
        try {
          final file = File(invoice.pdfPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      if (invoice.docxPath != null) {
        try {
          final file = File(invoice.docxPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }

      // 2. Delete database header (cascade deletes items)
      final db = ref.read(databaseProvider);
      await (db.delete(db.invoices)..where((t) => t.id.equals(invoice.id))).go();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice deleted'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoicesStream = ref.watch(invoicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History'),
      ),
      body: invoicesStream.when(
        data: (list) {
          // Apply search query filter
          var filteredList = list.where((inv) {
            final query = _searchQuery.toLowerCase();
            final matchesName = inv.customerName.toLowerCase().contains(query);
            final matchesNumber = inv.invoiceNumber.toLowerCase().contains(query);
            final matchesGst = inv.customerGstNumber?.toLowerCase().contains(query) ?? false;
            return matchesName || matchesNumber || matchesGst;
          }).toList();

          // Apply template filter
          if (_filterTemplate != 'all') {
            filteredList = filteredList.where((inv) => inv.templateType == _filterTemplate).toList();
          }

          // Apply sorting rules
          filteredList.sort((a, b) {
            int comp = 0;
            if (_sortField == 'date') {
              comp = a.invoiceDate.compareTo(b.invoiceDate);
            } else if (_sortField == 'total') {
              comp = a.grandTotal.compareTo(b.grandTotal);
            } else if (_sortField == 'number') {
              comp = a.invoiceNumber.compareTo(b.invoiceNumber);
            }
            return _ascending ? comp : -comp;
          });

          return Column(
            children: [
              // Search & Filter controls panel
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search invoices by name, number, or GSTIN...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Filter Template Dropdown
                    DropdownButton<String>(
                      value: _filterTemplate,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Templates')),
                        DropdownMenuItem(value: 'tourism', child: Text('Tourism')),
                        DropdownMenuItem(value: 'standard', child: Text('Standard')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _filterTemplate = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    // Sort dropdown
                    DropdownButton<String>(
                      value: _sortField,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'date', child: Text('Sort by Date')),
                        DropdownMenuItem(value: 'total', child: Text('Sort by Total')),
                        DropdownMenuItem(value: 'number', child: Text('Sort by Number')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _sortField = val;
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
                      onPressed: () {
                        setState(() {
                          _ascending = !_ascending;
                        });
                      },
                    ),
                  ],
                ),
              ),

              if (filteredList.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No matching invoices found in history.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filteredList.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final invoice = filteredList[index];
                      final balance = invoice.grandTotal - invoice.advancePaid;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Left: Icon representing template type
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: invoice.templateType == 'tourism'
                                      ? AppTheme.primaryGreen.withOpacity(0.1)
                                      : AppTheme.deepBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  invoice.templateType == 'tourism' ? Icons.beach_access : Icons.shopping_bag,
                                  color: invoice.templateType == 'tourism' ? AppTheme.primaryGreen : AppTheme.deepBlue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Middle Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          invoice.invoiceNumber,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.deepBlue),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _df.format(invoice.invoiceDate),
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      invoice.customerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    if (invoice.tourTrip != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Trip: ${invoice.tourTrip}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Financials Column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currency.format(invoice.grandTotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen),
                                  ),
                                  if (balance > 0)
                                    Text(
                                      'Due: ${_currency.format(balance)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                                    )
                                  else
                                    const Text(
                                      'Fully Paid',
                                      style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                    )
                                ],
                              ),
                              const SizedBox(width: 24),
                              
                              // Actions menu
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.blue),
                                    tooltip: 'View Preview',
                                    onPressed: () => _viewInvoice(invoice),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download, color: AppTheme.primaryGreen),
                                    tooltip: 'Download PDF',
                                    onPressed: () => _downloadPdf(invoice),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: AppTheme.deepBlue),
                                    tooltip: 'Duplicate Invoice',
                                    onPressed: () => _duplicateInvoice(invoice),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () => _deleteInvoice(invoice),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading history: $err')),
      ),
    );
  }
}
