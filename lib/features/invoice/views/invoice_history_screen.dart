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
import '../../../core/utils/navigation.dart';

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

      final destPath = await FilePicker.saveFile(
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

    final isWide = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History'),
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => layoutScaffoldKey.currentState?.openDrawer(),
              ),
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
              // Search & Filter controls panel (Responsive Layout)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final theme = Theme.of(context);
                    final isWide = constraints.maxWidth >= 750;

                    final searchField = TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search invoices by customer, number, or GSTIN...',
                        prefixIcon: Icon(Icons.search_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    );

                    final filterTemplateDropdown = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterTemplate,
                          dropdownColor: theme.cardColor,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Layouts')),
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
                      ),
                    );

                    final sortDropdown = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortField,
                          dropdownColor: theme.cardColor,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'date', child: Text('Sort by Date')),
                            DropdownMenuItem(value: 'total', child: Text('Sort by Total')),
                            DropdownMenuItem(value: 'number', child: Text('Sort by ID')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _sortField = val;
                              });
                            }
                          },
                        ),
                      ),
                    );

                    final sortDirectionBtn = Container(
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(_ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 18),
                        onPressed: () {
                          setState(() {
                            _ascending = !_ascending;
                          });
                        },
                      ),
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(flex: 4, child: searchField),
                          const SizedBox(width: 12),
                          filterTemplateDropdown,
                          const SizedBox(width: 12),
                          sortDropdown,
                          const SizedBox(width: 8),
                          sortDirectionBtn,
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          searchField,
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: filterTemplateDropdown),
                              const SizedBox(width: 8),
                              Expanded(child: sortDropdown),
                              const SizedBox(width: 8),
                              sortDirectionBtn,
                            ],
                          )
                        ],
                      );
                    }
                  },
                ),
              ),

              if (filteredList.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No matching invoices found in history.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
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
                      final theme = Theme.of(context);
                      final isDark = theme.brightness == Brightness.dark;

                      // Card layout dependent on width
                      return LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final isCardWide = cardConstraints.maxWidth >= 650;

                          // Shared sub-components
                          final iconLayout = Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: invoice.templateType == 'tourism'
                                  ? theme.colorScheme.primary.withOpacity(0.1)
                                  : theme.colorScheme.secondary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              invoice.templateType == 'tourism'
                                  ? Icons.beach_access_rounded
                                  : Icons.shopping_bag_rounded,
                              color: invoice.templateType == 'tourism'
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                              size: 20,
                            ),
                          );

                          final invoiceInfo = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    invoice.invoiceNumber,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _df.format(invoice.invoiceDate),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                invoice.customerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                                ),
                              ),
                              if (invoice.tourTrip != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.route_rounded,
                                        size: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        invoice.tourTrip!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );

                          final pricingInfo = Column(
                            crossAxisAlignment:
                                isCardWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currency.format(invoice.grandTotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (balance > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Due: ${_currency.format(balance)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.accentOrange,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Fully Paid',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                            ],
                          );

                          final actions = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 20),
                                tooltip: 'View Invoice',
                                color: Colors.blue.shade400,
                                onPressed: () => _viewInvoice(invoice),
                              ),
                              IconButton(
                                icon: const Icon(Icons.file_download_outlined, size: 20),
                                tooltip: 'Save PDF Copy',
                                color: theme.colorScheme.primary,
                                onPressed: () => _downloadPdf(invoice),
                              ),
                              IconButton(
                                icon: const Icon(Icons.content_copy_rounded, size: 18),
                                tooltip: 'Duplicate as Draft',
                                color: theme.colorScheme.secondary,
                                onPressed: () => _duplicateInvoice(invoice),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                tooltip: 'Delete Permanently',
                                color: theme.colorScheme.error,
                                onPressed: () => _deleteInvoice(invoice),
                              ),
                            ],
                          );

                          if (isCardWide) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Row(
                                  children: [
                                    iconLayout,
                                    const SizedBox(width: 16),
                                    Expanded(child: invoiceInfo),
                                    const SizedBox(width: 16),
                                    pricingInfo,
                                    const SizedBox(width: 20),
                                    actions,
                                  ],
                                ),
                              ),
                            );
                          } else {
                            // Stacked for compact screens
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        iconLayout,
                                        const SizedBox(width: 12),
                                        Expanded(child: invoiceInfo),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        pricingInfo,
                                        actions,
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
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
