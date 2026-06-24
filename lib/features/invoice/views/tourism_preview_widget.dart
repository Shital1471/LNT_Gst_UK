import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../models/tourism_layout_config.dart';
import '../models/invoice_template_schema.dart';

class TourismInvoicePreviewWidget extends StatelessWidget {
  final Invoice invoice;
  final List<InvoiceItem> items;
  final CompanyProfile company;
  final Map<String, dynamic> fieldValues;
  final double scale;
  final bool isDesigner;
  final String? selectedSectionId;
  final String? selectedFieldId;
  final Function(String sectionId, String? fieldId)? onTapField;
  final InvoiceTemplateSchema template;

  const TourismInvoicePreviewWidget({
    super.key,
    required this.invoice,
    required this.items,
    required this.company,
    required this.fieldValues,
    required this.template,
    this.scale = 1.0,
    this.isDesigner = false,
    this.selectedSectionId,
    this.selectedFieldId,
    this.onTapField,
  });

  @override
  Widget build(BuildContext context) {
    // Enforce layout width protection on table columns
    final adjustedTemplate = template.adjustColumnWidths();
    final layout = TourismLayoutConfig(adjustedTemplate, items.length);

    final double width = layout.pageWidth * scale;
    final double height = layout.pageHeight * scale;

    final df = DateFormat('dd/MM/yyyy');
    final simpleCurrencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);

    // Dynamic Typography Resolvers
    final headerStyle = template.typography['header'] ?? TextStyleSchema(fontSize: 12, fontWeight: 'bold', fontFamily: 'Times New Roman', textColor: '#0B3B60');
    final subheaderStyle = template.typography['subheader'] ?? TextStyleSchema(fontSize: 6.5, fontWeight: 'bold', fontFamily: 'Times New Roman', textColor: '#E57A25');
    final sectionTitleStyle = template.typography['section_title'] ?? TextStyleSchema(fontSize: 8, fontWeight: 'bold', fontFamily: 'Times New Roman', textColor: '#499F34');
    final subsectionTitleStyle = template.typography['subsection_title'] ?? TextStyleSchema(fontSize: 8, fontWeight: 'bold', fontFamily: 'Times New Roman', textColor: '#000000');
    final bodyStyle = template.typography['body'] ?? TextStyleSchema(fontSize: 7.5, fontWeight: 'normal', fontFamily: 'Times New Roman', textColor: '#000000');
    final tableHeaderStyle = template.typography['table_header'] ?? TextStyleSchema(fontSize: 7.5, fontWeight: 'bold', fontFamily: 'Times New Roman', textColor: '#FFFFFF');
    final tableDataStyle = template.typography['table_data'] ?? TextStyleSchema(fontSize: 7.5, fontWeight: 'normal', fontFamily: 'Times New Roman', textColor: '#000000');
    final footerStyle = template.typography['footer'] ?? TextStyleSchema(fontSize: 6.5, fontWeight: 'normal', fontFamily: 'Times New Roman', textColor: '#000000');

    // 1. Resolve header fields
    final companySec = adjustedTemplate.sections.firstWhere((s) => s.id == 'company_details', orElse: () => SectionSchema(id: 'company_details', title: 'Company Details', orderIndex: 0, fields: []));
    final companyFields = companySec.fields.where((f) => f.isVisible).toList();

    // 2. Resolve invoice metadata
    final invoiceSec = adjustedTemplate.sections.firstWhere((s) => s.id == 'invoice_info', orElse: () => SectionSchema(id: 'invoice_info', title: 'Invoice Details', orderIndex: 2, fields: []));
    final invoiceFields = invoiceSec.fields.where((f) => f.isVisible).toList();

    // 3. Resolve customer details
    final customerSec = adjustedTemplate.sections.firstWhere((s) => s.id == 'customer_details', orElse: () => SectionSchema(id: 'customer_details', title: 'BILL TO', orderIndex: 1, fields: []));
    final customerFields = customerSec.fields.where((f) => f.isVisible).toList();

