import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../company/providers/company_provider.dart';
import '../models/invoice_template_schema.dart';
import '../../../core/utils/num_to_words.dart';
import '../providers/invoice_form_provider.dart';
import 'tourism_preview_widget.dart';

class InvoiceDesignerScreen extends ConsumerStatefulWidget {
  const InvoiceDesignerScreen({super.key});

  @override
  ConsumerState<InvoiceDesignerScreen> createState() => _InvoiceDesignerScreenState();
}

class _InvoiceDesignerScreenState extends ConsumerState<InvoiceDesignerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSectionId;
  String? _selectedFieldId;
  bool _enableAbsoluteDragging = false;
  String _selectedStyleClass = 'body';

  final List<Map<String, String>> _styleClasses = const [
    {'id': 'body', 'name': 'Body Text'},
    {'id': 'header', 'name': 'Company Name Header'},
    {'id': 'subheader', 'name': 'Company Tagline / Subtitle'},
    {'id': 'section_title', 'name': 'Section Title (e.g. BILL TO)'},
    {'id': 'subsection_title', 'name': 'Subsection Header'},
    {'id': 'table_header', 'name': 'Table Column Header'},
    {'id': 'table_data', 'name': 'Table Data Cell'},
    {'id': 'footer', 'name': 'Footer / Terms / Signatures'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceFormProvider);
    final activeT = state.activeTemplate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Invoice Layout Designer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset Layout',
            onPressed: () {
              ref.read(invoiceFormProvider.notifier).updateTemplate(
                    InvoiceTemplateSchema.getPreset(activeT.id),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Layout reset to default preset')),
              );
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Side: Visual Page Canvas (WYSIWYG layout mockup)
          Expanded(
            flex: 3,
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade900
                  : Colors.grey.shade100,
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCanvasPage(activeT),
                      const SizedBox(height: 12),
                      const Text(
                        'Visual representation of current schema layout. Items in layout are select-to-edit.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right Side: Inspector Panel & Section list
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.3))),
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppTheme.deepBlue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryGreen,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_view), text: 'Fields'),
                      Tab(icon: Icon(Icons.view_headline), text: 'Header'),
                      Tab(icon: Icon(Icons.space_bar), text: 'Spacing'),
                      Tab(icon: Icon(Icons.table_chart), text: 'Columns'),
                      Tab(icon: Icon(Icons.subtitles), text: 'Footers'),
                      Tab(icon: Icon(Icons.text_fields), text: 'Typography'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFieldsTab(activeT),
                        _buildHeaderTab(activeT),
                        _buildSpacingTab(activeT),
                        _buildColumnsTab(activeT),
                        _buildFootersTab(activeT),
                        _buildTypographyTab(activeT),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Visual Canvas Component Builder ---
  Widget _buildCanvasPage(InvoiceTemplateSchema template) {
    const double scale = 0.8;
    final width = template.pageWidth * scale;
    final height = template.pageHeight * scale;
    final isTourism = template.id == 'tourism';
    final state = ref.watch(invoiceFormProvider);

    if (isTourism) {
      final companyAsync = ref.watch(companyProfileStateProvider);
      final company = companyAsync.valueOrNull ?? const CompanyProfile(
        id: 0,
        name: '',
        address: '',
        contactNumber: '',
        email: '',
        gstNumber: '',
        bankAccountName: '',
        bankName: '',
        bankAccountNumber: '',
        bankIfscCode: '',
        defaultGstPercentage: 5.0,
      );

      final mockInvoice = Invoice(
        id: 0,
        invoiceNumber: state.invoiceNumber,
        invoiceDate: state.invoiceDate,
        dueDate: state.dueDate,
        customerName: state.customerName,
        customerAddress: state.customerAddress,
        customerGstNumber: state.customerGstNumber,
        customerContactNumber: state.customerContactNumber,
        templateType: state.templateType,
        subTotal: state.gstCalculations.subTotal,
        cgst: state.gstCalculations.cgst,
        sgst: state.gstCalculations.sgst,
        grandTotal: state.gstCalculations.grandTotal,
        advancePaid: state.advancePaid,
        amountPaidInWords: NumberToWords.convert(state.gstCalculations.grandTotal - state.advancePaid),
        fieldValuesJson: null,
        templateSchemaJson: null,
        createdDate: DateTime.now(),
        totalGst: state.gstCalculations.cgst + state.gstCalculations.sgst,
      );

      final mockItems = state.items.map((item) => InvoiceItem(
        id: 0,
        invoiceId: 0,
        description: item.description,
        quantityDays: item.quantityDays,
        rate: item.rate,
        amount: item.amount,
        noOfVehicles: item.noOfVehicles,
        itemDate: item.date,
        fromTo: item.fromTo,
      )).toList();

      return TourismInvoicePreviewWidget(
        invoice: mockInvoice,
        items: mockItems,
        company: company,
        fieldValues: state.fieldValues,
        template: template,
        scale: scale,
        isDesigner: true,
        selectedSectionId: _selectedSectionId,
        selectedFieldId: _selectedFieldId,
        onTapField: (sectionId, fieldId) {
          setState(() {
            _selectedSectionId = sectionId;
            _selectedFieldId = fieldId;

            if (sectionId == 'items_table') {
              _tabController.animateTo(3); // Columns Tab
            } else if (const ['terms_conditions', 'payment_info', 'signature', 'bank_details'].contains(sectionId)) {
              _tabController.animateTo(4); // Footers Tab
            } else {
              _tabController.animateTo(0); // Fields Tab
            }
          });
        },
      );
    }

    final visibleSections = template.sections.where((s) => s.isVisible).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
        padding: EdgeInsets.only(
          top: template.marginTop * scale,
          bottom: template.marginBottom * scale,
          left: template.marginLeft * scale,
          right: template.marginRight * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: visibleSections.map((sec) => _buildCanvasSection(template, sec, scale)).toList(),
        ),
      ),
    );
  }

  Widget _buildCanvasSection(InvoiceTemplateSchema template, SectionSchema sec, double scale) {
    final isSelected = _selectedSectionId == sec.id;

    Widget child;
    if (sec.id == 'items_table') {
      child = _buildItemsTableMock(template.id);
    } else if (sec.id == 'tax_summary') {
      child = _buildTaxSummaryMock();
    } else {
      child = _buildSectionFields(sec, scale);
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSectionId = sec.id;
          _selectedFieldId = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.04) : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  sec.title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepBlue,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 10, color: AppTheme.primaryGreen),
              ],
            ),
            const Divider(height: 4, color: AppTheme.primaryGreen),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionFields(SectionSchema sec, double scale) {
    final fields = sec.fields.where((f) => f.isVisible).toList();

    if (_enableAbsoluteDragging && _selectedSectionId == sec.id) {
      return SizedBox(
        height: 100,
        child: Stack(
          children: fields.map((f) {
            final double left = (f.posX ?? 0.0) * scale;
            final double top = (f.posY ?? 0.0) * scale;

            return Positioned(
              left: left,
              top: top,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final newX = (f.posX ?? 0.0) + details.delta.dx / scale;
                  final newY = (f.posY ?? 0.0) + details.delta.dy / scale;
                  _updateFieldPosition(sec.id, f.id, newX, newY);
                },
                child: _buildFieldChip(sec.id, f),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: fields.map((f) {
        final isFieldSelected = _selectedFieldId == f.id;
        final fontColor = _parseColor(f.textColor);

        return InkWell(
          onTap: () {
            setState(() {
              _selectedFieldId = f.id;
              _selectedSectionId = sec.id;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(
                color: isFieldSelected ? AppTheme.primaryGreen : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${f.label}: ',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  '[Value]',
                  style: TextStyle(
                    fontSize: f.fontSize - 1,
                    fontWeight: f.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
                    color: fontColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFieldChip(String sectionId, FieldSchema f) {
    final isFieldSelected = _selectedFieldId == f.id;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isFieldSelected ? Colors.green.shade50 : Colors.blue.shade50,
        border: Border.all(color: isFieldSelected ? Colors.green : Colors.blue),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        f.label,
        style: const TextStyle(fontSize: 8, color: Colors.black),
      ),
    );
  }

  Widget _buildItemsTableMock(String templateId) {
    if (templateId == 'tourism') {
      return Table(
        border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: const [
              Padding(padding: EdgeInsets.all(2), child: Text('S No.', style: TextStyle(fontSize: 5, fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('Description of Service', style: TextStyle(fontSize: 5, fontWeight: FontWeight.bold, color: Colors.black))),
              Padding(padding: EdgeInsets.all(2), child: Text('No. of Vehicles', style: TextStyle(fontSize: 5, fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('Date', style: TextStyle(fontSize: 5, fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('From-To', style: TextStyle(fontSize: 5, fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('Qty/Days', style: TextStyle(fontSize: 5, fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('Rate (Rs.)', style: TextStyle(fontSize: 5, fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.right)),
              Padding(padding: EdgeInsets.all(2), child: Text('Amt (Rs.)', style: TextStyle(fontSize: 5, fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.right)),
            ],
          ),
          const TableRow(
            children: [
              Padding(padding: EdgeInsets.all(2), child: Text('1', style: TextStyle(fontSize: 5, color: Colors.black), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('Car Rental Charges', style: TextStyle(fontSize: 5, color: Colors.black))),
              Padding(padding: EdgeInsets.all(2), child: Text('1', style: TextStyle(fontSize: 5, color: Colors.black), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('21/06/2026', style: TextStyle(fontSize: 5, color: Colors.black), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('Dehradun - Haridwar', style: TextStyle(fontSize: 5, color: Colors.black), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('1.0', style: TextStyle(fontSize: 5, color: Colors.black), textAlign: TextAlign.center)),
              Padding(padding: EdgeInsets.all(2), child: Text('2500.00', style: TextStyle(fontSize: 5, color: Colors.black), textAlign: TextAlign.right)),
              Padding(padding: EdgeInsets.all(2), child: Text('2500.00', style: TextStyle(fontSize: 5, color: Colors.black), textAlign: TextAlign.right)),
            ],
          ),
        ],
      );
    }

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: const [
            Padding(padding: EdgeInsets.all(2), child: Text('Description', style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.black))),
            Padding(padding: EdgeInsets.all(2), child: Text('Qty/Days', style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.black))),
            Padding(padding: EdgeInsets.all(2), child: Text('Rate', style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.black))),
            Padding(padding: EdgeInsets.all(2), child: Text('Amount', style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.black))),
          ],
        ),
        const TableRow(
          children: [
            Padding(padding: EdgeInsets.all(2), child: Text('Item 1 charges details', style: TextStyle(fontSize: 6, color: Colors.black))),
            Padding(padding: EdgeInsets.all(2), child: Text('1.0', style: TextStyle(fontSize: 6, color: Colors.black))),
            Padding(padding: EdgeInsets.all(2), child: Text('2500.00', style: TextStyle(fontSize: 6, color: Colors.black))),
            Padding(padding: EdgeInsets.all(2), child: Text('2500.00', style: TextStyle(fontSize: 6, color: Colors.black))),
          ],
        ),
      ],
    );
  }

  Widget _buildTaxSummaryMock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        Text('Sub Total: Rs. 2,500.00', style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text('CGST (2.5%): Rs. 62.50', style: TextStyle(fontSize: 6, color: Colors.black87)),
        Text('SGST (2.5%): Rs. 62.50', style: TextStyle(fontSize: 6, color: Colors.black87)),
        Text('Total GST: Rs. 125.00', style: TextStyle(fontSize: 6, color: Colors.black87)),
        Text('Grand Total: Rs. 2,625.00', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
      ],
    );
  }

  // --- Right Side Panels Tabs ---

  Widget _buildFieldsTab(InvoiceTemplateSchema template) {
    final sections = [...template.sections]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sections & Fields',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _addSectionDialog(template),
                    icon: const Icon(Icons.add_box, size: 16),
                    label: const Text('Add Section', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addCustomFieldDialog(template),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Field', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Arrange, show, hide, rename sections and add custom fields. Tap fields in preview to highlight.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final sec = sections[index];
                final isSelected = _selectedSectionId == sec.id;

                return Card(
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: isSelected
                        ? const BorderSide(color: AppTheme.primaryGreen, width: 1.5)
                        : BorderSide(color: Colors.grey.shade200),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    initiallyExpanded: isSelected,
                    leading: const Icon(Icons.folder_open, color: AppTheme.deepBlue, size: 20),
                    title: Text(
                      sec.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text('ID: ${sec.id}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          tooltip: 'Rename Section',
                          onPressed: () => _renameSectionDialog(template, sec),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 16),
                          onPressed: index > 0 ? () => _moveSection(template, index, -1) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          onPressed: index < sections.length - 1 ? () => _moveSection(template, index, 1) : null,
                        ),
                        Switch(
                          value: sec.isVisible,
                          onChanged: (val) {
                            final updatedSections = template.sections.map((s) {
                              return s.id == sec.id ? s.copyWith(isVisible: val) : s;
                            }).toList();
                            
                            // Sync with footerSections
                            var updatedFooters = template.footerSections;
                            if (sec.id == 'terms_conditions') {
                              updatedFooters = template.footerSections.map((f) {
                                return f.id == 'terms_conditions' ? f.copyWith(isVisible: val) : f;
                              }).toList();
                            } else if (sec.id == 'payment_info') {
                              updatedFooters = template.footerSections.map((f) {
                                return f.id == 'bank_details' ? f.copyWith(isVisible: val) : f;
                              }).toList();
                            } else if (sec.id == 'signature') {
                              updatedFooters = template.footerSections.map((f) {
                                return f.id == 'signature' ? f.copyWith(isVisible: val) : f;
                              }).toList();
                            }

                            _updateTemplateSections(
                              template.copyWith(
                                sections: updatedSections,
                                footerSections: updatedFooters,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    children: [
                      if (sec.fields.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'No fields in this section',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                          child: Column(
                            children: sec.fields.asMap().entries.map((entry) {
                              final fIdx = entry.key;
                              final field = entry.value;
                              final isFieldSelected = _selectedFieldId == field.id;
                              return Container(
                                decoration: BoxDecoration(
                                  color: isFieldSelected
                                      ? AppTheme.primaryGreen.withOpacity(0.06)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                child: ListTile(
                                  dense: true,
                                  title: Text(
                                    field.label,
                                    style: TextStyle(
                                      fontWeight: isFieldSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Type: ${field.valueType} ${field.isCustom ? "(Custom)" : ""}',
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_upward, size: 14),
                                        onPressed: fIdx > 0 ? () => _moveField(template, sec.id, fIdx, -1) : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_downward, size: 14),
                                        onPressed: fIdx < sec.fields.length - 1 ? () => _moveField(template, sec.id, fIdx, 1) : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 14),
                                        tooltip: 'Rename Label',
                                        onPressed: () => _renameFieldDialog(template, sec.id, field),
                                      ),
                                      Switch(
                                        value: field.isVisible,
                                        onChanged: (val) {
                                          _updateFieldProperties(sec.id, field.id, field.copyWith(isVisible: val));
                                        },
                                      ),
                                      if (field.isCustom)
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                                          tooltip: 'Delete Custom Field',
                                          onPressed: () => _deleteCustomField(sec.id, field.id),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedSectionId = sec.id;
                                      _selectedFieldId = field.id;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTab(InvoiceTemplateSchema template) {
    final config = template.headerConfig;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Header & Logo Layout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
        ),
        const SizedBox(height: 12),

        SwitchListTile(
          title: const Text('Show Logo Image', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Toggle header branding logo visibility', style: TextStyle(fontSize: 11)),
          value: config.logoIsVisible,
          activeColor: AppTheme.primaryGreen,
          onChanged: (val) {
            _updateHeaderConfig(template, config.copyWith(logoIsVisible: val));
          },
        ),

        const Divider(),

        _buildSliderRow(
          title: 'Logo Scaling Factor',
          subtitle: 'Adjust width/height multiplier of the logo image',
          value: config.logoSize,
          min: 0.2,
          max: 3.0,
          divisions: 28,
          onChanged: (val) {
            _updateHeaderConfig(template, config.copyWith(logoSize: val));
          },
          label: '${config.logoSize.toStringAsFixed(1)}x',
        ),

        const Divider(),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: config.logoPosition,
            decoration: const InputDecoration(
              labelText: 'Logo Positioning',
              helperText: 'Horizontal position of the logo in the header',
            ),
            items: const [
              DropdownMenuItem(value: 'left', child: Text('Left Aligned')),
              DropdownMenuItem(value: 'center', child: Text('Centered')),
              DropdownMenuItem(value: 'right', child: Text('Right Aligned')),
            ],
            onChanged: (val) {
              if (val != null) {
                _updateHeaderConfig(template, config.copyWith(logoPosition: val));
              }
            },
          ),
        ),

        const Divider(),

        _buildSliderRow(
          title: 'Header Band Height',
          subtitle: 'Adjust the height space of the top header band',
          value: config.headerHeight,
          min: 50.0,
          max: 200.0,
          divisions: 30,
          onChanged: (val) {
            _updateHeaderConfig(template, config.copyWith(headerHeight: val));
          },
          label: '${config.headerHeight.toStringAsFixed(0)} pt',
        ),

        const Divider(),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: config.headerLayout,
            decoration: const InputDecoration(
              labelText: 'Header Arrangement Preset',
              helperText: 'Changes positioning flow of company & invoice info blocks',
            ),
            items: const [
              DropdownMenuItem(value: 'split', child: Text('Split (Company Left, Invoice Right)')),
              DropdownMenuItem(value: 'centered', child: Text('Centered Layout')),
              DropdownMenuItem(value: 'stacked', child: Text('Stacked Layout (Logo top, text under)')),
            ],
            onChanged: (val) {
              if (val != null) {
                _updateHeaderConfig(template, config.copyWith(headerLayout: val));
              }
            },
          ),
        ),

        const Divider(),

        _buildSliderRow(
          title: 'Inner Header Spacing',
          subtitle: 'Adjust gap between logo and company name text',
          value: config.headerSpacing,
          min: 0.0,
          max: 30.0,
          divisions: 30,
          onChanged: (val) {
            _updateHeaderConfig(template, config.copyWith(headerSpacing: val));
          },
          label: '${config.headerSpacing.toStringAsFixed(0)} pt',
        ),

        const Divider(),

        _buildSliderRow(
          title: 'Company Name Size',
          subtitle: 'Font size of company header name text',
          value: config.companyNameSize,
          min: 8.0,
          max: 24.0,
          divisions: 32,
          onChanged: (val) {
            _updateHeaderConfig(template, config.copyWith(companyNameSize: val));
          },
          label: '${config.companyNameSize.toStringAsFixed(1)} pt',
        ),

        const Divider(),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: config.headerAlignment,
            decoration: const InputDecoration(
              labelText: 'Header Text Alignment',
              helperText: 'Align company details and tagline texts',
            ),
            items: const [
              DropdownMenuItem(value: 'left', child: Text('Left')),
              DropdownMenuItem(value: 'center', child: Text('Center')),
              DropdownMenuItem(value: 'right', child: Text('Right')),
            ],
            onChanged: (val) {
              if (val != null) {
                _updateHeaderConfig(template, config.copyWith(headerAlignment: val));
              }
            },
          ),
        ),
      ],
    );
  }

  void _updateHeaderConfig(InvoiceTemplateSchema template, HeaderConfigSchema updatedHeader) {
    _updateTemplateSections(template.copyWith(headerConfig: updatedHeader));
  }

  Widget _buildSpacingTab(InvoiceTemplateSchema template) {
    final isTourism = template.id == 'tourism';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Page Spacing & Layout Presets',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
        ),
        const SizedBox(height: 12),

        Card(
          color: AppTheme.primaryGreen.withOpacity(0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.primaryGreen, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Layout Scaling Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                const Text(
                  'Instantly scale margins, paddings and font sizes to fit your invoice contents.',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: template.layoutPreset == 'compact' ? AppTheme.primaryGreen : Colors.grey.shade100,
                          foregroundColor: template.layoutPreset == 'compact' ? Colors.white : Colors.black,
                          elevation: 1,
                        ),
                        onPressed: () => _applyPreset(template, 'compact'),
                        child: const Text('Compact', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: template.layoutPreset == 'standard' ? AppTheme.primaryGreen : Colors.grey.shade100,
                          foregroundColor: template.layoutPreset == 'standard' ? Colors.white : Colors.black,
                          elevation: 1,
                        ),
                        onPressed: () => _applyPreset(template, 'standard'),
                        child: const Text('Standard', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: template.layoutPreset == 'large_print' ? AppTheme.primaryGreen : Colors.grey.shade100,
                          foregroundColor: template.layoutPreset == 'large_print' ? Colors.white : Colors.black,
                          elevation: 1,
                        ),
                        onPressed: () => _applyPreset(template, 'large_print'),
                        child: const Text('Large', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Divider(),

        if (isTourism) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Page Format and margins are locked for the LN Tourism fixed coordinate template.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButtonFormField<String>(
              value: template.pageFormat,
              decoration: const InputDecoration(
                labelText: 'Page Size Format',
              ),
              items: const [
                DropdownMenuItem(value: 'A4', child: Text('A4 (Standard)')),
                DropdownMenuItem(value: 'Letter', child: Text('US Letter')),
                DropdownMenuItem(value: 'Custom', child: Text('Custom Size')),
              ],
              onChanged: (val) {
                if (val != null) {
                  double width = 595.27;
                  double height = 841.89;
                  if (val == 'Letter') {
                    width = 612.0;
                    height = 792.0;
                  }
                  _updateTemplateSections(
                    template.copyWith(pageFormat: val, pageWidth: width, pageHeight: height),
                  );
                }
              },
            ),
          ),

          if (template.pageFormat == 'Custom') ...[
            _buildSliderRow(
              title: 'Page Width',
              subtitle: 'Custom page width in points',
              value: template.pageWidth,
              min: 300.0,
              max: 1000.0,
              divisions: 70,
              onChanged: (val) {
                _updateTemplateSections(template.copyWith(pageWidth: val));
              },
              label: '${template.pageWidth.toStringAsFixed(0)} pt',
            ),
            _buildSliderRow(
              title: 'Page Height',
              subtitle: 'Custom page height in points',
              value: template.pageHeight,
              min: 400.0,
              max: 1500.0,
              divisions: 110,
              onChanged: (val) {
                _updateTemplateSections(template.copyWith(pageHeight: val));
              },
              label: '${template.pageHeight.toStringAsFixed(0)} pt',
            ),
          ],

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Page Margins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          _marginSlider('Top Margin', template.marginTop, (v) {
            _updateTemplateSections(template.copyWith(marginTop: v));
          }),
          _marginSlider('Bottom Margin', template.marginBottom, (v) {
            _updateTemplateSections(template.copyWith(marginBottom: v));
          }),
          _marginSlider('Left Margin', template.marginLeft, (v) {
            _updateTemplateSections(template.copyWith(marginLeft: v).adjustColumnWidths());
          }),
          _marginSlider('Right Margin', template.marginRight, (v) {
            _updateTemplateSections(template.copyWith(marginRight: v).adjustColumnWidths());
          }),
        ],

        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Section Spacing & Gaps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        _buildSliderRow(
          title: 'Main Section Gap',
          subtitle: 'Space between major document content rows',
          value: template.sectionGap,
          min: 0.0,
          max: 50.0,
          divisions: 50,
          onChanged: (val) {
            _updateTemplateSections(template.copyWith(sectionGap: val));
          },
          label: '${template.sectionGap.toStringAsFixed(0)} pt',
        ),
        _buildSliderRow(
          title: 'Subsection Field Gap',
          subtitle: 'Gap between labels/inputs within details sections',
          value: template.subsectionGap,
          min: 0.0,
          max: 30.0,
          divisions: 30,
          onChanged: (val) {
            _updateTemplateSections(template.copyWith(subsectionGap: val));
          },
          label: '${template.subsectionGap.toStringAsFixed(0)} pt',
        ),
        _buildSliderRow(
          title: 'Table Spacing Gap',
          subtitle: 'Clearance gap above invoice line item table',
          value: template.tableGap,
          min: 0.0,
          max: 50.0,
          divisions: 50,
          onChanged: (val) {
            _updateTemplateSections(template.copyWith(tableGap: val));
          },
          label: '${template.tableGap.toStringAsFixed(0)} pt',
        ),
        _buildSliderRow(
          title: 'Footer Spacing Gap',
          subtitle: 'Gap between amounts box and signatory/terms footer sections',
          value: template.footerGap,
          min: 0.0,
          max: 50.0,
          divisions: 50,
          onChanged: (val) {
            _updateTemplateSections(template.copyWith(footerGap: val));
          },
          label: '${template.footerGap.toStringAsFixed(0)} pt',
        ),
      ],
    );
  }

  Widget _buildColumnsTab(InvoiceTemplateSchema template) {
    final cols = [...template.tableColumns]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Table Column Designer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable, rename, align, and resize columns. Custom columns will render at the end.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: cols.length,
              itemBuilder: (context, index) {
                final col = cols[index];
                final isStandard = const ['s_no', 'description', 'qty', 'rate', 'amount', 'no_of_vehicles', 'date', 'from_to'].contains(col.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ExpansionTile(
                    leading: const Icon(Icons.view_column, color: AppTheme.deepBlue),
                    title: Text(
                      col.label,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      'ID: ${col.id} | Width: ${col.isWidthFlexible ? "Flexible" : "${col.width.toStringAsFixed(0)}pt"}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 16),
                          onPressed: index > 0 ? () => _moveColumn(template, index, -1) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          onPressed: index < cols.length - 1 ? () => _moveColumn(template, index, 1) : null,
                        ),
                        Switch(
                          value: col.isVisible,
                          onChanged: (val) {
                            final updated = template.tableColumns.map((c) {
                              return c.id == col.id ? c.copyWith(isVisible: val) : c;
                            }).toList();
                            _updateTemplateSections(template.copyWith(tableColumns: updated).adjustColumnWidths());
                          },
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: TextEditingController(text: col.label)
                                ..selection = TextSelection.fromPosition(TextPosition(offset: col.label.length)),
                              decoration: const InputDecoration(
                                labelText: 'Column Header Display Label',
                              ),
                              onChanged: (val) {
                                final updated = template.tableColumns.map((c) {
                                  return c.id == col.id ? c.copyWith(label: val) : c;
                                }).toList();
                                _updateTemplateSections(template.copyWith(tableColumns: updated));
                              },
                            ),
                            const SizedBox(height: 12),

                            const Text('Text Alignment', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: 'left', label: Text('Left', style: TextStyle(fontSize: 11))),
                                ButtonSegment(value: 'center', label: Text('Center', style: TextStyle(fontSize: 11))),
                                ButtonSegment(value: 'right', label: Text('Right', style: TextStyle(fontSize: 11))),
                              ],
                              selected: {col.alignment},
                              onSelectionChanged: (val) {
                                final updated = template.tableColumns.map((c) {
                                  return c.id == col.id ? c.copyWith(alignment: val.first) : c;
                                }).toList();
                                _updateTemplateSections(template.copyWith(tableColumns: updated));
                              },
                            ),
                            const SizedBox(height: 12),

                            SwitchListTile(
                              dense: true,
                              title: const Text('Flexible Auto-width', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Allocates remaining page width. Recommended for description', style: TextStyle(fontSize: 10)),
                              value: col.isWidthFlexible,
                              onChanged: (val) {
                                final updated = template.tableColumns.map((c) {
                                  return c.id == col.id ? c.copyWith(isWidthFlexible: val) : c;
                                }).toList();
                                _updateTemplateSections(template.copyWith(tableColumns: updated).adjustColumnWidths());
                              },
                            ),

                            if (!col.isWidthFlexible) ...[
                              const SizedBox(height: 8),
                              _buildSliderRow(
                                title: 'Column Width',
                                subtitle: 'Specific width in points',
                                value: col.width,
                                min: 20.0,
                                max: 300.0,
                                divisions: 56,
                                onChanged: (val) {
                                  final updated = template.tableColumns.map((c) {
                                    return c.id == col.id ? c.copyWith(width: val) : c;
                                  }).toList();
                                  _updateTemplateSections(template.copyWith(tableColumns: updated).adjustColumnWidths());
                                },
                                label: '${col.width.toStringAsFixed(0)} pt',
                              ),
                            ],

                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: col.dataType,
                              decoration: const InputDecoration(labelText: 'Column Data Type'),
                              items: const [
                                DropdownMenuItem(value: 'text', child: Text('Text')),
                                DropdownMenuItem(value: 'number', child: Text('Number')),
                                DropdownMenuItem(value: 'currency', child: Text('Currency / Money')),
                                DropdownMenuItem(value: 'date', child: Text('Date')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  final updated = template.tableColumns.map((c) {
                                    return c.id == col.id ? c.copyWith(dataType: val) : c;
                                  }).toList();
                                  _updateTemplateSections(template.copyWith(tableColumns: updated));
                                }
                              },
                            ),

                            if (!isStandard) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  final updated = template.tableColumns.where((c) => c.id != col.id).toList();
                                  _updateTemplateSections(template.copyWith(tableColumns: updated).adjustColumnWidths());
                                },
                                icon: const Icon(Icons.delete_outline, size: 16),
                                label: const Text('Delete Column', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootersTab(InvoiceTemplateSchema template) {
    final footers = [...template.footerSections]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Footer Layout Designer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure columns at the bottom of the invoice: terms & conditions, bank details, signatory.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: footers.length,
              itemBuilder: (context, index) {
                final ft = footers[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ExpansionTile(
                    leading: const Icon(Icons.subtitles, color: AppTheme.deepBlue),
                    title: Text(
                      ft.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      'ID: ${ft.id} | Width Weight: ${ft.widthPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 16),
                          onPressed: index > 0 ? () => _moveFooterSection(template, index, -1) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          onPressed: index < footers.length - 1 ? () => _moveFooterSection(template, index, 1) : null,
                        ),
                        Switch(
                          value: ft.isVisible,
                          onChanged: (val) {
                            final updatedFooters = template.footerSections.map((f) {
                              return f.id == ft.id ? f.copyWith(isVisible: val) : f;
                            }).toList();

                            // Sync with sections
                            var updatedSections = template.sections;
                            if (ft.id == 'terms_conditions') {
                              updatedSections = template.sections.map((s) {
                                return s.id == 'terms_conditions' ? s.copyWith(isVisible: val) : s;
                              }).toList();
                            } else if (ft.id == 'bank_details') {
                              updatedSections = template.sections.map((s) {
                                return s.id == 'payment_info' ? s.copyWith(isVisible: val) : s;
                              }).toList();
                            } else if (ft.id == 'signature') {
                              updatedSections = template.sections.map((s) {
                                return s.id == 'signature' ? s.copyWith(isVisible: val) : s;
                              }).toList();
                            }

                            _updateTemplateSections(
                              template.copyWith(
                                footerSections: updatedFooters,
                                sections: updatedSections,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: TextEditingController(text: ft.title)
                                ..selection = TextSelection.fromPosition(TextPosition(offset: ft.title.length)),
                              decoration: const InputDecoration(labelText: 'Footer Section Header Title'),
                              onChanged: (val) {
                                final updated = template.footerSections.map((f) {
                                  return f.id == ft.id ? f.copyWith(title: val) : f;
                                }).toList();
                                _updateTemplateSections(template.copyWith(footerSections: updated));
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildSliderRow(
                              title: 'Width Percentage (%)',
                              subtitle: 'Horizontal share relative to page width',
                              value: ft.widthPercent,
                              min: 10.0,
                              max: 100.0,
                              divisions: 90,
                              onChanged: (val) {
                                final updated = template.footerSections.map((f) {
                                  return f.id == ft.id ? f.copyWith(widthPercent: val) : f;
                                }).toList();
                                _updateTemplateSections(template.copyWith(footerSections: updated));
                              },
                              label: '${ft.widthPercent.toStringAsFixed(0)}%',
                            ),
                            const SizedBox(height: 12),
                            _buildSliderRow(
                              title: 'Section Area Height',
                              subtitle: 'Vertical bounds limits of this block',
                              value: ft.height,
                              min: 40.0,
                              max: 150.0,
                              divisions: 22,
                              onChanged: (val) {
                                final updated = template.footerSections.map((f) {
                                  return f.id == ft.id ? f.copyWith(height: val) : f;
                                }).toList();
                                _updateTemplateSections(template.copyWith(footerSections: updated));
                              },
                              label: '${ft.height.toStringAsFixed(0)} pt',
                            ),
                            const SizedBox(height: 12),
                            const Text('Text Alignment', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: 'left', label: Text('Left', style: TextStyle(fontSize: 11))),
                                ButtonSegment(value: 'center', label: Text('Center', style: TextStyle(fontSize: 11))),
                                ButtonSegment(value: 'right', label: Text('Right', style: TextStyle(fontSize: 11))),
                              ],
                              selected: {ft.alignment},
                              onSelectionChanged: (val) {
                                final updated = template.footerSections.map((f) {
                                  return f.id == ft.id ? f.copyWith(alignment: val.first) : f;
                                }).toList();
                                _updateTemplateSections(template.copyWith(footerSections: updated));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypographyTab(InvoiceTemplateSchema template) {
    final currentStyle = template.typography[_selectedStyleClass] ??
        TextStyleSchema(fontSize: 9, fontWeight: 'normal', fontFamily: 'Times New Roman', textColor: '#000000');

    final List<String> fontFamilies = ['Times New Roman', 'Helvetica', 'Courier', 'Arial', 'Outfit', 'Inter'];
    final presetColors = ['#000000', '#0B3B60', '#499F34', '#E57A25', '#FF0000', '#777777', '#3F51B5', '#009688'];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Typography & Styling',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
        ),
        const SizedBox(height: 8),
        const Text(
          'Control layout typography parameters class by class.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _selectedStyleClass,
          decoration: const InputDecoration(
            labelText: 'Target Text Element Class',
            border: OutlineInputBorder(),
          ),
          items: _styleClasses.map((item) {
            return DropdownMenuItem(value: item['id'], child: Text(item['name']!));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedStyleClass = val;
              });
            }
          },
        ),

        const SizedBox(height: 16),
        const Divider(),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: fontFamilies.contains(currentStyle.fontFamily) ? currentStyle.fontFamily : 'Times New Roman',
            decoration: const InputDecoration(labelText: 'Font Family'),
            items: fontFamilies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (val) {
              if (val != null) {
                _updateTypography(template, _selectedStyleClass, currentStyle.copyWith(fontFamily: val));
              }
            },
          ),
        ),

        const Divider(),

        _buildSliderRow(
          title: 'Font Size',
          subtitle: 'Base text height in points',
          value: currentStyle.fontSize,
          min: 5.0,
          max: 30.0,
          divisions: 50,
          onChanged: (val) {
            _updateTypography(template, _selectedStyleClass, currentStyle.copyWith(fontSize: val));
          },
          label: '${currentStyle.fontSize.toStringAsFixed(1)} pt',
        ),

        const Divider(),

        SwitchListTile(
          title: const Text('Bold Typeface', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Render text with bold font-weight', style: TextStyle(fontSize: 11)),
          value: currentStyle.fontWeight == 'bold',
          activeColor: AppTheme.primaryGreen,
          onChanged: (val) {
            _updateTypography(
              template,
              _selectedStyleClass,
              currentStyle.copyWith(fontWeight: val ? 'bold' : 'normal'),
            );
          },
        ),

        const Divider(),

        _buildSliderRow(
          title: 'Line Height spacing',
          subtitle: 'Vertical line height multiplier factor',
          value: currentStyle.lineHeight,
          min: 0.8,
          max: 2.5,
          divisions: 17,
          onChanged: (val) {
            _updateTypography(template, _selectedStyleClass, currentStyle.copyWith(lineHeight: val));
          },
          label: '${currentStyle.lineHeight.toStringAsFixed(1)}x',
        ),

        const Divider(),

        _buildSliderRow(
          title: 'Letter Spacing',
          subtitle: 'Spacing gap details between text characters',
          value: currentStyle.letterSpacing,
          min: -1.0,
          max: 5.0,
          divisions: 30,
          onChanged: (val) {
            _updateTypography(template, _selectedStyleClass, currentStyle.copyWith(letterSpacing: val));
          },
          label: '${currentStyle.letterSpacing.toStringAsFixed(1)} pt',
        ),

        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Text Color Hex', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),

        TextField(
          controller: TextEditingController(text: currentStyle.textColor)
            ..selection = TextSelection.fromPosition(TextPosition(offset: currentStyle.textColor.length)),
          decoration: const InputDecoration(
            labelText: 'Hex Color Value (e.g. #0B3B60)',
            prefixIcon: Icon(Icons.color_lens, size: 16),
          ),
          onChanged: (val) {
            if (val.startsWith('#') && (val.length == 7 || val.length == 9)) {
              _updateTypography(template, _selectedStyleClass, currentStyle.copyWith(textColor: val));
            }
          },
        ),

        const SizedBox(height: 12),
        const Text('Color Presets', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presetColors.map((colorHex) {
            final color = _parseColor(colorHex);
            final isSelected = currentStyle.textColor.toLowerCase() == colorHex.toLowerCase();
            return GestureDetector(
              onTap: () {
                _updateTypography(template, _selectedStyleClass, currentStyle.copyWith(textColor: colorHex));
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade400,
                    width: isSelected ? 3.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Slider(
            min: min,
            max: max,
            value: value,
            divisions: divisions,
            activeColor: AppTheme.primaryGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _marginSlider(String label, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text('${value.toStringAsFixed(0)} pt', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          Slider(
            min: 5,
            max: 100,
            value: value,
            activeColor: AppTheme.primaryGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- Helper state update triggers ---

  void _updateTemplateSections(InvoiceTemplateSchema updated) {
    ref.read(invoiceFormProvider.notifier).updateTemplate(updated);
  }

  void _updateTypography(InvoiceTemplateSchema template, String key, TextStyleSchema updatedStyle) {
    final Map<String, TextStyleSchema> updatedTy = Map.of(template.typography);
    updatedTy[key] = updatedStyle;
    _updateTemplateSections(template.copyWith(typography: updatedTy));
  }

  void _updateFieldProperties(String sectionId, String fieldId, FieldSchema updatedField) {
    final state = ref.read(invoiceFormProvider);
    final template = state.activeTemplate;

    final updated = template.sections.map((s) {
      if (s.id == sectionId) {
        final updatedFields = s.fields.map((f) {
          return f.id == fieldId ? updatedField : f;
        }).toList();
        return s.copyWith(fields: updatedFields);
      }
      return s;
    }).toList();

    _updateTemplateSections(template.copyWith(sections: updated));
  }

  void _updateFieldPosition(String sectionId, String fieldId, double newX, double newY) {
    final state = ref.read(invoiceFormProvider);
    final template = state.activeTemplate;

    final updated = template.sections.map((s) {
      if (s.id == sectionId) {
        final updatedFields = s.fields.map((f) {
          return f.id == fieldId ? f.copyWith(posX: newX, posY: newY) : f;
        }).toList();
        return s.copyWith(fields: updatedFields);
      }
      return s;
    }).toList();

    _updateTemplateSections(template.copyWith(sections: updated));
  }

  void _deleteCustomField(String sectionId, String fieldId) {
    final state = ref.read(invoiceFormProvider);
    final template = state.activeTemplate;

    final updated = template.sections.map((s) {
      if (s.id == sectionId) {
        final updatedFields = s.fields.where((f) => f.id != fieldId).toList();
        return s.copyWith(fields: updatedFields);
      }
      return s;
    }).toList();

    setState(() {
      _selectedFieldId = null;
    });
    _updateTemplateSections(template.copyWith(sections: updated));
  }

  void _applyPreset(InvoiceTemplateSchema template, String preset) {
    double sizeMultiplier = 1.0;
    double marginValue = 24.0;

    if (preset == 'compact') {
      sizeMultiplier = 0.85;
      marginValue = 12.0;
    } else if (preset == 'large_print') {
      sizeMultiplier = 1.2;
      marginValue = 36.0;
    }

    final updated = template.sections.map((s) {
      final fields = s.fields.map((f) {
        return f.copyWith(fontSize: f.fontSize * sizeMultiplier);
      }).toList();
      return s.copyWith(fields: fields);
    }).toList();

    _updateTemplateSections(
      template.copyWith(
        layoutPreset: preset,
        marginTop: marginValue,
        marginBottom: marginValue,
        marginLeft: marginValue,
        marginRight: marginValue,
        sections: updated,
      ),
    );
  }

  void _moveSection(InvoiceTemplateSchema template, int index, int direction) {
    final newIndex = index + direction;
    final sortedList = [...template.sections]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (newIndex < 0 || newIndex >= sortedList.length) return;

    final item = sortedList.removeAt(index);
    sortedList.insert(newIndex, item);

    final updatedList = sortedList.asMap().entries.map((e) {
      return e.value.copyWith(orderIndex: e.key);
    }).toList();

    _updateTemplateSections(template.copyWith(sections: updatedList));
  }

  void _moveColumn(InvoiceTemplateSchema template, int index, int direction) {
    final newIndex = index + direction;
    final sortedList = [...template.tableColumns]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (newIndex < 0 || newIndex >= sortedList.length) return;

    final item = sortedList.removeAt(index);
    sortedList.insert(newIndex, item);

    final updatedList = sortedList.asMap().entries.map((e) {
      return e.value.copyWith(orderIndex: e.key);
    }).toList();

    _updateTemplateSections(template.copyWith(tableColumns: updatedList).adjustColumnWidths());
  }

  void _moveFooterSection(InvoiceTemplateSchema template, int index, int direction) {
    final newIndex = index + direction;
    final sortedList = [...template.footerSections]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (newIndex < 0 || newIndex >= sortedList.length) return;

    final item = sortedList.removeAt(index);
    sortedList.insert(newIndex, item);

    final updatedList = sortedList.asMap().entries.map((e) {
      return e.value.copyWith(orderIndex: e.key);
    }).toList();

    _updateTemplateSections(template.copyWith(footerSections: updatedList));
  }

  void _moveField(InvoiceTemplateSchema template, String sectionId, int index, int direction) {
    final newIndex = index + direction;
    
    final updatedSections = template.sections.map((s) {
      if (s.id == sectionId) {
        if (newIndex < 0 || newIndex >= s.fields.length) return s;
        final list = [...s.fields];
        final item = list.removeAt(index);
        list.insert(newIndex, item);
        return s.copyWith(fields: list);
      }
      return s;
    }).toList();

    _updateTemplateSections(template.copyWith(sections: updatedSections));
  }

  void _addSectionDialog(InvoiceTemplateSchema template) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Section'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Section Title (e.g. Booking Details)',
            hintText: 'Enter title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isNotEmpty) {
                final sectionId = 'custom_${title.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
                final maxOrderIndex = template.sections.isEmpty
                    ? 0
                    : template.sections.map((s) => s.orderIndex).reduce((a, b) => a > b ? a : b);
                
                final newSection = SectionSchema(
                  id: sectionId,
                  title: title,
                  isVisible: true,
                  orderIndex: maxOrderIndex + 1,
                  fields: [],
                );

                _updateTemplateSections(
                  template.copyWith(
                    sections: [...template.sections, newSection],
                  ),
                );
                titleCtrl.dispose();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Section'),
          ),
        ],
      ),
    );
  }

  void _addCustomFieldDialog(InvoiceTemplateSchema template) {
    final nameCtrl = TextEditingController();
    final optionsCtrl = TextEditingController();
    String fieldType = 'text';
    String targetSectionId = 'invoice_info';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: const Text('Add Dynamic Custom Field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Field Name (e.g. Vehicle Number)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: fieldType,
                  decoration: const InputDecoration(labelText: 'Field Type'),
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('Text')),
                    DropdownMenuItem(value: 'number', child: Text('Number')),
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                    DropdownMenuItem(value: 'time', child: Text('Time')),
                    DropdownMenuItem(value: 'currency', child: Text('Currency')),
                    DropdownMenuItem(value: 'checkbox', child: Text('Checkbox')),
                    DropdownMenuItem(value: 'dropdown', child: Text('Dropdown')),
                    DropdownMenuItem(value: 'radio', child: Text('Radio Button')),
                    DropdownMenuItem(value: 'multiline', child: Text('Multi-line Text')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setStateBuilder(() {
                        fieldType = val;
                      });
                    }
                  },
                ),
                if (fieldType == 'dropdown' || fieldType == 'radio') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: optionsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Options (comma-separated)',
                      helperText: 'Options to select (e.g. Sedan, SUV)',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: targetSectionId,
                  decoration: const InputDecoration(labelText: 'Render in Section'),
                  items: template.sections
                      .where((s) => s.id != 'items_table' && s.id != 'tax_summary')
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.title)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateBuilder(() {
                        targetSectionId = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final fieldId = name.toLowerCase().replaceAll(' ', '_');
                  final List<String> options = optionsCtrl.text.isNotEmpty
                      ? optionsCtrl.text.split(',').map((o) => o.trim()).where((o) => o.isNotEmpty).toList()
                      : [];

                  final newField = FieldSchema(
                    id: fieldId,
                    label: name,
                    valueType: fieldType,
                    isCustom: true,
                    posX: 10,
                    posY: 10,
                    dropdownOptions: options.isNotEmpty ? options : null,
                  );

                  final updatedSections = template.sections.map((s) {
                    if (s.id == targetSectionId) {
                      return s.copyWith(fields: [...s.fields, newField]);
                    }
                    return s;
                  }).toList();

                  _updateTemplateSections(template.copyWith(sections: updatedSections));
                  nameCtrl.dispose();
                  optionsCtrl.dispose();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Field'),
            ),
          ],
        ),
      ),
    );
  }

  void _renameSectionDialog(InvoiceTemplateSchema template, SectionSchema sec) {
    final titleCtrl = TextEditingController(text: sec.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename Section: ${sec.title}'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'New Section Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newTitle = titleCtrl.text.trim();
              if (newTitle.isNotEmpty) {
                final updated = template.sections.map((s) {
                  return s.id == sec.id ? s.copyWith(title: newTitle) : s;
                }).toList();
                _updateTemplateSections(template.copyWith(sections: updated));
                titleCtrl.dispose();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _renameFieldDialog(InvoiceTemplateSchema template, String sectionId, FieldSchema field) {
    final labelCtrl = TextEditingController(text: field.label);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename Field: ${field.label}'),
        content: TextField(
          controller: labelCtrl,
          decoration: const InputDecoration(labelText: 'New Display Label'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newLabel = labelCtrl.text.trim();
              if (newLabel.isNotEmpty) {
                _updateFieldProperties(sectionId, field.id, field.copyWith(label: newLabel));
                labelCtrl.dispose();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }
}
