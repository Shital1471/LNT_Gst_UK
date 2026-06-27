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
  return (db.select(db.invoices)
        ..orderBy([(t) => OrderingTerm.desc(t.invoiceDate)]))
      .watch();
});

class InvoiceHistoryScreen extends ConsumerStatefulWidget {
  final Function(int) onTabChange;
  const InvoiceHistoryScreen({super.key, required this.onTabChange});

  @override
  ConsumerState<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends ConsumerState<InvoiceHistoryScreen> {
  final _df = DateFormat('dd/MM/yyyy');
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  String _searchQuery = '';
  String _sortField = 'date';
  bool _ascending = false;
  String _filterTemplate = 'all';

  Future<void> _viewInvoice(Invoice invoice) async {
    final db = ref.read(databaseProvider);
    final items = await (db.select(db.invoiceItems)
          ..where((t) => t.invoiceId.equals(invoice.id)))
        .get();

    final companyVal = ref.read(companyProfileStateProvider);
    final company = companyVal.value;

    if (company == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Company profile not configured'),
              backgroundColor: Colors.orange),
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
            SnackBar(
                content: Text('PDF downloaded to $destPath'),
                backgroundColor: AppTheme.primaryGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _duplicateInvoice(Invoice invoice) async {
    final db = ref.read(databaseProvider);
    final items = await (db.select(db.invoiceItems)
          ..where((t) => t.invoiceId.equals(invoice.id)))
        .get();

    final notifier = ref.read(invoiceFormProvider.notifier);
    notifier.loadFromInvoice(invoice, items);
    widget.onTabChange(1);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Loaded ${invoice.invoiceNumber} as new Draft. Modify and generate.'),
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
        content: Text(
            'Are you sure you want to permanently delete invoice ${invoice.invoiceNumber}? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (invoice.pdfPath != null) {
        try {
          final file = File(invoice.pdfPath!);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      if (invoice.docxPath != null) {
        try {
          final file = File(invoice.docxPath!);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }

      final db = ref.read(databaseProvider);
      await (db.delete(db.invoices)..where((t) => t.id.equals(invoice.id))).go();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invoice deleted'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoicesStream = ref.watch(invoicesStreamProvider);
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
        title: Text(
          'Invoice History',
          style: AppTheme.displayFont(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.paperDark : AppTheme.paperLight,
          ),
        ),
        actions: [
          // Invoice count badge shown in top right (like the reference image)
          invoicesStream.when(
            data: (list) => Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  '${list.length} invoice${list.length == 1 ? '' : 's'}',
                  style: AppTheme.uiFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.mistDark : AppTheme.mistLight,
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _e) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: invoicesStream.when(
        data: (list) {
          // Apply search filter
          var filteredList = list.where((inv) {
            final query = _searchQuery.toLowerCase();
            if (query.isEmpty) return true;
            return inv.customerName.toLowerCase().contains(query) ||
                inv.invoiceNumber.toLowerCase().contains(query) ||
                (inv.customerGstNumber?.toLowerCase().contains(query) ?? false);
          }).toList();

          // Apply template filter
          if (_filterTemplate != 'all') {
            filteredList =
                filteredList.where((inv) => inv.templateType == _filterTemplate).toList();
          }

          // Apply sort
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
              // ── Search & Controls Bar ─────────────────────────────────
              _buildControlsBar(context, isDark, filteredList.length),
              // ── Invoice List ──────────────────────────────────────────
              if (filteredList.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No matching invoices found.',
                      style: AppTheme.uiFont(
                        fontSize: 13,
                        color: isDark ? AppTheme.mistDimDark : AppTheme.mistDimLight,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildInvoiceCard(context, filteredList[index], isDark),
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

  // ─── Controls Bar ─────────────────────────────────────────────────────────
  Widget _buildControlsBar(BuildContext context, bool isDark, int count) {
    final borderColor = isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight;
    final bgColor = isDark ? AppTheme.panelDark : AppTheme.panelLight;
    final textColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final mutedColor = isDark ? AppTheme.mistDark : AppTheme.mistLight;

    final searchField = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextField(
        style: AppTheme.uiFont(fontSize: 13.5, color: textColor),
        decoration: InputDecoration(
          hintText: 'Search by customer, invoice number, or GSTIN...',
          hintStyle: AppTheme.uiFont(
              fontSize: 13.5,
              color: isDark ? AppTheme.mistDimDark : AppTheme.mistDimLight),
          prefixIcon: Icon(Icons.search_rounded,
              size: 18, color: isDark ? AppTheme.mistDark : AppTheme.mistLight),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );

    // Pill-style dropdown button
    Widget pillDropdown({
      required String value,
      required List<DropdownMenuItem<String>> items,
      required ValueChanged<String?> onChanged,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: isDark ? AppTheme.panelRaisedDark : AppTheme.panelRaisedLight,
            style: AppTheme.uiFont(
                fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: mutedColor),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
    }

    // Sort direction toggle
    final sortDirectionBtn = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 16,
          color: mutedColor,
        ),
        onPressed: () => setState(() => _ascending = !_ascending),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          if (isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 10),
                Row(
                  children: [
                    pillDropdown(
                      value: _filterTemplate,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All layouts')),
                        DropdownMenuItem(value: 'tourism', child: Text('Tourism')),
                        DropdownMenuItem(
                            value: 'standard', child: Text('Standard')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _filterTemplate = val);
                      },
                    ),
                    const SizedBox(width: 8),
                    pillDropdown(
                      value: _sortField,
                      items: const [
                        DropdownMenuItem(value: 'date', child: Text('Sort by date')),
                        DropdownMenuItem(value: 'total', child: Text('Sort by total')),
                        DropdownMenuItem(value: 'number', child: Text('Sort by ID')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _sortField = val);
                      },
                    ),
                    const SizedBox(width: 8),
                    sortDirectionBtn,
                    const Spacer(),
                    Text(
                      'Showing $count result${count == 1 ? '' : 's'}',
                      style: AppTheme.uiFont(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: mutedColor),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: pillDropdown(
                        value: _filterTemplate,
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All layouts')),
                          DropdownMenuItem(
                              value: 'tourism', child: Text('Tourism')),
                          DropdownMenuItem(
                              value: 'standard', child: Text('Standard')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _filterTemplate = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: pillDropdown(
                        value: _sortField,
                        items: const [
                          DropdownMenuItem(
                              value: 'date', child: Text('Sort by date')),
                          DropdownMenuItem(
                              value: 'total', child: Text('Sort by total')),
                          DropdownMenuItem(
                              value: 'number', child: Text('Sort by ID')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _sortField = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    sortDirectionBtn,
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Showing $count result${count == 1 ? '' : 's'}',
                  style: AppTheme.uiFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: mutedColor),
                  textAlign: TextAlign.right,
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // ─── Invoice Card ──────────────────────────────────────────────────────────
  Widget _buildInvoiceCard(BuildContext context, Invoice invoice, bool isDark) {
    final theme = Theme.of(context);
    final balance = invoice.grandTotal - invoice.advancePaid;
    final isPaid = balance <= 0;

    final accentColor = isDark ? AppTheme.saffronDark : AppTheme.saffronLight;
    final cardBg = isDark ? AppTheme.panelDark : AppTheme.panelLight;
    final borderColor = isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight;
    final textColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final mutedColor = isDark ? AppTheme.mistDark : AppTheme.mistLight;

    // Icon container
    final iconBox = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        invoice.templateType == 'tourism'
            ? Icons.beach_access_rounded
            : Icons.receipt_long_rounded,
        color: accentColor,
        size: 20,
      ),
    );

    // Pricing / status block
    final pricingBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _currency.format(invoice.grandTotal),
          style: AppTheme.monoFont(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 4),
        if (isPaid)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.jadeDark : AppTheme.jadeLight,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Paid',
                style: AppTheme.uiFont(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.jadeDark : AppTheme.jadeLight,
                ),
              ),
            ],
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFF97316),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Due ${_currency.format(balance)}',
                style: AppTheme.uiFont(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF97316),
                ),
              ),
            ],
          ),
      ],
    );

    // Action icon buttons
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionIconBtn(
          icon: Icons.visibility_outlined,
          tooltip: 'View Invoice',
          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
          onTap: () => _viewInvoice(invoice),
        ),
        _actionIconBtn(
          icon: Icons.file_download_outlined,
          tooltip: 'Save PDF',
          color: mutedColor,
          onTap: () => _downloadPdf(invoice),
        ),
        _actionIconBtn(
          icon: Icons.content_copy_rounded,
          tooltip: 'Duplicate as Draft',
          color: mutedColor,
          onTap: () => _duplicateInvoice(invoice),
        ),
        _actionIconBtn(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Delete',
          color: theme.colorScheme.error,
          onTap: () => _deleteInvoice(invoice),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              hoverColor: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              onTap: () => _viewInvoice(invoice),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: isWide
                    ? Row(
                        children: [
                          iconBox,
                          const SizedBox(width: 14),
                          // Invoice info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      invoice.invoiceNumber,
                                      style: AppTheme.monoFont(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _df.format(invoice.invoiceDate),
                                      style: AppTheme.uiFont(
                                        fontSize: 11.5,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  invoice.customerName,
                                  style: AppTheme.uiFont(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: mutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          pricingBlock,
                          const SizedBox(width: 8),
                          actions,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              iconBox,
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invoice.invoiceNumber,
                                      style: AppTheme.monoFont(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      invoice.customerName,
                                      style: AppTheme.uiFont(
                                          fontSize: 12.5, color: mutedColor),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _df.format(invoice.invoiceDate),
                                style: AppTheme.uiFont(
                                    fontSize: 11, color: mutedColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [pricingBlock, actions],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionIconBtn({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