    // 4. Resolve service details
    final serviceSec = adjustedTemplate.sections.firstWhere((s) => s.id == 'service_details', orElse: () => SectionSchema(id: 'service_details', title: 'SERVICE DETAIL 8', orderIndex: 3, fields: []));
    final serviceFields = serviceSec.fields.where((f) => f.isVisible).toList();

    // 5. Resolve table columns
    final visibleCols = adjustedTemplate.tableColumns.where((c) => c.isVisible).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    // 6. Resolve totals
    final double gstPercentage = (invoice.subTotal == 0) ? 0.0 : ((invoice.cgst + invoice.sgst) / invoice.subTotal * 100);
    final gstHalfRate = gstPercentage / 2;

    // 7. Resolve terms, bank details & signatory
    final bankSec = adjustedTemplate.sections.firstWhere((s) => s.id == 'payment_info', orElse: () => SectionSchema(id: 'payment_info', title: 'BANK DETAIL 8', orderIndex: 6, fields: []));
    final bankFields = bankSec.fields.where((f) => f.isVisible).toList();

    final termsSec = adjustedTemplate.sections.firstWhere((s) => s.id == 'terms_conditions', orElse: () => SectionSchema(id: 'terms_conditions', title: 'TERM & CONDITION 8', orderIndex: 7, fields: []));
    final termsField = termsSec.fields.firstWhere((f) => f.id == 'terms_text', orElse: () => FieldSchema(id: 'terms_text', label: 'Terms', valueType: 'text'));
    final termsString = fieldValues['terms_text'] ?? termsField.defaultValue?.toString() ?? '';
    final termsList = termsString.toString().split('\n').where((t) => t.isNotEmpty).toList();

    final sigSec = adjustedTemplate.sections.firstWhere((s) => s.id == 'signature', orElse: () => SectionSchema(id: 'signature', title: 'Authorized Signatory', orderIndex: 8, fields: []));
    final sigField = sigSec.fields.firstWhere((f) => f.id == 'signatory_title', orElse: () => FieldSchema(id: 'signatory_title', label: 'Title', valueType: 'text'));
    final signatoryTitle = fieldValues['signatory_title'] ?? sigField.defaultValue?.toString() ?? 'AUTHORISED SIGNATORY';

    // Calculate footer section horizontal positions
    final visibleFooters = adjustedTemplate.footerSections.where((f) => f.isVisible).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final double footerY = layout.footerTopLineY;
    final List<double> footerSeparators = [];
    double currentX = layout.leftMargin;

