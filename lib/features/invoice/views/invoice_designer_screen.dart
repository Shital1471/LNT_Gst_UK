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

class _InvoiceDesignerScreenState extends ConsumerState<InvoiceDesignerScreen> {
  String? _selectedSectionId;
  String? _selectedFieldId;
  bool _enableAbsoluteDragging = false;

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
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: AppTheme.deepBlue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppTheme.primaryGreen,
                      tabs: [
                        Tab(icon: Icon(Icons.grid_view), text: 'Sections'),
                        Tab(icon: Icon(Icons.tune), text: 'Properties'),
                        Tab(icon: Icon(Icons.settings), text: 'Page & Presets'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSectionsTab(activeT),
                          _buildPropertiesTab(activeT),
                          _buildPageSettingsTab(activeT),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Visual Canvas Component Builder ---
  Widget _buildCanvasPage(InvoiceTemplateSchema template) {
    // Proportional dimensions for A4 mockup: 595 x 841 points -> scaled down to 480 width
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
        scale: scale,
        isDesigner: true,
        selectedSectionId: _selectedSectionId,
        selectedFieldId: _selectedFieldId,
        onTapField: (sectionId, fieldId) {
          setState(() {
            _selectedSectionId = sectionId;
            _selectedFieldId = fieldId;
          });
        },
      );
    }

    // Filter and sort visible sections
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

  Widget _buildTourismHeaderMock(InvoiceTemplateSchema template, double scale) {
    final companySec = template.sections.firstWhere((s) => s.id == 'company_details');
    final invoiceSec = template.sections.firstWhere((s) => s.id == 'invoice_info');
    
    final isCompanySelected = _selectedSectionId == 'company_details';
    final isInvoiceSelected = _selectedSectionId == 'invoice_info';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Company details
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSectionId = 'company_details';
                _selectedFieldId = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isCompanySelected ? AppTheme.primaryGreen : Colors.transparent,
                ),
                color: isCompanySelected ? AppTheme.primaryGreen.withOpacity(0.04) : Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LN TOURISM PRIVATE LIMITED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.deepBlue),
                  ),
                  const Text(
                    'TOURS & TRAVELS | CAR RENTAL | TRANSPORT SOLUTIONS',
                    style: TextStyle(fontSize: 5.5, fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
                  ),
                  const SizedBox(height: 2),
                  _buildSectionFields(companySec, scale),
                ],
              ),
            ),
          ),
        ),
        
        // Green vertical separator
        Container(
          width: 1 * scale,
          height: 50 * scale,
          color: AppTheme.primaryGreen,
          margin: const EdgeInsets.symmetric(horizontal: 4),
        ),

        // Right Column: Invoice Info Box
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSectionId = 'invoice_info';
                _selectedFieldId = null;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isInvoiceSelected ? AppTheme.primaryGreen : AppTheme.primaryGreen.withOpacity(0.5),
                  width: isInvoiceSelected ? 1.5 : 1,
                ),
                color: isInvoiceSelected ? AppTheme.primaryGreen.withOpacity(0.04) : Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    alignment: Alignment.center,
                    child: const Text(
                      'INVOICE',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: _buildSectionFields(invoiceSec, scale),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTourismBillToAndServiceMock(InvoiceTemplateSchema template, double scale) {
    final customerSec = template.sections.firstWhere((s) => s.id == 'customer_details');
    final serviceSec = template.sections.firstWhere((s) => s.id == 'service_details');

    final isCustomerSelected = _selectedSectionId == 'customer_details';
    final isServiceSelected = _selectedSectionId == 'service_details';

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black54),
          bottom: BorderSide(color: Colors.black54),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BILL TO
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSectionId = 'customer_details';
                  _selectedFieldId = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isCustomerSelected ? AppTheme.primaryGreen : Colors.transparent,
                  ),
                  color: isCustomerSelected ? AppTheme.primaryGreen.withOpacity(0.04) : Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BILL TO',
                      style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                    const Divider(height: 4, color: Colors.black),
                    _buildSectionFields(customerSec, scale),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // SERVICE DETAIL 8
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSectionId = 'service_details';
                  _selectedFieldId = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isServiceSelected ? AppTheme.primaryGreen : Colors.transparent,
                  ),
                  color: isServiceSelected ? AppTheme.primaryGreen.withOpacity(0.04) : Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SERVICE DETAIL 8',
                      style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                    const Divider(height: 4, color: Colors.black),
                    _buildSectionFields(serviceSec, scale),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourismItemsTableMock(InvoiceTemplateSchema template, double scale) {
    final isSelected = _selectedSectionId == 'items_table';
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSectionId = 'items_table';
          _selectedFieldId = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          ),
          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.04) : Colors.transparent,
        ),
        padding: const EdgeInsets.all(2),
        child: _buildItemsTableMock('tourism'),
      ),
    );
  }

  Widget _buildTourismTotalsMock(InvoiceTemplateSchema template, double scale) {
    final isSelected = _selectedSectionId == 'tax_summary';
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSectionId = 'tax_summary';
          _selectedFieldId = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          ),
          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.04) : Colors.transparent,
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Words left
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black87),
                ),
                child: const Text(
                  'Amount to be paid in words : Two Thousand Six Hundred Twenty Five Rupees Only.',
                  style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Summary right
            SizedBox(
              width: 120 * scale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _totalsRowMock("Sub Total", "2500.00"),
                  _totalsRowMock("CGST (2.5%)", "62.50"),
                  _totalsRowMock("SGST (2.5%)", "62.50"),
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Total Amount', style: TextStyle(color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.bold)),
                        Text('Rs. 2625.00', style: TextStyle(color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  _totalsRowMock("Advance Paid", "0.00"),
                  _totalsRowMock("Amount To Be Paid", "2625.00", isBold: true),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _totalsRowMock(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 5.5, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("Rs. $value", style: TextStyle(fontSize: 5.5, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildTourismFooterMock(InvoiceTemplateSchema template, double scale) {
    final paymentSec = template.sections.firstWhere((s) => s.id == 'payment_info');
    final termsSec = template.sections.firstWhere((s) => s.id == 'terms_conditions');
    final sigSec = template.sections.firstWhere((s) => s.id == 'signature');

    final isPaymentSelected = _selectedSectionId == 'payment_info';
    final isTermsSelected = _selectedSectionId == 'terms_conditions';
    final isSigSelected = _selectedSectionId == 'signature';

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black54),
          bottom: BorderSide(color: Colors.black54),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terms & Conditions
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSectionId = 'terms_conditions';
                  _selectedFieldId = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: isTermsSelected ? AppTheme.primaryGreen : Colors.transparent),
                  color: isTermsSelected ? AppTheme.primaryGreen.withOpacity(0.04) : Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TERM & CONDITION 8', style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    const SizedBox(height: 2),
                    _buildSectionFields(termsSec, scale),
                  ],
                ),
              ),
            ),
          ),
          
          // Green divider
          Container(
            width: 0.5 * scale,
            height: 40 * scale,
            color: AppTheme.primaryGreen,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),

          // Bank Details
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSectionId = 'payment_info';
                  _selectedFieldId = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: isPaymentSelected ? AppTheme.primaryGreen : Colors.transparent),
                  color: isPaymentSelected ? AppTheme.primaryGreen.withOpacity(0.04) : Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BANK DETAIL 8', style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    const SizedBox(height: 2),
                    _buildSectionFields(paymentSec, scale),
                  ],
                ),
              ),
            ),
          ),

          // Green divider
          Container(
            width: 0.5 * scale,
            height: 40 * scale,
            color: AppTheme.primaryGreen,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),

          // Signature Block
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSectionId = 'signature';
                  _selectedFieldId = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: isSigSelected ? AppTheme.primaryGreen : Colors.transparent),
                  color: isSigSelected ? AppTheme.primaryGreen.withOpacity(0.04) : Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('FOR LN TOURISM PVT. LTD.', style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: AppTheme.deepBlue)),
                    const SizedBox(height: 12),
                    const Text('Abhishek Prajapati', style: TextStyle(fontSize: 8, fontStyle: FontStyle.italic, color: Colors.blue, fontWeight: FontWeight.bold)),
                    const Divider(height: 4, color: Colors.grey),
                    _buildSectionFields(sigSec, scale),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      // Standard Fields section
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
      // Absolute positioning mode
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
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final newX = (f.posX ?? 0.0) + details.delta.dx / scale;
                    final newY = (f.posY ?? 0.0) + details.delta.dy / scale;
                    _updateFieldPosition(sec.id, f.id, newX, newY);
                  }
                },
                child: _buildFieldChip(sec.id, f),
              ),
            );
          }).toList(),
        ),
      );
    }

    // Grid layout mode (Standard flow)
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

  Widget _buildSectionsTab(InvoiceTemplateSchema template) {
    final sections = template.sections;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Arrange Sections', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.primaryGreen),
                tooltip: 'Add Custom Field',
                onPressed: () => _addCustomFieldDialog(template),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Drag and drop elements to reorder sections. Use switch to show/hide sections.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
          Expanded(
            child: ReorderableListView(
              buildDefaultDragHandles: true,
              onReorder: (oldIdx, newIdx) {
                if (newIdx > oldIdx) newIdx -= 1;
                final list = [...sections];
                final item = list.removeAt(oldIdx);
                list.insert(newIdx, item);

                // Update order indexes
                final updatedList = list.asMap().entries.map((e) {
                  return e.value.copyWith(orderIndex: e.key);
                }).toList();

                _updateTemplateSections(template.copyWith(sections: updatedList));
              },
              children: sections.map((sec) {
                return Card(
                  key: ValueKey(sec.id),
                  child: ListTile(
                    leading: const Icon(Icons.drag_indicator),
                    title: Text(sec.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('ID: ${sec.id}', style: const TextStyle(fontSize: 10)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () => _renameSectionDialog(template, sec),
                        ),
                        Switch(
                          value: sec.isVisible,
                          onChanged: (val) {
                            final updated = template.sections.map((s) {
                              return s.id == sec.id ? s.copyWith(isVisible: val) : s;
                            }).toList();
                            _updateTemplateSections(template.copyWith(sections: updated));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesTab(InvoiceTemplateSchema template) {
    if (_selectedFieldId == null && _selectedSectionId == null) {
      return const Center(child: Text('Select an element in canvas to customize properties'));
    }

    if (_selectedFieldId != null) {
      // Customize specific field details
      final sec = template.sections.firstWhere((s) => s.id == _selectedSectionId);
      final field = sec.fields.firstWhere((f) => f.id == _selectedFieldId);

      return _buildFieldInspector(template, sec.id, field);
    }

    // Customize section properties
    final sec = template.sections.firstWhere((s) => s.id == _selectedSectionId);
    return _buildSectionInspector(template, sec);
  }

  Widget _buildSectionInspector(InvoiceTemplateSchema template, SectionSchema sec) {
    final titleCtrl = TextEditingController(text: sec.title);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Section Properties: ${sec.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: 'Section Title'),
            onChanged: (val) {
              final updated = template.sections.map((s) {
                return s.id == sec.id ? s.copyWith(title: val) : s;
              }).toList();
              _updateTemplateSections(template.copyWith(sections: updated));
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Visible'),
              Switch(
                value: sec.isVisible,
                onChanged: (val) {
                  final updated = template.sections.map((s) {
                    return s.id == sec.id ? s.copyWith(isVisible: val) : s;
                  }).toList();
                  _updateTemplateSections(template.copyWith(sections: updated));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (template.id != 'tourism' && sec.id != 'items_table' && sec.id != 'tax_summary') ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Enable Absolute Draggable Coordinates'),
                Checkbox(
                  value: _enableAbsoluteDragging,
                  onChanged: (val) {
                    setState(() {
                      _enableAbsoluteDragging = val ?? false;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldInspector(InvoiceTemplateSchema template, String sectionId, FieldSchema field) {
    final labelCtrl = TextEditingController(text: field.label);
    final sizeCtrl = TextEditingController(text: field.fontSize.toString());
    final isBold = field.fontWeight == 'bold';

    final presetColors = ['#000000', '#0B3B60', '#499F34', '#E57A25', '#FF0000', '#777777'];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('Field: ${field.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: labelCtrl,
          decoration: const InputDecoration(labelText: 'Display Label'),
          onChanged: (val) {
            _updateFieldProperties(sectionId, field.id, field.copyWith(label: val));
          },
        ),
        if (template.id != 'tourism') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: sizeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Font Size'),
                  onChanged: (val) {
                    final size = double.tryParse(val) ?? field.fontSize;
                    _updateFieldProperties(sectionId, field.id, field.copyWith(fontSize: size));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const Text('Bold font', style: TextStyle(fontSize: 10)),
                  Checkbox(
                    value: isBold,
                    onChanged: (val) {
                      _updateFieldProperties(
                        sectionId,
                        field.id,
                        field.copyWith(fontWeight: val == true ? 'bold' : 'normal'),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          const Text('Align text'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'left', label: Text('Left')),
              ButtonSegment(value: 'center', label: Text('Center')),
              ButtonSegment(value: 'right', label: Text('Right')),
            ],
            selected: {field.alignment},
            onSelectionChanged: (val) {
              _updateFieldProperties(sectionId, field.id, field.copyWith(alignment: val.first));
            },
          ),
          const SizedBox(height: 16),
          const Text('Color presets'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: presetColors.map((colorHex) {
              final color = _parseColor(colorHex);
              final isSelected = field.textColor.toLowerCase() == colorHex.toLowerCase();
              return GestureDetector(
                onTap: () {
                  _updateFieldProperties(sectionId, field.id, field.copyWith(textColor: colorHex));
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryGreen : Colors.grey,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Visible'),
            Switch(
              value: field.isVisible,
              onChanged: (val) {
                _updateFieldProperties(sectionId, field.id, field.copyWith(isVisible: val));
              },
            ),
          ],
        ),
        if (field.isCustom) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _deleteCustomField(sectionId, field.id);
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete Custom Field'),
          ),
        ]
      ],
    );
  }

  Widget _buildPageSettingsTab(InvoiceTemplateSchema template) {
    if (template.id == 'tourism') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Page settings and margins are locked for the LN Tourism fixed coordinate template.',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Layout presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: template.layoutPreset == 'compact' ? AppTheme.primaryGreen : null,
                ),
                onPressed: () => _applyPreset(template, 'compact'),
                child: const Text('Compact'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: template.layoutPreset == 'standard' ? AppTheme.primaryGreen : null,
                ),
                onPressed: () => _applyPreset(template, 'standard'),
                child: const Text('Standard'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: template.layoutPreset == 'large_print' ? AppTheme.primaryGreen : null,
                ),
                onPressed: () => _applyPreset(template, 'large_print'),
                child: const Text('Large Print'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        const Text('Page Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: template.pageFormat,
          decoration: const InputDecoration(labelText: 'Page Size Format'),
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
        const SizedBox(height: 16),
        const Text('Page Margins (points)', style: TextStyle(fontSize: 12, color: Colors.grey)),
        _marginSlider('Top Margin', template.marginTop, (v) {
          _updateTemplateSections(template.copyWith(marginTop: v));
        }),
        _marginSlider('Bottom Margin', template.marginBottom, (v) {
          _updateTemplateSections(template.copyWith(marginBottom: v));
        }),
        _marginSlider('Left Margin', template.marginLeft, (v) {
          _updateTemplateSections(template.copyWith(marginLeft: v));
        }),
        _marginSlider('Right Margin', template.marginRight, (v) {
          _updateTemplateSections(template.copyWith(marginRight: v));
        }),
      ],
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

  void _addCustomFieldDialog(InvoiceTemplateSchema template) {
    final nameCtrl = TextEditingController();
    String fieldType = 'text';
    String targetSectionId = 'invoice_info';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: const Text('Add Dynamic Custom Field'),
          content: Column(
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
                  DropdownMenuItem(value: 'currency', child: Text('Currency')),
                  DropdownMenuItem(value: 'checkbox', child: Text('Checkbox')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setStateBuilder(() {
                      fieldType = val;
                    });
                  }
                },
              ),
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
                  final newField = FieldSchema(
                    id: fieldId,
                    label: name,
                    valueType: fieldType,
                    isCustom: true,
                    posX: 10,
                    posY: 10,
                  );

                  final updatedSections = template.sections.map((s) {
                    if (s.id == targetSectionId) {
                      return s.copyWith(fields: [...s.fields, newField]);
                    }
                    return s;
                  }).toList();

                  _updateTemplateSections(template.copyWith(sections: updatedSections));
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
