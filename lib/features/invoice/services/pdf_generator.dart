import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../models/invoice_template_schema.dart';
import '../models/tourism_layout_config.dart';

class PdfGeneratorService {
  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required CompanyProfile company,
  }) async {
    final pdf = pw.Document();

    final df = DateFormat('dd/MM/yyyy');
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs. ',
      decimalDigits: 2,
    );
    final simpleCurrencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 2,
    );

    // 1. Determine active template schema configuration
    InvoiceTemplateSchema template;
    if (invoice.templateSchemaJson != null &&
        invoice.templateSchemaJson!.isNotEmpty) {
      template = InvoiceTemplateSchema.fromJson(
        jsonDecode(invoice.templateSchemaJson!),
      );
    } else {
      template = InvoiceTemplateSchema.getPreset(invoice.templateType);
    }

    // Apply layout width protection to prevent boundaries overflow
    final adjustedTemplate = template.adjustColumnWidths();

    // 2. Parse dynamic field values map
    Map<String, dynamic> fieldValues = {};
    if (invoice.fieldValuesJson != null &&
        invoice.fieldValuesJson!.isNotEmpty) {
      try {
        fieldValues = jsonDecode(invoice.fieldValuesJson!);
      } catch (_) {}
    } else {
      // Fallback
      fieldValues = {
        'invoice_number': invoice.invoiceNumber,
        'invoice_date': invoice.invoiceDate.toIso8601String(),
        'due_date': invoice.dueDate.toIso8601String(),
        'booking_ref': invoice.bookingRef ?? '',
        'booking_date': invoice.bookingDate?.toIso8601String(),
        'customer_name': invoice.customerName,
        'customer_address': invoice.customerAddress,
        'customer_gst': invoice.customerGstNumber ?? '',
        'customer_phone': invoice.customerContactNumber ?? '',
        'tour_trip': invoice.tourTrip ?? '',
        'travel_date': invoice.travelDate?.toIso8601String(),
        'no_of_days': invoice.noOfDays,
        'no_of_vehicles': invoice.noOfVehicles,
        'coordinator_name': invoice.coordinatorName ?? '',
      };
    }

    fieldValues['company_name'] = company.name;
    fieldValues['company_address'] = company.address;
    fieldValues['company_gst'] = company.gstNumber;
    fieldValues['company_phone'] = company.contactNumber;
    fieldValues['company_email'] = company.email;
    fieldValues['company_website'] = 'www.lntourism.com';

    // 3. Determine Page dimensions
    PdfPageFormat pageFormat = PdfPageFormat.a4;
    if (adjustedTemplate.pageFormat == 'Letter') {
      pageFormat = PdfPageFormat.letter;
    } else if (adjustedTemplate.pageFormat == 'Custom') {
      pageFormat = PdfPageFormat(
        adjustedTemplate.pageWidth,
        adjustedTemplate.pageHeight,
      );
    }

    double scale = 1.0;

    // 4. Load branding logo and signature images if available
    pw.ImageProvider? logoImage;
    pw.ImageProvider? sigImage;

    if (company.logoPath != null && company.logoPath!.isNotEmpty) {
      try {
        final file = File(company.logoPath!);
        if (await file.exists()) {
          logoImage = pw.MemoryImage(await file.readAsBytes());
        }
      } catch (_) {}
    }

    final String signatureType =
        fieldValues['signature_type']?.toString() ?? 'company';
    final String? signatureImagePath = fieldValues['signature_image_path']
        ?.toString();

    if (signatureType == 'upload' &&
        signatureImagePath != null &&
        signatureImagePath.isNotEmpty) {
      try {
        final file = File(signatureImagePath);
        if (await file.exists()) {
          sigImage = pw.MemoryImage(await file.readAsBytes());
        }
      } catch (_) {}
    } else if (signatureType == 'company') {
      if (company.signaturePath != null && company.signaturePath!.isNotEmpty) {
        try {
          final file = File(company.signaturePath!);
          if (await file.exists()) {
            sigImage = pw.MemoryImage(await file.readAsBytes());
          }
        } catch (_) {}
      }
    }

    // 5. Build sections in sorted layout sequence
    final visibleSections =
        adjustedTemplate.sections.where((s) => s.isVisible).toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final isTourism = adjustedTemplate.id == 'tourism';
    final pageTheme = isTourism
        ? pw.ThemeData.withFont(
            base: pw.Font.times(),
            bold: pw.Font.timesBold(),
            italic: pw.Font.timesItalic(),
            boldItalic: pw.Font.timesBoldItalic(),
          )
        : null;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: pageTheme,
        margin: isTourism
            ? pw.EdgeInsets.zero
            : pw.EdgeInsets.only(
                top: adjustedTemplate.marginTop * scale,
                bottom: adjustedTemplate.marginBottom * scale,
                left: adjustedTemplate.marginLeft * scale,
                right: adjustedTemplate.marginRight * scale,
              ),
        build: (pw.Context context) {
          if (isTourism) {
            return _buildTourismLayout(
              template: adjustedTemplate,
              invoice: invoice,
              items: items,
              company: company,
              logoImage: logoImage,
              sigImage: sigImage,
              scale: scale,
              df: df,
              simpleCurrencyFmt: simpleCurrencyFmt,
              currencyFmt: currencyFmt,
              fieldValues: fieldValues,
            );
          }

          pw.Widget _buildSection(SectionSchema sec) {
            if (sec.id == 'company_details') {
              return _buildCompanyDetailsHeader(
                adjustedTemplate,
                sec,
                logoImage,
                invoice,
                company,
                scale,
                df,
              );
            } else if (sec.id == 'customer_details') {
              return _buildCustomerDetailsBlock(
                adjustedTemplate,
                sec,
                fieldValues,
                scale,
              );
            } else if (sec.id == 'invoice_info') {
              return _buildInvoiceMetaGrid(
                adjustedTemplate,
                sec,
                fieldValues,
                scale,
                df,
              );
            } else if (sec.id == 'items_table') {
              return _buildDynamicItemsTable(
                adjustedTemplate,
                items,
                scale,
                df,
                simpleCurrencyFmt,
              );
            } else if (sec.id == 'tax_summary') {
              return _buildTaxSummaryBlock(
                adjustedTemplate,
                invoice,
                scale,
                simpleCurrencyFmt,
                currencyFmt,
              );
            } else if (sec.id == 'payment_info') {
              return _buildPaymentInfoBlock(
                adjustedTemplate,
                sec,
                company,
                invoice,
                scale,
                simpleCurrencyFmt,
                currencyFmt,
              );
            } else if (sec.id == 'terms_conditions') {
              return _buildTermsConditionsBlock(adjustedTemplate, sec, scale);
            } else if (sec.id == 'signature') {
              return _buildSignatureBlock(
                adjustedTemplate,
                sec,
                company,
                sigImage,
                scale,
                invoice,
              );
            }
            return pw.SizedBox();
          }

          // Dynamic rendering using spacing gap properties
          final children = <pw.Widget>[];
          for (int i = 0; i < visibleSections.length; i++) {
            if (i > 0) {
              children.add(
                pw.SizedBox(height: adjustedTemplate.sectionGap * scale),
              );
            }
            children.add(_buildSection(visibleSections[i]));
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: children,
          );
        },
      ),
    );

    return await pdf.save();
  }

  // --- Dynamic Tourism Absolute Layout ---
  static pw.Widget _buildTourismLayout({
    required InvoiceTemplateSchema template,
    required Invoice invoice,
    required List<InvoiceItem> items,
    required CompanyProfile company,
    required pw.ImageProvider? logoImage,
    required pw.ImageProvider? sigImage,
    required double scale,
    required DateFormat df,
    required NumberFormat simpleCurrencyFmt,
    required NumberFormat currencyFmt,
    required Map<String, dynamic> fieldValues,
  }) {
    final layout = TourismLayoutConfig(template, items.length, fieldValues);

    final companySec = template.sections.firstWhere(
      (s) => s.id == 'company_details',
      orElse: () => SectionSchema(
        id: 'company_details',
        title: 'Company Details',
        orderIndex: 0,
        fields: [],
      ),
    );
    final companyFields = companySec.fields.where((f) => f.isVisible).toList();

    final invoiceSec = template.sections.firstWhere(
      (s) => s.id == 'invoice_info',
      orElse: () => SectionSchema(
        id: 'invoice_info',
        title: 'Invoice Details',
        orderIndex: 2,
        fields: [],
      ),
    );
    final invoiceFields = invoiceSec.fields.where((f) => f.isVisible).toList();

    final customerSec = template.sections.firstWhere(
      (s) => s.id == 'customer_details',
      orElse: () => SectionSchema(
        id: 'customer_details',
        title: 'BILL TO',
        orderIndex: 1,
        fields: [],
      ),
    );
    final customerFields = customerSec.fields
        .where((f) => f.isVisible)
        .toList();

    final serviceSec = template.sections.firstWhere(
      (s) => s.id == 'service_details',
      orElse: () => SectionSchema(
        id: 'service_details',
        title: 'SERVICE DETAIL 8',
        orderIndex: 3,
        fields: [],
      ),
    );
    final serviceFields = serviceSec.fields.where((f) => f.isVisible).toList();

    final bankSec = template.sections.firstWhere(
      (s) => s.id == 'payment_info',
      orElse: () => SectionSchema(
        id: 'payment_info',
        title: 'BANK DETAIL 8',
        orderIndex: 6,
        fields: [],
      ),
    );
    final bankFields = bankSec.fields.where((f) => f.isVisible).toList();

    final visibleCols = template.tableColumns.where((c) => c.isVisible).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final cName = (fieldValues['company_name'] ?? company.name)
        .toString()
        .toUpperCase();
    // Unused variables removed for analyzer cleanliness

    final termsSec = template.sections.firstWhere(
      (s) => s.id == 'terms_conditions',
      orElse: () => SectionSchema(
        id: 'terms_conditions',
        title: 'TERM & CONDITION 8',
        orderIndex: 7,
        fields: [],
      ),
    );
    final termsField = termsSec.fields.firstWhere(
      (f) => f.id == 'terms_text',
      orElse: () =>
          FieldSchema(id: 'terms_text', label: 'Terms', valueType: 'text'),
    );
    final termsString =
        fieldValues['terms_text'] ?? termsField.defaultValue?.toString() ?? '';
    final termsList = termsString
        .toString()
        .split('\n')
        .where((t) => t.isNotEmpty)
        .toList();

    final sigSec = template.sections.firstWhere(
      (s) => s.id == 'signature',
      orElse: () => SectionSchema(
        id: 'signature',
        title: 'Authorized Signatory',
        orderIndex: 8,
        fields: [],
      ),
    );
    final sigField = sigSec.fields.firstWhere(
      (f) => f.id == 'signatory_title',
      orElse: () =>
          FieldSchema(id: 'signatory_title', label: 'Title', valueType: 'text'),
    );
    final signatoryTitle =
        fieldValues['signatory_title'] ??
        sigField.defaultValue?.toString() ??
        'AUTHORISED SIGNATORY';

    final double gstPercentage = (invoice.subTotal == 0)
        ? 0.0
        : ((invoice.cgst + invoice.sgst) / invoice.subTotal * 100);
    final gstHalfRate = gstPercentage / 2;

    // Layout values
    final double tableEndY = layout.tableEndY;
    final double totalsBoxY = layout.totalsBoxY;
    final double wordsBoxY = layout.wordsBoxY;
    final double footerTopLineY = layout.footerTopLineY;
    final double footerBottomLineY = layout.footerBottomLineY;
    final double sigBoxY = layout.sigBoxY;
    final double sigUnderlineY = layout.sigUnderlineY;
    final double signatoryTitleY = layout.signatoryTitleY;

    // Fetch typography
    final headerStyle =
        template.typography['header'] ??
        TextStyleSchema(
          fontSize: 12,
          fontWeight: 'bold',
          fontFamily: 'Times New Roman',
          textColor: '#0B3B60',
        );
    final subheaderStyle =
        template.typography['subheader'] ??
        TextStyleSchema(
          fontSize: 6.5,
          fontWeight: 'bold',
          fontFamily: 'Times New Roman',
          textColor: '#E57A25',
        );
    final sectionTitleStyle =
        template.typography['section_title'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'bold',
          fontFamily: 'Times New Roman',
          textColor: '#499F34',
        );
    final subsectionTitleStyle =
        template.typography['subsection_title'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'bold',
          fontFamily: 'Times New Roman',
          textColor: '#000000',
        );
    final bodyStyle =
        template.typography['body'] ??
        TextStyleSchema(
          fontSize: 7.5,
          fontWeight: 'normal',
          fontFamily: 'Times New Roman',
          textColor: '#000000',
        );
    final tableHeaderStyle =
        template.typography['table_header'] ??
        TextStyleSchema(
          fontSize: 7.5,
          fontWeight: 'bold',
          fontFamily: 'Times New Roman',
          textColor: '#FFFFFF',
        );
    final tableDataStyle =
        template.typography['table_data'] ??
        TextStyleSchema(
          fontSize: 7.5,
          fontWeight: 'normal',
          fontFamily: 'Times New Roman',
          textColor: '#000000',
        );
    final footerStyle =
        template.typography['footer'] ??
        TextStyleSchema(
          fontSize: 6.5,
          fontWeight: 'normal',
          fontFamily: 'Times New Roman',
          textColor: '#000000',
        );

    pw.Widget _positionedField({
      required double posX,
      required double posY,
      required double width,
      required double height,
      required pw.Widget child,
    }) {
      return pw.Positioned(
        left: posX * scale,
        top: posY * scale,
        child: pw.SizedBox(
          width: width * scale,
          height: height * scale,
          child: child,
        ),
      );
    }

    pw.Widget _invoiceInfoRow(
      String label,
      String value,
      double posY, {
      bool isBold = false,
    }) {
      return pw.Positioned(
        left: (layout.invBoxX + 6) * scale,
        top: posY * scale,
        child: pw.SizedBox(
          width: (layout.invBoxWidth - 12) * scale,
          height: 10 * scale,
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 60 * scale,
                child: pw.Text(
                  label,
                  style: pw.TextStyle(
                    fontSize: 7.5 * scale,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF0B3B60),
                  ),
                ),
              ),
              pw.Text(
                ":  $value",
                style: pw.TextStyle(
                  fontSize: 7.5 * scale,
                  fontWeight: isBold
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget _dottedFieldRow(
      String label,
      String value,
      double posX,
      double posY,
      double width,
      double height,
    ) {
      return pw.Positioned(
        left: posX * scale,
        top: posY * scale,
        child: pw.SizedBox(
          width: width * scale,
          height: height * scale,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                width: 75 * scale,
                child: pw.Text(
                  "$label :",
                  style: _getPdfStyle(
                    subsectionTitleStyle,
                    scale,
                    forceBold: true,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(value, style: _getPdfStyle(bodyStyle, scale)),
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget _totalsRow(
      String label,
      String value,
      int rowIndex, {
      bool isBold = false,
      bool isTotalAmount = false,
    }) {
      final double top = totalsBoxY + (rowIndex * layout.totalsRowHeight);

      return pw.Positioned(
        left: layout.totalsBoxX * scale,
        top: top * scale,
        child: pw.Container(
          width: layout.totalsBoxWidth * scale,
          height: layout.totalsRowHeight * scale,
          color: isTotalAmount ? PdfColors.black : null,
          padding: pw.EdgeInsets.symmetric(
            horizontal: 6 * scale,
            vertical: 3 * scale,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: tableDataStyle.fontSize * scale,
                  font: (isBold || isTotalAmount)
                      ? _getFontBold(tableDataStyle.fontFamily)
                      : _getFont(tableDataStyle.fontFamily),
                  color: isTotalAmount
                      ? PdfColors.white
                      : _parseColor(tableDataStyle.textColor),
                ),
              ),
              pw.Text(
                "Rs. $value",
                style: pw.TextStyle(
                  fontSize: tableDataStyle.fontSize * scale,
                  font: (isBold || isTotalAmount)
                      ? _getFontBold(tableDataStyle.fontFamily)
                      : _getFont(tableDataStyle.fontFamily),
                  color: isTotalAmount
                      ? PdfColors.white
                      : _parseColor(tableDataStyle.textColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget _bankItemRow(String label, String value, double posY) {
      return pw.Positioned(
        left: 218 * scale,
        top: posY * scale,
        child: pw.SizedBox(
          width: 155 * scale,
          height: 10 * scale,
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 62 * scale,
                child: pw.Text(
                  "$label:",
                  style: pw.TextStyle(
                    fontSize: footerStyle.fontSize * scale,
                    fontWeight: pw.FontWeight.bold,
                    font: _getFontBold(footerStyle.fontFamily),
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(value, style: _getPdfStyle(footerStyle, scale)),
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget _cellBody(String text, {pw.TextAlign align = pw.TextAlign.left}) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(
          horizontal: 4 * scale,
          vertical: 3.5 * scale,
        ),
        child: pw.Text(
          text,
          style: _getPdfStyle(tableDataStyle, scale),
          textAlign: align,
        ),
      );
    }

    // List of Positioned background lines
    final List<pw.Widget> decorativeLines = [
      // Top header dashed line
      pw.Positioned(
        left: layout.leftMargin * scale,
        top: layout.headerTopLineY * scale,
        child: pw.Container(
          width: layout.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColors.grey400,
                style: pw.BorderStyle.dashed,
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
      // Bottom header dashed line
      pw.Positioned(
        left: layout.leftMargin * scale,
        top: layout.headerBottomLineY * scale,
        child: pw.Container(
          width: layout.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColors.grey400,
                style: pw.BorderStyle.dashed,
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
      // Vertical Green Divider
      pw.Positioned(
        left: layout.headerDividerX * scale,
        top: layout.headerTopLineY * scale,
        child: pw.Container(
          width: 1.2 * scale,
          height: (layout.headerBottomLineY - layout.headerTopLineY) * scale,
          color: PdfColor.fromInt(0xFF499F34),
        ),
      ),
      // Invoice Box green border
      pw.Positioned(
        left: layout.invBoxX * scale,
        top: layout.invBoxY * scale,
        child: pw.Container(
          width: layout.invBoxWidth * scale,
          height: layout.invBoxHeight * scale,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColor.fromInt(0xFF499F34),
              width: 1.0 * scale,
            ),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(3 * scale)),
          ),
        ),
      ),
      // Invoice Box Header Green fill
      pw.Positioned(
        left: (layout.invBoxX + 0.5) * scale,
        top: (layout.invBoxY + 0.5) * scale,
        child: pw.Container(
          width: (layout.invBoxWidth - 1.0) * scale,
          height: (layout.invBoxHeaderHeight - 0.5) * scale,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF499F34),
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(2.5 * scale),
              topRight: pw.Radius.circular(2.5 * scale),
            ),
          ),
        ),
      ),
      // Bill To top dashed line
      pw.Positioned(
        left: layout.leftMargin * scale,
        top: layout.billToTopLineY * scale,
        child: pw.Container(
          width: layout.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColors.black,
                style: pw.BorderStyle.dashed,
                width: 0.8,
              ),
            ),
          ),
        ),
      ),
      // Bill To bottom dashed line
      pw.Positioned(
        left: layout.leftMargin * scale,
        top: layout.billToBottomLineY * scale,
        child: pw.Container(
          width: layout.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColors.black,
                style: pw.BorderStyle.dashed,
                width: 0.8,
              ),
            ),
          ),
        ),
      ),
      // Column Underlines
      pw.Positioned(
        left: layout.billToColumnUnderlineX1 * scale,
        top: layout.billToColumnUnderlineY * scale,
        child: pw.Container(
          width:
              (layout.billToColumnUnderlineX2 -
                  layout.billToColumnUnderlineX1) *
              scale,
          height: 1.0 * scale,
          color: PdfColors.black,
        ),
      ),
      pw.Positioned(
        left: layout.serviceColumnUnderlineX1 * scale,
        top: layout.serviceColumnUnderlineY * scale,
        child: pw.Container(
          width:
              (layout.serviceColumnUnderlineX2 -
                  layout.serviceColumnUnderlineX1) *
              scale,
          height: 1.0 * scale,
          color: PdfColors.black,
        ),
      ),
    ];

    // Add dotted separators under Bill To and Service Details fields
    if (customerSec.isVisible) {
      for (final f in customerFields) {
        if (f.id != 'customer_phone') {
          final underlineY =
              layout.getFieldY(f.id) + layout.getFieldHeight(f.id);
          decorativeLines.add(
            pw.Positioned(
              left: layout.billToColumnUnderlineX1 * scale,
              top: underlineY * scale,
              child: pw.Container(
                width:
                    (layout.billToColumnUnderlineX2 -
                        layout.billToColumnUnderlineX1) *
                    scale,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColors.grey400,
                      style: pw.BorderStyle.dashed,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    if (serviceSec.isVisible) {
      for (final f in serviceFields) {
        if (f.id != 'coordinator_name') {
          final underlineY =
              layout.getFieldY(f.id) + layout.getFieldHeight(f.id);
          decorativeLines.add(
            pw.Positioned(
              left: layout.serviceColumnUnderlineX1 * scale,
              top: underlineY * scale,
              child: pw.Container(
                width:
                    (layout.serviceColumnUnderlineX2 -
                        layout.serviceColumnUnderlineX1) *
                    scale,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColors.grey400,
                      style: pw.BorderStyle.dashed,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // Add Totals Box boundaries
    decorativeLines.addAll([
      pw.Positioned(
        left: layout.totalsBoxX * scale,
        top: totalsBoxY * scale,
        child: pw.Container(
          width: layout.totalsBoxWidth * scale,
          height: layout.totalsBoxHeight * scale,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.black,
              width: 0.8 * scale,
              style: pw.BorderStyle.dashed,
            ),
          ),
        ),
      ),
      pw.Positioned(
        left: layout.totalsBoxDividerX * scale,
        top: totalsBoxY * scale,
        child: pw.Container(
          width: 0.5 * scale,
          height: layout.totalsBoxHeight * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(
                color: PdfColors.black,
                style: pw.BorderStyle.dashed,
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
    ]);
    for (int i = 1; i < 6; i++) {
      final double y = totalsBoxY + (i * layout.totalsRowHeight);
      decorativeLines.add(
        pw.Positioned(
          left: layout.totalsBoxX * scale,
          top: y * scale,
          child: pw.Container(
            width: layout.totalsBoxWidth * scale,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColors.black,
                  style: pw.BorderStyle.dashed,
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Amount in words border
    decorativeLines.add(
      pw.Positioned(
        left: layout.wordsBoxX * scale,
        top: wordsBoxY * scale,
        child: pw.Container(
          width: layout.wordsBoxWidth * scale,
          height: layout.wordsBoxHeight * scale,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.black,
              width: 0.8 * scale,
              style: pw.BorderStyle.dashed,
            ),
          ),
        ),
      ),
    );

    // Footer section boundaries
    decorativeLines.addAll([
      pw.Positioned(
        left: layout.leftMargin * scale,
        top: footerTopLineY * scale,
        child: pw.Container(
          width: layout.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColors.black,
                style: pw.BorderStyle.dashed,
                width: 0.8,
              ),
            ),
          ),
        ),
      ),
      pw.Positioned(
        left: layout.leftMargin * scale,
        top: footerBottomLineY * scale,
        child: pw.Container(
          width: layout.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColors.black,
                style: pw.BorderStyle.dashed,
                width: 0.8,
              ),
            ),
          ),
        ),
      ),
    ]);

    // Build horizontal footer columns based on ordering and visibility
    final visibleFooters = template.footerSections.where((f) {
      if (!f.isVisible) return false;
      if (f.id == 'terms_conditions') return termsSec.isVisible;
      if (f.id == 'bank_details') return bankSec.isVisible;
      if (f.id == 'signature') return sigSec.isVisible;
      return true;
    }).toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    double sum = visibleFooters.fold(0.0, (prev, f) => prev + f.widthPercent);
    if (sum == 0.0) sum = 1.0;

    final normalizedFooters = visibleFooters
        .map((f) => f.copyWith(widthPercent: (f.widthPercent / sum) * 100.0))
        .toList();

    final List<pw.Widget> footerChildren = [];
    double footX = layout.leftMargin;

    for (int i = 0; i < normalizedFooters.length; i++) {
      final fSec = normalizedFooters[i];
      final colW = layout.contentWidth * (fSec.widthPercent / 100);
      final cellX = footX;

      if (i > 0) {
        // Draw green separator line
        decorativeLines.add(
          pw.Positioned(
            left: cellX * scale,
            top: footerTopLineY * scale,
            child: pw.Container(
              width: 1.0 * scale,
              height: (footerBottomLineY - footerTopLineY) * scale,
              color: PdfColor.fromInt(0xFF499F34),
            ),
          ),
        );
      }

      footX += colW;

      pw.Widget fCell;
      if (fSec.id == 'terms_conditions') {
        fCell = pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              fSec.title.toUpperCase(),
              style: _getPdfStyle(sectionTitleStyle, scale, forceBold: true),
            ),
            pw.SizedBox(height: 2),
            ...termsList
                .map(
                  (t) => pw.Padding(
                    padding: pw.EdgeInsets.symmetric(vertical: 0.5 * scale),
                    child: pw.Text(t, style: _getPdfStyle(footerStyle, scale)),
                  ),
                )
                .toList(),
          ],
        );
      } else if (fSec.id == 'bank_details') {
        fCell = pw.Padding(
          padding: pw.EdgeInsets.only(left: 8 * scale),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                fSec.title.toUpperCase(),
                style: _getPdfStyle(sectionTitleStyle, scale, forceBold: true),
              ),
              pw.SizedBox(height: 4),
              ...bankFields.map((bf) {
                final val = fieldValues[bf.id] ?? bf.defaultValue ?? '';
                return pw.Padding(
                  padding: pw.EdgeInsets.symmetric(vertical: 1.5 * scale),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 50 * scale,
                        child: pw.Text(
                          "${bf.label}:",
                          style: pw.TextStyle(
                            fontSize: footerStyle.fontSize * scale,
                            fontWeight: pw.FontWeight.bold,
                            font: _getFontBold(footerStyle.fontFamily),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          val.toString(),
                          style: _getPdfStyle(footerStyle, scale),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      } else {
        // signature
        fCell = pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              "FOR ${cName.toUpperCase()}",
              style: pw.TextStyle(
                fontSize: footerStyle.fontSize * scale,
                fontWeight: pw.FontWeight.bold,
                font: _getFontBold(footerStyle.fontFamily),
                color: PdfColor.fromInt(0xFF0B3B60),
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              "This is a computer-generated invoice.\nSubject to applicable laws of India.",
              style: pw.TextStyle(
                fontSize: 5.0 * scale,
                color: PdfColor.fromInt(0xFF555555),
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.Spacer(),
            if (sigImage != null)
              pw.Image(sigImage, height: 22 * scale)
            else
              pw.Text(
                fieldValues['signature_text']?.toString() ??
                    "Abhishek Prajapati",
                style: pw.TextStyle(
                  font: pw.Font.timesItalic(),
                  fontSize: 10 * scale,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1D4ED8),
                ),
              ),
            pw.Container(
              height: 0.5,
              margin: const pw.EdgeInsets.symmetric(vertical: 2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.grey500,
                    style: pw.BorderStyle.dashed,
                    width: 0.5,
                  ),
                ),
              ),
            ),
            pw.Text(
              signatoryTitle.toString().toUpperCase(),
              style: pw.TextStyle(
                fontSize: footerStyle.fontSize * scale,
                fontWeight: pw.FontWeight.bold,
                font: _getFontBold(footerStyle.fontFamily),
                color: PdfColor.fromInt(0xFF0B3B60),
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        );
      }

      footerChildren.add(
        _positionedField(
          posX: cellX + 4.0,
          posY: footerTopLineY + 6.0,
          width: colW - 8.0,
          height: layout.footerHeight - 12.0,
          child: fCell,
        ),
      );
    }

    return pw.SizedBox(
      width: layout.pageWidth * scale,
      height: layout.pageHeight * scale,
      child: pw.Stack(
        children: [
          // 1. Render all background lines & borders
          ...decorativeLines,

          // 2. Company Info Left
          if (companySec.isVisible)
            ...companyFields.map((f) {
              final rawVal = fieldValues[f.id] ?? f.defaultValue;
              final textVal =
                  (f.id == 'company_name' || f.id == 'company_tagline')
                  ? rawVal?.toString().toUpperCase() ?? ''
                  : rawVal?.toString() ?? '';

              final isCompName = f.id == 'company_name';
              final isTagline = f.id == 'company_tagline';
              final isPhone = f.id == 'company_phone';
              final isEmail = f.id == 'company_email';
              final isWebsite = f.id == 'company_website';
              final isContact = isPhone || isEmail || isWebsite;

              // Reduce company name font size so long names fit
              final effectiveHeaderStyle = isCompName
                  ? headerStyle.copyWith(fontSize: 10.0)
                  : headerStyle;

              final style = isCompName
                  ? effectiveHeaderStyle
                  : (isTagline ? subheaderStyle : bodyStyle);

              // Contact fields: use orange highlight color and smaller font
              final contactTextStyle = pw.TextStyle(
                fontSize: 7.0 * scale,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFFE57A25),
                font: _getFontBold(bodyStyle.fontFamily),
              );

              return _positionedField(
                posX: layout.getFieldX(f.id),
                posY: layout.getFieldY(f.id),
                width: layout.getFieldWidth(f.id),
                height: layout.getFieldHeight(f.id),
                child: isContact
                    ? pw.Text(textVal, style: contactTextStyle, maxLines: 1)
                    : pw.Text(
                        textVal,
                        maxLines: isCompName ? 2 : 1,
                        overflow: pw.TextOverflow.clip,
                        style: _getPdfStyle(
                          style,
                          scale,
                          forceBold: isCompName || isTagline,
                        ),
                      ),
              );
            }).toList(),

          // Logo Middle
          if (template.headerConfig.logoIsVisible && logoImage != null)
            _positionedField(
              posX: layout.logoX,
              posY: layout.logoY,
              width: layout.logoWidth,
              height: layout.logoHeight,
              child: pw.Image(logoImage),
            ),

          // Invoice Title
          if (invoiceSec.isVisible)
            _positionedField(
              posX: layout.invBoxX + 2,
              posY: layout.invBoxY + 4,
              width: layout.invBoxWidth - 4,
              height: layout.invBoxHeaderHeight - 4,
              child: pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "INVOICE",
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10.0 * scale,
                  ),
                ),
              ),
            ),

          // Invoice Info fields
          if (invoiceSec.isVisible)
            ...invoiceFields.map((f) {
              final rawVal = fieldValues[f.id] ?? f.defaultValue;
              final textVal = _formatValue(rawVal, f.valueType);
              final isBold =
                  f.id == 'company_pan' ||
                  f.id == 'company_gst_in' ||
                  f.id == 'invoice_number';

              return _positionedField(
                posX: layout.getFieldX(f.id),
                posY: layout.getFieldY(f.id),
                width: layout.getFieldWidth(f.id),
                height: layout.getFieldHeight(f.id),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 60 * scale,
                      child: pw.Text(
                        f.label,
                        style: pw.TextStyle(
                          fontSize: 7.5 * scale,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0B3B60),
                        ),
                      ),
                    ),
                    pw.Text(
                      ":  $textVal",
                      style: pw.TextStyle(
                        fontSize: 7.5 * scale,
                        fontWeight: isBold
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

          // BILL TO Section title
          if (customerSec.isVisible)
            _positionedField(
              posX: layout.billToColumnUnderlineX1,
              posY: layout.billToTopLineY + 4.0,
              width: 100,
              height: 12,
              child: pw.Text(
                customerSec.title,
                style: _getPdfStyle(sectionTitleStyle, scale, forceBold: true),
              ),
            ),

          if (customerSec.isVisible)
            ...customerFields.map((f) {
              final rawVal = fieldValues[f.id] ?? f.defaultValue;
              final textVal = _formatValue(rawVal, f.valueType);
              return _dottedFieldRow(
                f.label,
                textVal,
                layout.getFieldX(f.id),
                layout.getFieldY(f.id),
                layout.getFieldWidth(f.id),
                layout.getFieldHeight(f.id),
              );
            }).toList(),

          // SERVICE DETAIL Title
          if (serviceSec.isVisible)
            _positionedField(
              posX: layout.serviceColumnUnderlineX1,
              posY: layout.billToTopLineY + 4.0,
              width: 150,
              height: 12,
              child: pw.Text(
                serviceSec.title,
                style: _getPdfStyle(sectionTitleStyle, scale, forceBold: true),
              ),
            ),

          if (serviceSec.isVisible)
            ...serviceFields.map((f) {
              final rawVal = fieldValues[f.id] ?? f.defaultValue;
              final textVal = _formatValue(rawVal, f.valueType);
              return _dottedFieldRow(
                f.label,
                textVal,
                layout.getFieldX(f.id),
                layout.getFieldY(f.id),
                layout.getFieldWidth(f.id),
                layout.getFieldHeight(f.id),
              );
            }).toList(),

          // Service Items Table
          if (template.sections
              .firstWhere(
                (s) => s.id == 'items_table',
                orElse: () => SectionSchema(
                  id: 'items_table',
                  title: 'Items',
                  orderIndex: 4,
                  fields: [],
                ),
              )
              .isVisible)
            _positionedField(
              posX: layout.leftMargin,
              posY: layout.tableStartY,
              width: layout.contentWidth,
              height: layout.tableHeight,
              child: pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.black,
                  width: 0.8 * scale,
                ),
                columnWidths: Map.fromIterables(
                  Iterable<int>.generate(visibleCols.length),
                  visibleCols.map((c) => pw.FixedColumnWidth(c.width * scale)),
                ),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF499F34),
                    ),
                    children: visibleCols
                        .map(
                          (col) => pw.Padding(
                            padding: pw.EdgeInsets.symmetric(
                              vertical: 4 * scale,
                              horizontal: 1 * scale,
                            ),
                            child: pw.Text(
                              col.label,
                              style: pw.TextStyle(
                                color: _parseColor(tableHeaderStyle.textColor),
                                fontWeight:
                                    tableHeaderStyle.fontWeight == 'bold'
                                    ? pw.FontWeight.bold
                                    : pw.FontWeight.normal,
                                fontSize: tableHeaderStyle.fontSize * scale,
                                font: tableHeaderStyle.fontWeight == 'bold'
                                    ? _getFontBold(tableHeaderStyle.fontFamily)
                                    : _getFont(tableHeaderStyle.fontFamily),
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  ...List.generate(items.length, (idx) {
                    final item = items[idx];
                    return pw.TableRow(
                      children: visibleCols.map((col) {
                        final cellText = _getItemCellText(
                          item,
                          col,
                          idx,
                          df,
                          simpleCurrencyFmt,
                        );
                        pw.TextAlign cellAlign = pw.TextAlign.left;
                        if (col.id == 's_no' ||
                            col.id == 'no_of_vehicles' ||
                            col.id == 'date' ||
                            col.id == 'qty') {
                          cellAlign = pw.TextAlign.center;
                        } else if (col.id == 'rate' || col.id == 'amount') {
                          cellAlign = pw.TextAlign.right;
                        } else {
                          cellAlign = col.alignment == 'right'
                              ? pw.TextAlign.right
                              : (col.alignment == 'center'
                                    ? pw.TextAlign.center
                                    : pw.TextAlign.left);
                        }

                        return _cellBody(cellText, align: cellAlign);
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),

          // Totals Block
          if (template.sections
              .firstWhere(
                (s) => s.id == 'tax_summary',
                orElse: () => SectionSchema(
                  id: 'tax_summary',
                  title: 'Totals',
                  orderIndex: 5,
                  fields: [],
                ),
              )
              .isVisible) ...[
            _totalsRow(
              "Sub Total",
              simpleCurrencyFmt.format(invoice.subTotal),
              0,
            ),
            _totalsRow(
              "CGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%",
              simpleCurrencyFmt.format(invoice.cgst),
              1,
            ),
            _totalsRow(
              "SGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%",
              simpleCurrencyFmt.format(invoice.sgst),
              2,
            ),
            _totalsRow(
              "Total Amount",
              simpleCurrencyFmt.format(invoice.grandTotal),
              3,
              isTotalAmount: true,
            ),
            _totalsRow(
              "Advance Payment Received",
              simpleCurrencyFmt.format(invoice.advancePaid),
              4,
            ),
            _totalsRow(
              "Amount To Be Paid",
              simpleCurrencyFmt.format(
                invoice.grandTotal - invoice.advancePaid,
              ),
              5,
              isBold: true,
            ),

            // Amount in Words
            _positionedField(
              posX: layout.wordsBoxX,
              posY: wordsBoxY,
              width: layout.wordsBoxWidth,
              height: layout.wordsBoxHeight,
              child: pw.Padding(
                padding: pw.EdgeInsets.symmetric(
                  horizontal: 6 * scale,
                  vertical: 4 * scale,
                ),
                child: pw.Text(
                  "Amount to be paid in words : ${invoice.amountPaidInWords.endsWith(' Only') ? '${invoice.amountPaidInWords}.' : (invoice.amountPaidInWords.endsWith(' Only.') ? invoice.amountPaidInWords : '${invoice.amountPaidInWords} Only.')}",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: bodyStyle.fontSize * scale,
                    color: _parseColor(bodyStyle.textColor),
                    font: _getFontBold(bodyStyle.fontFamily),
                  ),
                ),
              ),
            ),
          ],

          // Footer Children
          ...footerChildren,
        ],
      ),
    );
  }

  static String _getItemCellText(
    InvoiceItem item,
    TableColumnSchema col,
    int index,
    DateFormat df,
    NumberFormat simpleCurrencyFmt,
  ) {
    String baseDesc = item.description;
    Map<String, String> customVals = {};
    try {
      final decoded = jsonDecode(item.description) as Map<String, dynamic>;
      if (decoded.containsKey('description')) {
        baseDesc = decoded['description']?.toString() ?? '';
        final custom = decoded['customValues'] as Map<String, dynamic>?;
        if (custom != null) {
          custom.forEach((k, v) {
            customVals[k] = v.toString();
          });
        }
      }
    } catch (_) {}

    if (col.id == 's_no') {
      return (index + 1).toString();
    } else if (col.id == 'description') {
      return baseDesc;
    } else if (col.id == 'no_of_vehicles') {
      return item.noOfVehicles?.toString() ?? '1';
    } else if (col.id == 'date') {
      return item.itemDate != null ? df.format(item.itemDate!) : '';
    } else if (col.id == 'from_to') {
      return item.fromTo ?? '';
    } else if (col.id == 'qty') {
      return item.quantityDays.toStringAsFixed(
        item.quantityDays % 1 == 0 ? 0 : 1,
      );
    } else if (col.id == 'rate') {
      return simpleCurrencyFmt.format(item.rate);
    } else if (col.id == 'amount') {
      return simpleCurrencyFmt.format(item.amount);
    } else {
      return customVals[col.id] ?? '';
    }
  }

  static pw.Font _getFont(String fontFamily) {
    if (fontFamily.toLowerCase() == 'courier') {
      return pw.Font.courier();
    } else if (fontFamily.toLowerCase() == 'helvetica' ||
        fontFamily.toLowerCase() == 'arial') {
      return pw.Font.helvetica();
    } else {
      return pw.Font.times();
    }
  }

  static pw.Font _getFontBold(String fontFamily) {
    if (fontFamily.toLowerCase() == 'courier') {
      return pw.Font.courierBold();
    } else if (fontFamily.toLowerCase() == 'helvetica' ||
        fontFamily.toLowerCase() == 'arial') {
      return pw.Font.helveticaBold();
    } else {
      return pw.Font.timesBold();
    }
  }

  static pw.TextStyle _getPdfStyle(
    TextStyleSchema style,
    double scale, {
    bool forceBold = false,
  }) {
    final font = (style.fontWeight == 'bold' || forceBold)
        ? _getFontBold(style.fontFamily)
        : _getFont(style.fontFamily);
    return pw.TextStyle(
      font: font,
      fontSize: style.fontSize * scale,
      color: _parseColor(style.textColor),
      lineSpacing: style.lineHeight,
      letterSpacing: style.letterSpacing * scale,
    );
  }

  // --- Dynamic Layout Block Builders for Standard / service / transport ---

  static pw.Widget _buildCompanyDetailsHeader(
    InvoiceTemplateSchema template,
    SectionSchema sec,
    pw.ImageProvider? logoImage,
    Invoice invoice,
    CompanyProfile company,
    double scale,
    DateFormat df,
  ) {
    final headerStyle =
        template.typography['header'] ??
        TextStyleSchema(
          fontSize: 16,
          fontWeight: 'bold',
          fontFamily: 'Helvetica',
          textColor: '#0B3B60',
        );
    final subheaderStyle =
        template.typography['subheader'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'normal',
          fontFamily: 'Helvetica',
          textColor: '#555555',
        );

    final name = company.name;
    final phone = company.contactNumber;
    final email = company.email;
    final address = company.address;
    final web = 'www.lntourism.com';

    final logoSize = template.headerConfig.logoSize;
    final primaryGreen = PdfColor.fromInt(0xFF499F34);

    return pw.Container(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Company Info
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  name.toUpperCase(),
                  style: _getPdfStyle(headerStyle, scale),
                ),
                pw.SizedBox(height: 4 * scale),
                pw.Text(
                  "Ph: $phone",
                  style: _getPdfStyle(subheaderStyle, scale),
                ),
                pw.Text(
                  "Email: $email   Web: $web",
                  style: _getPdfStyle(subheaderStyle, scale),
                ),
                pw.Text(
                  "Office Address: $address",
                  style: _getPdfStyle(subheaderStyle, scale),
                ),
              ],
            ),
          ),

          // Middle: Logo
          if (template.headerConfig.logoIsVisible)
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                children: [
                  if (logoImage != null)
                    pw.Image(logoImage, height: 35 * scale * logoSize)
                  else
                    pw.Container(
                      height: 35 * scale,
                      alignment: pw.Alignment.center,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey300),
                        ),
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Text(
                        company.name.isNotEmpty ? company.name[0] : 'L',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: primaryGreen,
                          fontSize: 12 * scale,
                        ),
                      ),
                    ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "LN TOURISM",
                    style: pw.TextStyle(
                      fontSize: 7 * scale,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF0B3B60),
                    ),
                  ),
                ],
              ),
            ),

          // Right: Invoice Meta Box
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: primaryGreen, width: 1.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    color: primaryGreen,
                    padding: pw.EdgeInsets.symmetric(vertical: 3 * scale),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      "INVOICE",
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10 * scale,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _invMetaRow(
                          "Invoice No.",
                          invoice.invoiceNumber,
                          scale,
                        ),
                        _invMetaRow(
                          "Invoice Date",
                          df.format(invoice.invoiceDate),
                          scale,
                        ),
                        _invMetaRow("GSTIN", company.gstNumber, scale),
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

  static pw.Widget _buildCustomerDetailsBlock(
    InvoiceTemplateSchema template,
    SectionSchema sec,
    Map<String, dynamic> values,
    double scale,
  ) {
    final sectionTitleStyle =
        template.typography['section_title'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'bold',
          fontFamily: 'Helvetica',
          textColor: '#499F34',
        );
    final subsectionTitleStyle =
        template.typography['subsection_title'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'bold',
          fontFamily: 'Helvetica',
          textColor: '#000000',
        );
    final bodyStyle =
        template.typography['body'] ??
        TextStyleSchema(
          fontSize: 7.5,
          fontWeight: 'normal',
          fontFamily: 'Helvetica',
          textColor: '#000000',
        );

    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final visibleFields = sec.fields.where((f) => f.isVisible).toList();

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            sec.title.toUpperCase(),
            style: _getPdfStyle(sectionTitleStyle, scale, forceBold: true),
          ),
          pw.Container(
            height: 1,
            color: primaryGreen,
            margin: pw.EdgeInsets.only(top: 1, bottom: 4 * scale),
          ),
          pw.Wrap(
            spacing: 12 * scale,
            runSpacing: 2 * scale,
            children: visibleFields.map((f) {
              final rawVal = values[f.id];
              final valStr = rawVal != null
                  ? _formatValue(rawVal, f.valueType)
                  : '';

              return pw.Container(
                width: 140 * scale,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${f.label}: ",
                      style: _getPdfStyle(
                        subsectionTitleStyle,
                        scale,
                        forceBold: true,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        valStr,
                        style: _getPdfStyle(bodyStyle, scale),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceMetaGrid(
    InvoiceTemplateSchema template,
    SectionSchema sec,
    Map<String, dynamic> values,
    double scale,
    DateFormat df,
  ) {
    final sectionTitleStyle =
        template.typography['section_title'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'bold',
          fontFamily: 'Helvetica',
          textColor: '#499F34',
        );
    final subsectionTitleStyle =
        template.typography['subsection_title'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'bold',
          fontFamily: 'Helvetica',
          textColor: '#000000',
        );
    final bodyStyle =
        template.typography['body'] ??
        TextStyleSchema(
          fontSize: 7.5,
          fontWeight: 'normal',
          fontFamily: 'Helvetica',
          textColor: '#000000',
        );

    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final visibleFields = sec.fields.where((f) => f.isVisible).toList();

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            sec.title.toUpperCase(),
            style: _getPdfStyle(sectionTitleStyle, scale, forceBold: true),
          ),
          pw.Container(
            height: 1,
            color: primaryGreen,
            margin: pw.EdgeInsets.only(top: 1, bottom: 4 * scale),
          ),
          pw.Wrap(
            spacing: 16 * scale,
            runSpacing: 3 * scale,
            children: visibleFields.map((f) {
              final rawVal = values[f.id];
              final valStr = rawVal != null
                  ? _formatValue(rawVal, f.valueType)
                  : '';

              return pw.Container(
                width: 160 * scale,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${f.label}: ",
                      style: _getPdfStyle(
                        subsectionTitleStyle,
                        scale,
                        forceBold: true,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        valStr,
                        style: _getPdfStyle(bodyStyle, scale),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDynamicItemsTable(
    InvoiceTemplateSchema template,
    List<InvoiceItem> items,
    double scale,
    DateFormat df,
    NumberFormat simpleCurrencyFmt,
  ) {
    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final visibleCols = template.tableColumns.where((c) => c.isVisible).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final Map<int, pw.TableColumnWidth> columnWidths = {};
    for (int i = 0; i < visibleCols.length; i++) {
      columnWidths[i] = pw.FixedColumnWidth(visibleCols[i].width * scale);
    }

    final tableHeaderStyle =
        template.typography['table_header'] ??
        TextStyleSchema(
          fontSize: 7.5,
          fontWeight: 'bold',
          fontFamily: 'Helvetica',
          textColor: '#FFFFFF',
        );
    final tableDataStyle =
        template.typography['table_data'] ??
        TextStyleSchema(
          fontSize: 7.5,
          fontWeight: 'normal',
          fontFamily: 'Helvetica',
          textColor: '#000000',
        );

    return pw.Container(
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
        columnWidths: columnWidths,
        children: [
          // Table Header
          pw.TableRow(
            decoration: pw.BoxDecoration(color: primaryGreen),
            children: visibleCols
                .map(
                  (c) => pw.Padding(
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Text(
                      c.label,
                      style: pw.TextStyle(
                        color: _parseColor(tableHeaderStyle.textColor),
                        fontWeight: tableHeaderStyle.fontWeight == 'bold'
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                        fontSize: tableHeaderStyle.fontSize * scale,
                        font: tableHeaderStyle.fontWeight == 'bold'
                            ? _getFontBold(tableHeaderStyle.fontFamily)
                            : _getFont(tableHeaderStyle.fontFamily),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                )
                .toList(),
          ),

          // Table Body
          ...List.generate(items.length, (index) {
            final item = items[index];
            return pw.TableRow(
              children: visibleCols.map((col) {
                final cellText = _getItemCellText(
                  item,
                  col,
                  index,
                  df,
                  simpleCurrencyFmt,
                );
                pw.TextAlign cellAlign = pw.TextAlign.left;

                if (col.id == 's_no' ||
                    col.id == 'no_of_vehicles' ||
                    col.id == 'date' ||
                    col.id == 'qty') {
                  cellAlign = pw.TextAlign.center;
                } else if (col.id == 'rate' || col.id == 'amount') {
                  cellAlign = pw.TextAlign.right;
                } else {
                  cellAlign = col.alignment == 'right'
                      ? pw.TextAlign.right
                      : (col.alignment == 'center'
                            ? pw.TextAlign.center
                            : pw.TextAlign.left);
                }

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  child: pw.Text(
                    cellText,
                    style: _getPdfStyle(tableDataStyle, scale),
                    textAlign: cellAlign,
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildTaxSummaryBlock(
    InvoiceTemplateSchema template,
    Invoice invoice,
    double scale,
    NumberFormat simpleCurrencyFmt,
    NumberFormat currencyFmt,
  ) {
    final tableDataStyle =
        template.typography['table_data'] ??
        TextStyleSchema(
          fontSize: 7.5,
          fontWeight: 'normal',
          fontFamily: 'Helvetica',
          textColor: '#000000',
        );

    return pw.Container(
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 180 * scale,
            child: pw.Column(
              children: [
                _totalRow(
                  "Sub Total",
                  simpleCurrencyFmt.format(invoice.subTotal),
                  scale,
                  style: tableDataStyle,
                ),
                _totalRow(
                  "CGST",
                  simpleCurrencyFmt.format(invoice.cgst),
                  scale,
                  style: tableDataStyle,
                ),
                _totalRow(
                  "SGST",
                  simpleCurrencyFmt.format(invoice.sgst),
                  scale,
                  style: tableDataStyle,
                ),

                // Total Amount Box
                pw.Container(
                  color: PdfColors.black,
                  padding: pw.EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3 * scale,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Total Amount",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 8 * scale,
                        ),
                      ),
                      pw.Text(
                        currencyFmt.format(invoice.grandTotal),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 8 * scale,
                        ),
                      ),
                    ],
                  ),
                ),

                _totalRow(
                  "Advance Paid",
                  simpleCurrencyFmt.format(invoice.advancePaid),
                  scale,
                  style: tableDataStyle,
                ),
                pw.Container(height: 0.5, color: PdfColors.black),
                _totalRow(
                  "Amount To Be Paid",
                  simpleCurrencyFmt.format(
                    invoice.grandTotal - invoice.advancePaid,
                  ),
                  scale,
                  isBold: true,
                  style: tableDataStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentInfoBlock(
    InvoiceTemplateSchema template,
    SectionSchema sec,
    CompanyProfile company,
    Invoice invoice,
    double scale,
    NumberFormat simpleCurrencyFmt,
    NumberFormat currencyFmt,
  ) {
    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final sectionTitleStyle =
        template.typography['section_title'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'bold',
          fontFamily: 'Helvetica',
          textColor: '#499F34',
        );
    final footerStyle =
        template.typography['footer'] ??
        TextStyleSchema(
          fontSize: 6.5,
          fontWeight: 'normal',
          fontFamily: 'Helvetica',
          textColor: '#000000',
        );

    Map<String, dynamic> fieldValues = {};
    if (invoice.fieldValuesJson != null &&
        invoice.fieldValuesJson!.isNotEmpty) {
      try {
        fieldValues = jsonDecode(invoice.fieldValuesJson!);
      } catch (_) {}
    }

    final bankAccountName =
        fieldValues['bank_account_name'] ?? company.bankAccountName;
    final bankName = fieldValues['bank_name'] ?? company.bankName;
    final bankAccountNo =
        fieldValues['bank_account_no'] ?? company.bankAccountNumber;
    final bankIfsc = fieldValues['bank_ifsc'] ?? company.bankIfscCode;
    final bankBranch = fieldValues['bank_branch'] ?? '';

    return pw.Container(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Bank details & Words block
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(height: 1, color: primaryGreen),
                pw.SizedBox(height: 2),
                pw.Text(
                  sec.title.toUpperCase(),
                  style: _getPdfStyle(
                    sectionTitleStyle,
                    scale,
                    forceBold: true,
                  ),
                ),
                pw.SizedBox(height: 4 * scale),
                _bankItem(
                  "Account Name",
                  bankAccountName.toString(),
                  scale,
                  style: footerStyle,
                ),
                _bankItem(
                  "Bank Name",
                  bankName.toString(),
                  scale,
                  style: footerStyle,
                ),
                _bankItem(
                  "Account No",
                  bankAccountNo.toString(),
                  scale,
                  style: footerStyle,
                ),
                _bankItem(
                  "IFSC Code",
                  bankIfsc.toString(),
                  scale,
                  style: footerStyle,
                ),
                if (bankBranch.toString().isNotEmpty)
                  _bankItem(
                    "Branch",
                    bankBranch.toString(),
                    scale,
                    style: footerStyle,
                  ),
                pw.SizedBox(height: 6 * scale),
                pw.Text(
                  "Amount to be paid in words: ${invoice.amountPaidInWords}",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: footerStyle.fontSize * scale,
                    font: _getFontBold(footerStyle.fontFamily),
                  ),
                ),
              ],
            ),
          ),

          // Right: Dynamic QR Code and Barcode
          pw.Expanded(
            flex: 1,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  height: 45 * scale,
                  width: 45 * scale,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data:
                        'upi://pay?pa=lntourism@okaxis&pn=LN%20Tourism&am=${invoice.grandTotal - invoice.advancePaid}&cu=INR',
                  ),
                ),
                pw.SizedBox(width: 8 * scale),
                pw.Container(
                  height: 35 * scale,
                  width: 60 * scale,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: invoice.invoiceNumber,
                    drawText: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTermsConditionsBlock(
    InvoiceTemplateSchema template,
    SectionSchema sec,
    double scale,
  ) {
    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final sectionTitleStyle =
        template.typography['section_title'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'bold',
          fontFamily: 'Helvetica',
          textColor: '#499F34',
        );
    final footerStyle =
        template.typography['footer'] ??
        TextStyleSchema(
          fontSize: 6.5,
          fontWeight: 'normal',
          fontFamily: 'Helvetica',
          textColor: '#000000',
        );

    final field = sec.fields.firstWhere(
      (f) => f.id == 'terms_text',
      orElse: () =>
          FieldSchema(id: 'terms_text', label: 'Terms', valueType: 'text'),
    );
    final termsString =
        field.defaultValue?.toString() ??
        '1. Subject to local jurisdiction.\n2. E&OE.';
    final termsList = termsString.split('\n');

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 1, color: primaryGreen),
          pw.SizedBox(height: 2),
          pw.Text(
            sec.title.toUpperCase(),
            style: _getPdfStyle(sectionTitleStyle, scale, forceBold: true),
          ),
          pw.SizedBox(height: 4 * scale),
          ...termsList
              .map(
                (term) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Text(term, style: _getPdfStyle(footerStyle, scale)),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureBlock(
    InvoiceTemplateSchema template,
    SectionSchema sec,
    CompanyProfile company,
    pw.ImageProvider? sigImage,
    double scale,
    Invoice invoice,
  ) {
    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final sectionTitleStyle =
        template.typography['section_title'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'bold',
          fontFamily: 'Helvetica',
          textColor: '#499F34',
        );
    final footerStyle =
        template.typography['footer'] ??
        TextStyleSchema(
          fontSize: 6.5,
          fontWeight: 'normal',
          fontFamily: 'Helvetica',
          textColor: '#000000',
        );

    Map<String, dynamic> fieldValues = {};
    if (invoice.fieldValuesJson != null &&
        invoice.fieldValuesJson!.isNotEmpty) {
      try {
        fieldValues = jsonDecode(invoice.fieldValuesJson!);
      } catch (_) {}
    }
    final String signatureText =
        fieldValues['signature_text']?.toString() ??
        company.name.split(' ').first;

    final field = sec.fields.firstWhere(
      (f) => f.id == 'signatory_title',
      orElse: () =>
          FieldSchema(id: 'signatory_title', label: 'Title', valueType: 'text'),
    );
    final title = field.defaultValue?.toString() ?? 'AUTHORIZED SIGNATORY';

    return pw.Container(
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 140 * scale,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(height: 1, color: primaryGreen),
                pw.SizedBox(height: 2),
                pw.Text(
                  "FOR ${company.name.toUpperCase()}",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 7 * scale,
                    color: PdfColor.fromInt(0xFF0B3B60),
                  ),
                ),
                pw.SizedBox(height: 2),

                // Signature image
                pw.Container(
                  height: 25 * scale,
                  alignment: pw.Alignment.bottomCenter,
                  child: sigImage != null
                      ? pw.Image(sigImage, height: 22 * scale)
                      : pw.Text(
                          signatureText,
                          style: pw.TextStyle(
                            font: pw.Font.timesItalic(),
                            fontSize: 9 * scale,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF0B3B60),
                          ),
                        ),
                ),
                pw.Container(
                  height: 0.5,
                  color: PdfColors.grey400,
                  margin: const pw.EdgeInsets.symmetric(vertical: 2),
                ),
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 6 * scale,
                    color: PdfColor.fromInt(0xFF0B3B60),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

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

  static PdfColor _parseColor(String hex) {
    try {
      final hexClean = hex.replaceFirst('#', '').trim();
      return PdfColor.fromInt(int.parse('FF$hexClean', radix: 16));
    } catch (_) {
      return PdfColors.black;
    }
  }

  static pw.Widget _invMetaRow(String label, String value, double scale) {
    final deepBlue = PdfColor.fromInt(0xFF0B3B60);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
      child: pw.Row(
        children: [
          pw.Container(
            width: 50 * scale,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 6 * scale,
                fontWeight: pw.FontWeight.bold,
                color: deepBlue,
              ),
            ),
          ),
          pw.Text(":  $value", style: pw.TextStyle(fontSize: 6 * scale)),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value,
    double scale, {
    bool isBold = false,
    required TextStyleSchema style,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: style.fontSize * scale,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              font: isBold
                  ? _getFontBold(style.fontFamily)
                  : _getFont(style.fontFamily),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: style.fontSize * scale,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              font: isBold
                  ? _getFontBold(style.fontFamily)
                  : _getFont(style.fontFamily),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _termItem(String text, double scale) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 5.5 * scale)),
    );
  }

  static pw.Widget _bankItem(
    String label,
    String value,
    double scale, {
    required TextStyleSchema style,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Container(
            width: 50 * scale,
            child: pw.Text(
              "$label:",
              style: pw.TextStyle(
                fontSize: style.fontSize * scale,
                fontWeight: pw.FontWeight.bold,
                font: _getFontBold(style.fontFamily),
              ),
            ),
          ),
          pw.Text(value, style: _getPdfStyle(style, scale)),
        ],
      ),
    );
  }
}