    return Center(
      child: Card(
        elevation: isDesigner ? 2 : 8,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Container(
          width: width,
          height: height,
          color: Colors.white,
          child: Stack(
            children: [
              // 1. Background borders/dividers drawn by CustomPainter
              Positioned.fill(
                child: CustomPaint(
                  painter: TourismInvoiceBackgroundPainter(
                    scale: scale,
                    layout: layout,
                    footerSeparators: footerSeparators,
                    customerFields: customerFields,
                    serviceFields: serviceFields,
                  ),
                ),
              ),

              // 2. Render Header Section (Company profile details)
              if (companySec.isVisible)
                ...companyFields.map((f) {
                  final rawVal = fieldValues[f.id] ?? f.defaultValue;
                  final textVal = (f.id == 'company_name' || f.id == 'company_tagline')
                      ? rawVal?.toString().toUpperCase() ?? ''
                      : rawVal?.toString() ?? '';

                  final isCompName = f.id == 'company_name';
                  final isTagline = f.id == 'company_tagline';
                  final style = isCompName
                      ? headerStyle
                      : (isTagline ? subheaderStyle : bodyStyle);

                  return _positionedField(
                    id: f.id,
                    sectionId: 'company_details',
                    posX: f.posX ?? 22.0,
                    posY: f.posY ?? 32.0,
                    width: f.width ?? 230.0,
                    height: f.height ?? 12.0,
                    child: Text(
                      textVal,
                      style: TextStyle(
                        fontSize: style.fontSize * scale,
                        fontWeight: style.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
                        color: _parseColor(style.textColor),
                        fontFamily: style.fontFamily,
                        letterSpacing: style.letterSpacing * scale,
                        height: style.lineHeight,
                      ),
                      maxLines: 2,
                    ),
                  );
                }).toList(),

              // Logo Image
              if (adjustedTemplate.headerConfig.logoIsVisible)
                Positioned(
                  left: layout.logoX * scale,
                  top: layout.logoY * scale,
                  width: layout.logoWidth * scale,
                  height: layout.logoHeight * scale,
                  child: company.logoPath != null && File(company.logoPath!).existsSync()
                      ? Image.file(File(company.logoPath!), fit: BoxFit.contain)
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 0.5 * scale),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'LN TOURISM',
                            style: TextStyle(fontSize: 8 * scale, fontWeight: FontWeight.bold, color: const Color(0xFF0B3B60)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),

              // Invoice title right inside green header box
              if (invoiceSec.isVisible)
                Positioned(
                  left: (layout.invBoxX + 2) * scale,
                  top: (layout.invBoxY + 4) * scale,
                  width: (layout.invBoxWidth - 4) * scale,
                  height: (layout.invBoxHeaderHeight - 4) * scale,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "INVOICE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.0 * scale,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ),
                ),

              // Invoice metadata fields
              if (invoiceSec.isVisible)
                ...invoiceFields.map((f) {
                  final rawVal = fieldValues[f.id] ?? f.defaultValue;
                  final textVal = _formatValue(rawVal, f.valueType);
                  final isBold = f.id == 'company_pan' || f.id == 'company_gst_in' || f.id == 'invoice_number';

                  return Positioned(
                    left: (layout.invBoxX + 6) * scale,
                    top: (f.posY ?? 62.0) * scale,
                    width: (layout.invBoxWidth - 12) * scale,
                    height: 10 * scale,
                    child: GestureDetector(
                      onTap: onTapField != null ? () => onTapField!('invoice_info', f.id) : null,
                      child: Container(
                        decoration: isDesigner && selectedFieldId == f.id
                            ? BoxDecoration(border: Border.all(color: AppTheme.primaryGreen), color: AppTheme.primaryGreen.withOpacity(0.06))
                            : null,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60 * scale,
                              child: Text(
                                f.label,
                                style: TextStyle(
                                  fontSize: 7.5 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0B3B60),
                                  fontFamily: 'Times New Roman',
                                ),
                              ),
                            ),
                            Text(
                              ":  $textVal",
                              style: TextStyle(
                                fontSize: 7.5 * scale,
                                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                                color: Colors.black87,
                                fontFamily: 'Times New Roman',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),

              // BILL TO Column Title
              if (customerSec.isVisible)
                _positionedField(
                  id: 'customer_details_title',
                  sectionId: 'customer_details',
                  posX: 22,
                  posY: layout.billToTopLineY + 4.0,
                  width: 100,
                  height: 12,
                  child: Text(
                    customerSec.title,
                    style: TextStyle(
                      fontSize: sectionTitleStyle.fontSize * scale,
                      fontWeight: sectionTitleStyle.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
                      color: _parseColor(sectionTitleStyle.textColor),
                      fontFamily: sectionTitleStyle.fontFamily,
                    ),
                  ),
                ),

              // BILL TO Fields
              if (customerSec.isVisible)
                ...customerFields.map((f) {
                  final rawVal = fieldValues[f.id] ?? f.defaultValue;
                  final textVal = _formatValue(rawVal, f.valueType);
                  return _dottedFieldRow(f.label, textVal, f.posY ?? 172.0, f.id, 'customer_details', style: subsectionTitleStyle);
                }).toList(),

              // SERVICE DETAIL Title
              if (serviceSec.isVisible)
                _positionedField(
                  id: 'service_details_title',
                  sectionId: 'service_details',
                  posX: layout.serviceColumnUnderlineX1,
                  posY: layout.billToTopLineY + 4.0,
                  width: 150,
                  height: 12,
                  child: Text(
                    serviceSec.title,
                    style: TextStyle(
                      fontSize: sectionTitleStyle.fontSize * scale,
                      fontWeight: sectionTitleStyle.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
                      color: _parseColor(sectionTitleStyle.textColor),
                      fontFamily: sectionTitleStyle.fontFamily,
                    ),
                  ),
                ),

              // SERVICE DETAIL Fields
              if (serviceSec.isVisible)
                ...serviceFields.map((f) {
                  final rawVal = fieldValues[f.id] ?? f.defaultValue;
                  final textVal = _formatValue(rawVal, f.valueType);
                  return _dottedFieldRow(f.label, textVal, f.posY ?? 172.0, f.id, 'service_details', isRightCol: true, style: subsectionTitleStyle, layout: layout);
                }).toList(),

              // 3. Service Table
              if (adjustedTemplate.sections.firstWhere((s) => s.id == 'items_table', orElse: () => SectionSchema(id: 'items_table', title: 'Items', orderIndex: 4, fields: [])).isVisible)
                Positioned(
                  left: layout.leftMargin * scale,
                  top: layout.tableStartY * scale,
                  width: layout.contentWidth * scale,
                  child: Table(
                    border: TableBorder.all(color: Colors.black, width: 0.8 * scale),
                    columnWidths: Map.fromIterables(
                      Iterable<int>.generate(visibleCols.length),
                      visibleCols.map((c) => FixedColumnWidth(c.width * scale)),
                    ),
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFF499F34)),
                        children: visibleCols.map((col) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4 * scale, horizontal: 1 * scale),
                          child: Text(
                            col.label,
                            style: TextStyle(
                              color: _parseColor(tableHeaderStyle.textColor),
                              fontWeight: tableHeaderStyle.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
                              fontSize: tableHeaderStyle.fontSize * scale,
                              fontFamily: tableHeaderStyle.fontFamily,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )).toList(),
                      ),
                      ...List.generate(items.length, (idx) {
                        final item = items[idx];
                        
                        String itemDesc = item.description;
                        Map<String, String> itemCustomValues = {};
                        try {
                          final decoded = jsonDecode(item.description) as Map<String, dynamic>;
                          if (decoded.containsKey('description')) {
                            itemDesc = decoded['description']?.toString() ?? '';
                            final custom = decoded['customValues'] as Map<String, dynamic>?;
                            if (custom != null) {
                              custom.forEach((k, v) {
                                itemCustomValues[k] = v.toString();
                              });
                            }
                          }
                        } catch (_) {}

                        return TableRow(
                          children: visibleCols.map((col) {
                            String cellText = '';
                            TextAlign cellAlign = TextAlign.left;

                            if (col.id == 's_no') {
                              cellText = (idx + 1).toString();
                              cellAlign = TextAlign.center;
                            } else if (col.id == 'description') {
                              cellText = itemDesc;
                              cellAlign = TextAlign.left;
                            } else if (col.id == 'no_of_vehicles') {
                              cellText = item.noOfVehicles?.toString() ?? '1';
                              cellAlign = TextAlign.center;
                            } else if (col.id == 'date') {
                              cellText = item.itemDate != null ? df.format(item.itemDate!) : '';
                              cellAlign = TextAlign.center;
                            } else if (col.id == 'from_to') {
                              cellText = item.fromTo ?? '';
                              cellAlign = TextAlign.left;
                            } else if (col.id == 'qty') {
                              cellText = item.quantityDays.toStringAsFixed(item.quantityDays % 1 == 0 ? 0 : 1);
                              cellAlign = TextAlign.center;
                            } else if (col.id == 'rate') {
                              cellText = simpleCurrencyFmt.format(item.rate);
                              cellAlign = TextAlign.right;
                            } else if (col.id == 'amount') {
                              cellText = simpleCurrencyFmt.format(item.amount);
                              cellAlign = TextAlign.right;
                            } else {
                              // Custom table columns support
                              cellText = itemCustomValues[col.id] ?? '';
                              cellAlign = col.alignment == 'right'
                                  ? TextAlign.right
                                  : (col.alignment == 'center' ? TextAlign.center : TextAlign.left);
                            }

                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 3.5 * scale),
                              child: Text(
                                cellText,
                                style: TextStyle(
                                  fontSize: tableDataStyle.fontSize * scale,
                                  fontWeight: tableDataStyle.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
                                  color: _parseColor(tableDataStyle.textColor),
                                  fontFamily: tableDataStyle.fontFamily,
                                ),
                                textAlign: cellAlign,
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                ),

              // 4. Totals Block (Right side)
              if (adjustedTemplate.sections.firstWhere((s) => s.id == 'tax_summary', orElse: () => SectionSchema(id: 'tax_summary', title: 'Totals', orderIndex: 5, fields: [])).isVisible) ...[
                _totalsRow("Sub Total", simpleCurrencyFmt.format(invoice.subTotal), 0, 'tax_summary', layout, style: tableDataStyle),
                _totalsRow("CGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%", simpleCurrencyFmt.format(invoice.cgst), 1, 'tax_summary', layout, style: tableDataStyle),
                _totalsRow("SGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%", simpleCurrencyFmt.format(invoice.sgst), 2, 'tax_summary', layout, style: tableDataStyle),
                _totalsRow("Total Amount", simpleCurrencyFmt.format(invoice.grandTotal), 3, 'tax_summary', layout, isTotalAmount: true, style: tableDataStyle),
                _totalsRow("Advance Payment Received", simpleCurrencyFmt.format(invoice.advancePaid), 4, 'tax_summary', layout, style: tableDataStyle),
                _totalsRow("Amount To Be Paid", simpleCurrencyFmt.format(invoice.grandTotal - invoice.advancePaid), 5, 'tax_summary', layout, isBold: true, style: tableDataStyle),

                // Amount in words box (Left side, full width)
                _positionedField(
                  id: 'amount_paid_in_words',
                  sectionId: 'tax_summary',
                  posX: layout.wordsBoxX,
                  posY: layout.wordsBoxY,
                  width: layout.wordsBoxWidth,
                  height: layout.wordsBoxHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 4 * scale),
                    child: Text(
                      "Amount to be paid in words : ${invoice.amountPaidInWords.endsWith(' Only') ? '${invoice.amountPaidInWords}.' : (invoice.amountPaidInWords.endsWith(' Only.') ? invoice.amountPaidInWords : '${invoice.amountPaidInWords} Only.')}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: bodyStyle.fontSize * scale,
                        fontFamily: bodyStyle.fontFamily,
                        color: _parseColor(bodyStyle.textColor),
                      ),
                    ),
                  ),
                ),
              ],

              // 5. Dynamic Footer Sections Horizontal Layout
              ...List.generate(visibleFooters.length, (index) {
                final footerSec = visibleFooters[index];
                final widthPct = footerSec.widthPercent;
                final colWidth = layout.contentWidth * (widthPct / 100);
                final cellLeft = currentX;

                // Add dividers dynamically to background painter coordinates
                if (index > 0) {
                  footerSeparators.add(cellLeft);
                }

                currentX += colWidth;

                Widget footerWidget;
                if (footerSec.id == 'terms_conditions') {
                  footerWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        footerSec.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: sectionTitleStyle.fontSize * scale,
                          fontWeight: sectionTitleStyle.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
                          color: _parseColor(sectionTitleStyle.textColor),
                          fontFamily: sectionTitleStyle.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          children: termsList.map((t) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 0.5 * scale),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: footerStyle.fontSize * scale,
                                fontFamily: footerStyle.fontFamily,
                                color: _parseColor(footerStyle.textColor),
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  );
                } else if (footerSec.id == 'bank_details') {
                  footerWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        footerSec.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: sectionTitleStyle.fontSize * scale,
                          fontWeight: sectionTitleStyle.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
                          color: _parseColor(sectionTitleStyle.textColor),
                          fontFamily: sectionTitleStyle.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ...bankFields.map((bf) {
                        final val = fieldValues[bf.id] ?? bf.defaultValue ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50 * scale,
                                child: Text(
                                  "${bf.label}:",
                                  style: TextStyle(
                                    fontSize: footerStyle.fontSize * scale,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: footerStyle.fontFamily,
                                    color: _parseColor(footerStyle.textColor),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  val.toString(),
                                  style: TextStyle(
                                    fontSize: footerStyle.fontSize * scale,
                                    fontFamily: footerStyle.fontFamily,
                                    color: _parseColor(footerStyle.textColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                } else {
                  // Signature Block
                  footerWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "FOR ${company.name.toUpperCase()}",
                        style: TextStyle(
                          fontSize: footerStyle.fontSize * scale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B3B60),
                          fontFamily: footerStyle.fontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "This is a computer-generated invoice.\nSubject to applicable laws.",
                        style: TextStyle(fontSize: 5.0 * scale, color: Colors.grey.shade600, fontFamily: 'Times New Roman'),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      // Signature Image
                      if (company.signaturePath != null && File(company.signaturePath!).existsSync())
                        Image.file(File(company.signaturePath!), height: 25 * scale, fit: BoxFit.contain)
                      else
                        Text(
                          "Abhishek Prajapati",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontFamily: 'Times New Roman',
                          ),
                        ),
                      const Divider(height: 4, color: Colors.grey),
                      Text(
                        signatoryTitle.toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: footerStyle.fontSize * scale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B3B60),
                          fontFamily: footerStyle.fontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }

                return _positionedField(
                  id: footerSec.id,
                  sectionId: footerSec.id,
                  posX: cellLeft,
                  posY: footerY + 8,
                  width: colWidth - 8.0,
                  height: layout.footerHeight - 16.0,
                  child: footerWidget,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _positionedField({
    required String id,
    required String sectionId,
    required double posX,
    required double posY,
    required double width,
    required double height,
    required Widget child,
  }) {
    final isSelected = isDesigner && selectedFieldId == id;
    final isSecSelected = isDesigner && selectedSectionId == sectionId && selectedFieldId == null;

    return Positioned(
      left: posX * scale,
      top: posY * scale,
      width: width * scale,
      height: height * scale,
      child: GestureDetector(
        onTap: onTapField != null ? () => onTapField!(sectionId, id) : null,
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: AppTheme.primaryGreen, width: 1.0)
                : (isSecSelected
                    ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.5), width: 0.8)
                    : null),
            color: isSelected
                ? AppTheme.primaryGreen.withOpacity(0.06)
                : (isSecSelected
                    ? AppTheme.primaryGreen.withOpacity(0.02)
                    : null),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _dottedFieldRow(String label, String value, double posY, String id, String sectionId, {bool isRightCol = false, required TextStyleSchema style, TourismLayoutConfig? layout}) {
    final double left = isRightCol ? (layout?.serviceColumnUnderlineX1 ?? 300) : 22;
    final double width = isRightCol
        ? ((layout?.serviceColumnUnderlineX2 ?? 573.27) - left)
        : ((layout?.billToColumnUnderlineX2 ?? 285) - left);

    return Positioned(
      left: left * scale,
      top: posY * scale,
      width: width * scale,
      height: 12 * scale,
      child: GestureDetector(
        onTap: onTapField != null ? () => onTapField!(sectionId, id) : null,
        child: Container(
          decoration: isDesigner && selectedFieldId == id
              ? BoxDecoration(border: Border.all(color: AppTheme.primaryGreen), color: AppTheme.primaryGreen.withOpacity(0.06))
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: (isRightCol ? 90 : 75) * scale,
                child: Text(
                  "$label :",
                  style: TextStyle(
                    fontSize: style.fontSize * scale,
                    fontWeight: FontWeight.bold,
                    color: _parseColor(style.textColor),
                    fontFamily: style.fontFamily,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: style.fontSize * scale,
                    fontFamily: style.fontFamily,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalsRow(String label, String value, int rowIndex, String sectionId, TourismLayoutConfig layout, {bool isBold = false, bool isTotalAmount = false, required TextStyleSchema style}) {
    final double top = layout.totalsBoxY + (rowIndex * layout.totalsRowHeight);

    return Positioned(
      left: layout.totalsBoxX * scale,
      top: top * scale,
      width: layout.totalsBoxWidth * scale,
      height: layout.totalsRowHeight * scale,
      child: Container(
        color: isTotalAmount ? Colors.black : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 3 * scale),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: style.fontSize * scale,
                fontWeight: (isBold || isTotalAmount) ? FontWeight.bold : FontWeight.normal,
                color: isTotalAmount ? Colors.white : _parseColor(style.textColor),
                fontFamily: style.fontFamily,
              ),
            ),
            Text(
              "Rs. $value",
              style: TextStyle(
                fontSize: style.fontSize * scale,
                fontWeight: (isBold || isTotalAmount) ? FontWeight.bold : FontWeight.normal,
                color: isTotalAmount ? Colors.white : _parseColor(style.textColor),
                fontFamily: style.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatValue(dynamic val, String type) {
    if (val == null) return '';
    if (val is DateTime) {
      return DateFormat('dd/MM/yyyy').format(val);
    }
    final strVal = val.toString();
    if (type == 'date') {
      final parsed = DateTime.tryParse(strVal);
      if (parsed != null) return DateFormat('dd/MM/yyyy').format(parsed);
    }
    return strVal;
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

class TourismInvoiceBackgroundPainter extends CustomPainter {
  final double scale;
  final TourismLayoutConfig layout;
  final List<double> footerSeparators;
  final List<FieldSchema> customerFields;
  final List<FieldSchema> serviceFields;

  TourismInvoiceBackgroundPainter({
    required this.scale,
    required this.layout,
    required this.footerSeparators,
    required this.customerFields,
    required this.serviceFields,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 0.5 * scale
      ..style = PaintingStyle.stroke;

    final solidGreen = Paint()
      ..color = const Color(0xFF499F34)
      ..strokeWidth = 1.0 * scale
      ..style = PaintingStyle.stroke;

    final solidBlack = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.8 * scale
      ..style = PaintingStyle.stroke;

    void drawDashLine(double x1, double y1, double x2, double y2, Paint paint) {
      const double dashWidth = 3.0;
      const double dashSpace = 2.0;
      double dx = x2 - x1;
      if (dx != 0) {
        double currentX = x1;
        while (currentX < x2) {
          canvas.drawLine(
            Offset(currentX, y1),
            Offset(currentX + dashWidth * scale > x2 ? x2 : currentX + dashWidth * scale, y1),
            paint,
          );
          currentX += (dashWidth + dashSpace) * scale;
        }
      } else {
        double currentY = y1;
        while (currentY < y2) {
          canvas.drawLine(
            Offset(x1, currentY),
            Offset(x1, currentY + dashWidth * scale > y2 ? y2 : currentY + dashWidth * scale),
            paint,
          );
          currentY += (dashWidth + dashSpace) * scale;
        }
      }
    }

    // 1. Header borders
    drawDashLine(
      layout.leftMargin * scale,
      layout.headerTopLineY * scale,
      (layout.pageWidth - layout.rightMargin) * scale,
      layout.headerTopLineY * scale,
      dashPaint,
    );
    drawDashLine(
      layout.leftMargin * scale,
      layout.headerBottomLineY * scale,
      (layout.pageWidth - layout.rightMargin) * scale,
      layout.headerBottomLineY * scale,
      dashPaint,
    );

    // Green Divider
    canvas.drawLine(
      Offset(layout.headerDividerX * scale, layout.headerTopLineY * scale),
      Offset(layout.headerDividerX * scale, layout.headerBottomLineY * scale),
      solidGreen..strokeWidth = 1.2 * scale,
    );

    // Invoice Box green border
    final Rect invBoxRect = Rect.fromLTWH(
      layout.invBoxX * scale,
      layout.invBoxY * scale,
      layout.invBoxWidth * scale,
      layout.invBoxHeight * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(invBoxRect, Radius.circular(3 * scale)),
      solidGreen..strokeWidth = 1.0 * scale,
    );

    // Invoice Header background fill
    final fillPaint = Paint()
      ..color = const Color(0xFF499F34)
      ..style = PaintingStyle.fill;
    final Rect invHeaderRect = Rect.fromLTWH(
      layout.invBoxX * scale,
      layout.invBoxY * scale,
      layout.invBoxWidth * scale,
      layout.invBoxHeaderHeight * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        invHeaderRect,
        topLeft: Radius.circular(3 * scale),
        topRight: Radius.circular(3 * scale),
      ),
      fillPaint,
    );

    // 2. Bill To & Service details
    drawDashLine(
      layout.leftMargin * scale,
      layout.billToTopLineY * scale,
      (layout.pageWidth - layout.rightMargin) * scale,
      layout.billToTopLineY * scale,
      solidBlack,
    );
    drawDashLine(
      layout.leftMargin * scale,
      layout.billToBottomLineY * scale,
      (layout.pageWidth - layout.rightMargin) * scale,
      layout.billToBottomLineY * scale,
      solidBlack,
    );

    // Column titles underline
    canvas.drawLine(
      Offset(layout.billToColumnUnderlineX1 * scale, layout.billToColumnUnderlineY * scale),
      Offset(layout.billToColumnUnderlineX2 * scale, layout.billToColumnUnderlineY * scale),
      solidBlack..strokeWidth = 1.0 * scale,
    );
    canvas.drawLine(
      Offset(layout.serviceColumnUnderlineX1 * scale, layout.serviceColumnUnderlineY * scale),
      Offset(layout.serviceColumnUnderlineX2 * scale, layout.serviceColumnUnderlineY * scale),
      solidBlack..strokeWidth = 1.0 * scale,
    );

    // Dotted separators below fields
    for (final f in customerFields) {
      if (f.id != 'customer_phone') { // don't draw underline under last field
        final double underlineY = f.posY != null ? (f.posY! + (f.height ?? 10.0)) : 0.0;
        drawDashLine(
          layout.billToColumnUnderlineX1 * scale,
          underlineY * scale,
          layout.billToColumnUnderlineX2 * scale,
          underlineY * scale,
          dashPaint,
        );
      }
    }

    for (final f in serviceFields) {
      if (f.id != 'coordinator_name') {
        final double underlineY = f.posY != null ? (f.posY! + (f.height ?? 10.0)) : 0.0;
        drawDashLine(
          layout.serviceColumnUnderlineX1 * scale,
          underlineY * scale,
          layout.serviceColumnUnderlineX2 * scale,
          underlineY * scale,
          dashPaint,
        );
      }
    }

    // 3. Totals Box dashed borders
    final Rect totalsRect = Rect.fromLTWH(
      layout.totalsBoxX * scale,
      layout.totalsBoxY * scale,
      layout.totalsBoxWidth * scale,
      layout.totalsBoxHeight * scale,
    );
    canvas.drawRect(totalsRect, solidBlack);

    // Totals internal vertical line
    canvas.drawLine(
      Offset(layout.totalsBoxDividerX * scale, layout.totalsBoxY * scale),
      Offset(layout.totalsBoxDividerX * scale, (layout.totalsBoxY + layout.totalsBoxHeight) * scale),
      dashPaint,
    );

    // Totals internal horizontal dividers
    for (int i = 1; i < 6; i++) {
      final double y = layout.totalsBoxY + (i * layout.totalsRowHeight);
      canvas.drawLine(
        Offset(layout.totalsBoxX * scale, y * scale),
        Offset((layout.totalsBoxX + layout.totalsBoxWidth) * scale, y * scale),
        dashPaint,
      );
    }

    // Words box border
    final Rect wordsRect = Rect.fromLTWH(
      layout.wordsBoxX * scale,
      layout.wordsBoxY * scale,
      layout.wordsBoxWidth * scale,
      layout.wordsBoxHeight * scale,
    );
    canvas.drawRect(wordsRect, solidBlack);

    // 4. Footer Borders
    drawDashLine(
      layout.leftMargin * scale,
      layout.footerTopLineY * scale,
      (layout.pageWidth - layout.rightMargin) * scale,
      layout.footerTopLineY * scale,
      solidBlack,
    );
    drawDashLine(
      layout.leftMargin * scale,
      layout.footerBottomLineY * scale,
      (layout.pageWidth - layout.rightMargin) * scale,
      layout.footerBottomLineY * scale,
      solidBlack,
    );

    // Green Separators inside Footer
    for (final sepX in footerSeparators) {
      canvas.drawLine(
        Offset(sepX * scale, layout.footerTopLineY * scale),
        Offset(sepX * scale, layout.footerBottomLineY * scale),
        solidGreen..strokeWidth = 1.0 * scale,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TourismInvoiceBackgroundPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.layout.tableHeight != layout.tableHeight ||
        oldDelegate.footerSeparators.length != footerSeparators.length;
  }
}
