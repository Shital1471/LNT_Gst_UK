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
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);
    final simpleCurrencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);

    // 1. Determine active template schema configuration
    InvoiceTemplateSchema template;
    if (invoice.templateSchemaJson != null && invoice.templateSchemaJson!.isNotEmpty) {
      template = InvoiceTemplateSchema.fromJson(jsonDecode(invoice.templateSchemaJson!));
    } else {
      template = InvoiceTemplateSchema.getPreset(invoice.templateType);
    }

    // 2. Parse dynamic field values map
    Map<String, dynamic> fieldValues = {};
    if (invoice.fieldValuesJson != null && invoice.fieldValuesJson!.isNotEmpty) {
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

    // Add company metadata to values to resolve company details dynamically
    fieldValues['company_name'] = company.name;
    fieldValues['company_address'] = company.address;
    fieldValues['company_gst'] = company.gstNumber;
    fieldValues['company_phone'] = company.contactNumber;
    fieldValues['company_email'] = company.email;
    fieldValues['company_website'] = 'www.lntourism.com';

    // 3. Determine Page dimensions
    PdfPageFormat pageFormat = PdfPageFormat.a4;
    if (template.pageFormat == 'Letter') {
      pageFormat = PdfPageFormat.letter;
    } else if (template.pageFormat == 'Custom') {
      pageFormat = PdfPageFormat(template.pageWidth, template.pageHeight);
    }

    // 4. Calculate auto-scaling multiplier based on density
    double scale = 1.0;

    // 5. Load branding logo and signature images if available
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

    if (company.signaturePath != null && company.signaturePath!.isNotEmpty) {
      try {
        final file = File(company.signaturePath!);
        if (await file.exists()) {
          sigImage = pw.MemoryImage(await file.readAsBytes());
        }
      } catch (_) {}
    }

    // 6. Build sections in sorted layout sequence
    final visibleSections = template.sections.where((s) => s.isVisible).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final isTourism = template.id == 'tourism';
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
                top: template.marginTop * scale,
                bottom: template.marginBottom * scale,
                left: template.marginLeft * scale,
                right: template.marginRight * scale,
              ),
        build: (pw.Context context) {
          if (isTourism) {
            return _buildTourismLayout(
              template: template,
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
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: visibleSections.map((sec) {
              if (sec.id == 'company_details') {
                return _buildCompanyDetailsHeader(sec, logoImage, invoice, company, scale, df);
              } else if (sec.id == 'customer_details') {
                return _buildCustomerDetailsBlock(sec, fieldValues, scale);
              } else if (sec.id == 'invoice_info') {
                return _buildInvoiceMetaGrid(sec, fieldValues, scale, df);
              } else if (sec.id == 'items_table') {
                return _buildDynamicItemsTable(template.id, items, scale, df, simpleCurrencyFmt);
              } else if (sec.id == 'tax_summary') {
                return _buildTaxSummaryBlock(invoice, scale, simpleCurrencyFmt, currencyFmt);
              } else if (sec.id == 'payment_info') {
                return _buildPaymentInfoBlock(sec, company, invoice, scale, simpleCurrencyFmt, currencyFmt);
              } else if (sec.id == 'terms_conditions') {
                return _buildTermsConditionsBlock(sec, scale);
              } else if (sec.id == 'signature') {
                return _buildSignatureBlock(sec, company, sigImage, scale);
              }
              return pw.SizedBox();
            }).toList(),
          );
        },
      ),
    );

    return await pdf.save();
  }

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
    final cName = (fieldValues['company_name'] ?? company.name).toString().toUpperCase();
    final tagline = (fieldValues['company_tagline'] ?? 'TOURS & TRAVELS | CAR RENTAL | TRANSPORT SOLUTIONS').toString().toUpperCase();
    final phone = fieldValues['company_phone'] ?? company.contactNumber;
    final email = fieldValues['company_email'] ?? company.email;
    final web = fieldValues['company_website'] ?? 'www.lntourism.com';
    final address = fieldValues['company_address'] ?? company.address;

    final customerName = fieldValues['customer_name'] ?? '';
    final customerAddress = fieldValues['customer_address'] ?? '';
    final customerCityStatePin = fieldValues['customer_city_state_pin'] ?? '';
    final customerGst = fieldValues['customer_gst'] ?? '';
    final customerPhone = fieldValues['customer_phone'] ?? '';

    final invoiceNo = fieldValues['invoice_number'] ?? '';
    final invoiceDateRaw = fieldValues['invoice_date'];
    final invoiceDate = invoiceDateRaw != null ? _formatValue(invoiceDateRaw, 'date') : '';
    final bookingRef = fieldValues['booking_ref'] ?? '';
    final bookingDateRaw = fieldValues['booking_date'];
    final bookingDate = bookingDateRaw != null ? _formatValue(bookingDateRaw, 'date') : '';
    final companyPan = fieldValues['company_pan'] ?? 'AAGCL7813B';
    final companyGstIn = fieldValues['company_gst_in'] ?? '05AAGCL7813B1ZU';

    final tourTrip = fieldValues['tour_trip'] ?? '';
    final travelDateRaw = fieldValues['travel_date'];
    final travelDate = travelDateRaw != null ? _formatValue(travelDateRaw, 'date') : '';
    final noOfDays = fieldValues['no_of_days']?.toString() ?? '';
    final noOfVehicles = fieldValues['no_of_vehicles']?.toString() ?? '';
    final coordinatorName = fieldValues['coordinator_name'] ?? '';

    final bankAccountName = fieldValues['bank_account_name'] ?? company.bankAccountName;
    final bankName = fieldValues['bank_name'] ?? company.bankName;
    final bankAccountNo = fieldValues['bank_account_no'] ?? company.bankAccountNumber;
    final bankIfsc = fieldValues['bank_ifsc'] ?? company.bankIfscCode;

    final termsString = fieldValues['terms_text'] ?? 
        '1. Payment to be made within 7 days from invoice date.\n2. Extra charges (State Tax, Night Halt, Extra Km) will be charged as per actual.\n3. Vehicle will be provided as per the itinerary only.\n4. No refund for unused days or cancellations post journey.\n5. All disputes are subject to Dehradun jurisdiction only.';
    final termsList = termsString.toString().split('\n').where((t) => t.isNotEmpty).toList();

    final signatoryTitle = fieldValues['signatory_title'] ?? 'AUTHORISED SIGNATORY';

    final double gstPercentage = (invoice.subTotal == 0) ? 0.0 : ((invoice.cgst + invoice.sgst) / invoice.subTotal * 100);
    final gstHalfRate = gstPercentage / 2;

    // Helper functions for absolute Positioning
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

    pw.Widget _invoiceInfoRow(String label, String value, double posY, {bool isBold = false}) {
      return pw.Positioned(
        left: (TourismLayoutConfig.invBoxX + 6) * scale,
        top: posY * scale,
        child: pw.SizedBox(
          width: (TourismLayoutConfig.invBoxWidth - 12) * scale,
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
                  fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget _dottedFieldRow(String label, String value, double posY, {bool isRightCol = false}) {
      final double left = (isRightCol ? 300 : 22);
      final double width = (isRightCol ? 273.27 : 263);

      return pw.Positioned(
        left: left * scale,
        top: posY * scale,
        child: pw.SizedBox(
          width: width * scale,
          height: 12 * scale,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                width: (isRightCol ? 90 : 75) * scale,
                child: pw.Text(
                  "$label :",
                  style: pw.TextStyle(fontSize: 8.0 * scale, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  value,
                  style: pw.TextStyle(fontSize: 8.0 * scale),
                ),
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget _totalsRow(String label, String value, int rowIndex, {bool isBold = false, bool isTotalAmount = false}) {
      final double top = TourismLayoutConfig.totalsBoxY + (rowIndex * TourismLayoutConfig.totalsRowHeight);
      
      return pw.Positioned(
        left: TourismLayoutConfig.totalsBoxX * scale,
        top: top * scale,
        child: pw.Container(
          width: TourismLayoutConfig.totalsBoxWidth * scale,
          height: TourismLayoutConfig.totalsRowHeight * scale,
          color: isTotalAmount ? PdfColors.black : null,
          padding: pw.EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 3 * scale),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 7.5 * scale,
                  fontWeight: (isBold || isTotalAmount) ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: isTotalAmount ? PdfColors.white : PdfColors.black,
                ),
              ),
              pw.Text(
                "Rs. $value",
                style: pw.TextStyle(
                  fontSize: 7.5 * scale,
                  fontWeight: (isBold || isTotalAmount) ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: isTotalAmount ? PdfColors.white : PdfColors.black,
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
                  style: pw.TextStyle(fontSize: 7.5 * scale, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  value,
                  style: pw.TextStyle(fontSize: 7.5 * scale),
                ),
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget _cellBody(String text, {pw.TextAlign align = pw.TextAlign.left}) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 3.5 * scale),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 7.5 * scale),
          textAlign: align,
        ),
      );
    }

    // List of Positioned background lines
    final List<pw.Widget> decorativeLines = [
      // Top header dashed line
      pw.Positioned(
        left: TourismLayoutConfig.leftMargin * scale,
        top: TourismLayoutConfig.headerTopLineY * scale,
        child: pw.Container(
          width: TourismLayoutConfig.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, style: pw.BorderStyle.dashed, width: 0.5),
            ),
          ),
        ),
      ),
      // Bottom header dashed line
      pw.Positioned(
        left: TourismLayoutConfig.leftMargin * scale,
        top: TourismLayoutConfig.headerBottomLineY * scale,
        child: pw.Container(
          width: TourismLayoutConfig.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, style: pw.BorderStyle.dashed, width: 0.5),
            ),
          ),
        ),
      ),
      // Green divider
      pw.Positioned(
        left: TourismLayoutConfig.headerDividerX * scale,
        top: TourismLayoutConfig.headerTopLineY * scale,
        child: pw.Container(
          width: 1.2 * scale,
          height: (TourismLayoutConfig.headerBottomLineY - TourismLayoutConfig.headerTopLineY) * scale,
          color: PdfColor.fromInt(0xFF499F34),
        ),
      ),
      // Invoice Box green border
      pw.Positioned(
        left: TourismLayoutConfig.invBoxX * scale,
        top: TourismLayoutConfig.invBoxY * scale,
        child: pw.Container(
          width: TourismLayoutConfig.invBoxWidth * scale,
          height: TourismLayoutConfig.invBoxHeight * scale,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromInt(0xFF499F34), width: 1.0 * scale),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(3 * scale)),
          ),
        ),
      ),
      // Invoice Box Header Green fill
      pw.Positioned(
        left: (TourismLayoutConfig.invBoxX + 0.5) * scale,
        top: (TourismLayoutConfig.invBoxY + 0.5) * scale,
        child: pw.Container(
          width: (TourismLayoutConfig.invBoxWidth - 1.0) * scale,
          height: (TourismLayoutConfig.invBoxHeaderHeight - 0.5) * scale,
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
        left: TourismLayoutConfig.leftMargin * scale,
        top: TourismLayoutConfig.billToTopLineY * scale,
        child: pw.Container(
          width: TourismLayoutConfig.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, style: pw.BorderStyle.dashed, width: 0.8),
            ),
          ),
        ),
      ),
      // Bill To bottom dashed line
      pw.Positioned(
        left: TourismLayoutConfig.leftMargin * scale,
        top: TourismLayoutConfig.billToBottomLineY * scale,
        child: pw.Container(
          width: TourismLayoutConfig.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, style: pw.BorderStyle.dashed, width: 0.8),
            ),
          ),
        ),
      ),
      // Column Underlines
      pw.Positioned(
        left: TourismLayoutConfig.billToColumnUnderlineX1 * scale,
        top: TourismLayoutConfig.billToColumnUnderlineY * scale,
        child: pw.Container(
          width: (TourismLayoutConfig.billToColumnUnderlineX2 - TourismLayoutConfig.billToColumnUnderlineX1) * scale,
          height: 1.0 * scale,
          color: PdfColors.black,
        ),
      ),
      pw.Positioned(
        left: TourismLayoutConfig.serviceColumnUnderlineX1 * scale,
        top: TourismLayoutConfig.serviceColumnUnderlineY * scale,
        child: pw.Container(
          width: (TourismLayoutConfig.serviceColumnUnderlineX2 - TourismLayoutConfig.serviceColumnUnderlineX1) * scale,
          height: 1.0 * scale,
          color: PdfColors.black,
        ),
      ),
    ];

    // Add dotted separators under Bill To and Service Details fields
    for (double y in [184.0, 198.0, 212.0, 226.0]) {
      decorativeLines.add(
        pw.Positioned(
          left: TourismLayoutConfig.billToColumnUnderlineX1 * scale,
          top: y * scale,
          child: pw.Container(
            width: (TourismLayoutConfig.billToColumnUnderlineX2 - TourismLayoutConfig.billToColumnUnderlineX1) * scale,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, style: pw.BorderStyle.dashed, width: 0.5),
              ),
            ),
          ),
        ),
      );
      decorativeLines.add(
        pw.Positioned(
          left: TourismLayoutConfig.serviceColumnUnderlineX1 * scale,
          top: y * scale,
          child: pw.Container(
            width: (TourismLayoutConfig.serviceColumnUnderlineX2 - TourismLayoutConfig.serviceColumnUnderlineX1) * scale,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, style: pw.BorderStyle.dashed, width: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    // Add Totals Box boundaries and inside lines
    decorativeLines.addAll([
      // Totals box outer dashed border
      pw.Positioned(
        left: TourismLayoutConfig.totalsBoxX * scale,
        top: TourismLayoutConfig.totalsBoxY * scale,
        child: pw.Container(
          width: TourismLayoutConfig.totalsBoxWidth * scale,
          height: TourismLayoutConfig.totalsBoxHeight * scale,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.8 * scale, style: pw.BorderStyle.dashed),
          ),
        ),
      ),
      // Inside vertical dashed separator
      pw.Positioned(
        left: TourismLayoutConfig.totalsBoxDividerX * scale,
        top: TourismLayoutConfig.totalsBoxY * scale,
        child: pw.Container(
          width: 0.5 * scale,
          height: TourismLayoutConfig.totalsBoxHeight * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: PdfColors.black, style: pw.BorderStyle.dashed, width: 0.5),
            ),
          ),
        ),
      ),
    ]);
    for (int i = 1; i < 6; i++) {
      final double y = TourismLayoutConfig.totalsBoxY + (i * TourismLayoutConfig.totalsRowHeight);
      decorativeLines.add(
        pw.Positioned(
          left: TourismLayoutConfig.totalsBoxX * scale,
          top: y * scale,
          child: pw.Container(
            width: TourismLayoutConfig.totalsBoxWidth * scale,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, style: pw.BorderStyle.dashed, width: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    // Amount in words box dashed border
    decorativeLines.add(
      pw.Positioned(
        left: TourismLayoutConfig.wordsBoxX * scale,
        top: TourismLayoutConfig.wordsBoxY * scale,
        child: pw.Container(
          width: TourismLayoutConfig.wordsBoxWidth * scale,
          height: TourismLayoutConfig.wordsBoxHeight * scale,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.8 * scale, style: pw.BorderStyle.dashed),
          ),
        ),
      ),
    );

    // Footer section boundaries
    decorativeLines.addAll([
      // Top dashed footer line
      pw.Positioned(
        left: TourismLayoutConfig.leftMargin * scale,
        top: TourismLayoutConfig.footerTopLineY * scale,
        child: pw.Container(
          width: TourismLayoutConfig.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, style: pw.BorderStyle.dashed, width: 0.8),
            ),
          ),
        ),
      ),
      // Bottom dashed footer line
      pw.Positioned(
        left: TourismLayoutConfig.leftMargin * scale,
        top: TourismLayoutConfig.footerBottomLineY * scale,
        child: pw.Container(
          width: TourismLayoutConfig.contentWidth * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, style: pw.BorderStyle.dashed, width: 0.8),
            ),
          ),
        ),
      ),
      // Green vertical divider 1
      pw.Positioned(
        left: TourismLayoutConfig.footerDivider1X * scale,
        top: TourismLayoutConfig.footerTopLineY * scale,
        child: pw.Container(
          width: 1.0 * scale,
          height: (TourismLayoutConfig.footerBottomLineY - TourismLayoutConfig.footerTopLineY) * scale,
          color: PdfColor.fromInt(0xFF499F34),
        ),
      ),
      // Green vertical divider 2
      pw.Positioned(
        left: TourismLayoutConfig.footerDivider2X * scale,
        top: TourismLayoutConfig.footerTopLineY * scale,
        child: pw.Container(
          width: 1.0 * scale,
          height: (TourismLayoutConfig.footerBottomLineY - TourismLayoutConfig.footerTopLineY) * scale,
          color: PdfColor.fromInt(0xFF499F34),
        ),
      ),
      // Signature dotted line
      pw.Positioned(
        left: 395 * scale,
        top: TourismLayoutConfig.sigUnderlineY * scale,
        child: pw.Container(
          width: 171 * scale,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey500, style: pw.BorderStyle.dashed, width: 0.5),
            ),
          ),
        ),
      ),
    ]);

    return pw.SizedBox(
      width: TourismLayoutConfig.pageWidth * scale,
      height: TourismLayoutConfig.pageHeight * scale,
      child: pw.Stack(
        children: [
          // 1. Render all background lines & borders
          ...decorativeLines,

          // 2. Company Info Left
          _positionedField(
            posX: 22, posY: 32, width: 230, height: 16,
            child: pw.Text(
              cName,
              style: pw.TextStyle(
                fontSize: 12 * scale,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF0B3B60),
              ),
            ),
          ),
          _positionedField(
            posX: 22, posY: 46, width: 230, height: 10,
            child: pw.Text(
              tagline,
              style: pw.TextStyle(
                fontSize: 6.5 * scale,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFFE57A25),
              ),
            ),
          ),
          _positionedField(
            posX: 22, posY: 78, width: 230, height: 10,
            child: pw.Text(
              "Ph: $phone",
              style: pw.TextStyle(fontSize: 7.5 * scale),
            ),
          ),
          _positionedField(
            posX: 22, posY: 88, width: 340, height: 10,
            child: pw.Text(
              "Email: $email   Web: $web",
              style: pw.TextStyle(fontSize: 7.5 * scale),
            ),
          ),
          _positionedField(
            posX: 22, posY: 98, width: 340, height: 20,
            child: pw.Text(
              "Office Address : $address",
              style: pw.TextStyle(fontSize: 7.5 * scale),
            ),
          ),

          // Logo Middle
          if (logoImage != null)
            _positionedField(
              posX: TourismLayoutConfig.logoX,
              posY: TourismLayoutConfig.logoY,
              width: TourismLayoutConfig.logoWidth,
              height: TourismLayoutConfig.logoHeight,
              child: pw.Image(logoImage),
            ),

          // Invoice Title
          _positionedField(
            posX: TourismLayoutConfig.invBoxX + 2,
            posY: TourismLayoutConfig.invBoxY + 4,
            width: TourismLayoutConfig.invBoxWidth - 4,
            height: TourismLayoutConfig.invBoxHeaderHeight - 4,
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
          _invoiceInfoRow("Invoice No.", invoiceNo.toString(), 62),
          _invoiceInfoRow("Invoice Date", invoiceDate.toString(), 73),
          _invoiceInfoRow("Booking Ref.", bookingRef.toString(), 84),
          _invoiceInfoRow("Booking Date", bookingDate.toString(), 95),
          _invoiceInfoRow("PAN No.", companyPan.toString(), 106, isBold: true),
          _invoiceInfoRow("GSTIN", companyGstIn.toString(), 117, isBold: true),

          // BILL TO
          _positionedField(
            posX: 22, posY: 154, width: 100, height: 12,
            child: pw.Text(
              "BILL TO",
              style: pw.TextStyle(fontSize: 8 * scale, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF499F34)),
            ),
          ),
          _dottedFieldRow("Name / Company", customerName.toString(), 172),
          _dottedFieldRow("Address", customerAddress.toString(), 186),
          _dottedFieldRow("City / State / PIN", customerCityStatePin.toString(), 200),
          _dottedFieldRow("GSTIN", customerGst.toString(), 214),
          _dottedFieldRow("Contact No.", customerPhone.toString(), 228),

          // SERVICE DETAIL
          _positionedField(
            posX: 300, posY: 154, width: 150, height: 12,
            child: pw.Text(
              "SERVICE DETAIL 8",
              style: pw.TextStyle(fontSize: 8 * scale, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF499F34)),
            ),
          ),
          _dottedFieldRow("Tour / Trip", tourTrip.toString(), 172, isRightCol: true),
          _dottedFieldRow("Travel Date", travelDate.toString(), 186, isRightCol: true),
          _dottedFieldRow("No. of Days", noOfDays.toString(), 200, isRightCol: true),
          _dottedFieldRow("No. of Vehicles", noOfVehicles.toString(), 214, isRightCol: true),
          _dottedFieldRow("Co-ordinator Name", coordinatorName.toString(), 228, isRightCol: true),

          // Service Items Table
          _positionedField(
            posX: TourismLayoutConfig.leftMargin,
            posY: TourismLayoutConfig.tableStartY,
            width: TourismLayoutConfig.contentWidth,
            height: (TourismLayoutConfig.pageHeight - TourismLayoutConfig.tableStartY) * scale,
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8 * scale),
              columnWidths: Map.fromIterables(
                Iterable<int>.generate(TourismLayoutConfig.tableColumnWidths.length),
                TourismLayoutConfig.tableColumnWidths.map((w) => pw.FixedColumnWidth(w * scale)),
              ),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF499F34)),
                  children: TourismLayoutConfig.tableColumnLabels.map((lbl) => pw.Padding(
                    padding: pw.EdgeInsets.symmetric(vertical: 4 * scale, horizontal: 1 * scale),
                    child: pw.Text(
                      lbl,
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 7.5 * scale),
                      textAlign: pw.TextAlign.center,
                    ),
                  )).toList(),
                ),
                ...List.generate(items.length, (idx) {
                  final item = items[idx];
                  final itemDateStr = item.itemDate != null ? df.format(item.itemDate!) : '';
                  return pw.TableRow(
                    children: [
                      _cellBody((idx + 1).toString(), align: pw.TextAlign.center),
                      _cellBody(item.description),
                      _cellBody(item.noOfVehicles?.toString() ?? '1', align: pw.TextAlign.center),
                      _cellBody(itemDateStr, align: pw.TextAlign.center),
                      _cellBody(item.fromTo ?? ''),
                      _cellBody(item.quantityDays.toStringAsFixed(item.quantityDays % 1 == 0 ? 0 : 1), align: pw.TextAlign.center),
                      _cellBody(simpleCurrencyFmt.format(item.rate), align: pw.TextAlign.right),
                      _cellBody(simpleCurrencyFmt.format(item.amount), align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Totals Block
          _totalsRow("Sub Total", simpleCurrencyFmt.format(invoice.subTotal), 0),
          _totalsRow("CGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%", simpleCurrencyFmt.format(invoice.cgst), 1),
          _totalsRow("SGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%", simpleCurrencyFmt.format(invoice.sgst), 2),
          _totalsRow("Total Amount", simpleCurrencyFmt.format(invoice.grandTotal), 3, isTotalAmount: true),
          _totalsRow("Advance Payment Received", simpleCurrencyFmt.format(invoice.advancePaid), 4),
          _totalsRow("Amount To Be Paid", simpleCurrencyFmt.format(invoice.grandTotal - invoice.advancePaid), 5, isBold: true),

          // Amount in Words
          _positionedField(
            posX: TourismLayoutConfig.wordsBoxX,
            posY: TourismLayoutConfig.wordsBoxY,
            width: TourismLayoutConfig.wordsBoxWidth,
            height: TourismLayoutConfig.wordsBoxHeight,
            child: pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 4 * scale),
              child: pw.Text(
                "Amount to be paid in words : ${invoice.amountPaidInWords.endsWith(' Only') ? '${invoice.amountPaidInWords}.' : (invoice.amountPaidInWords.endsWith(' Only.') ? invoice.amountPaidInWords : '${invoice.amountPaidInWords} Only.')}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.0 * scale),
              ),
            ),
          ),

          // Footer Terms
          _positionedField(
            posX: 28, posY: 562, width: 170, height: 10,
            child: pw.Text(
              "TERM & CONDITION 8",
              style: pw.TextStyle(fontSize: 8.0 * scale, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF499F34)),
            ),
          ),
          _positionedField(
            posX: 28, posY: 574, width: 170, height: 75,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: termsList.map((t) => pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 0.5 * scale),
                child: pw.Text(t, style: pw.TextStyle(fontSize: 6.5 * scale)),
              )).toList(),
            ),
          ),

          // Footer Bank details
          _positionedField(
            posX: 218, posY: 562, width: 155, height: 10,
            child: pw.Text(
              "BANK DETAIL 8",
              style: pw.TextStyle(fontSize: 8.0 * scale, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF499F34)),
            ),
          ),
          _bankItemRow("Aooount Name", bankAccountName.toString(), 574),
          _bankItemRow("Bank Name", bankName.toString(), 585),
          _bankItemRow("Aooount No.", bankAccountNo.toString(), 596),
          _bankItemRow("IFSC Code", bankIfsc.toString(), 607),

          // Footer Signatory
          _positionedField(
            posX: 388, posY: 562, width: 185, height: 10,
            child: pw.Text(
              "FOR $cName",
              style: pw.TextStyle(fontSize: 7.5 * scale, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0B3B60)),
              textAlign: pw.TextAlign.center,
            ),
          ),
          _positionedField(
            posX: 388, posY: 574, width: 185, height: 20,
            child: pw.Text(
              "This is a computer-generated invoice.\nSubject to applicable laws of India.",
              style: pw.TextStyle(fontSize: 6.0 * scale, color: PdfColor.fromInt(0xFF555555)),
              textAlign: pw.TextAlign.center,
            ),
          ),

          if (sigImage != null)
            _positionedField(
              posX: TourismLayoutConfig.sigBoxX,
              posY: TourismLayoutConfig.sigBoxY,
              width: TourismLayoutConfig.sigBoxWidth,
              height: TourismLayoutConfig.sigBoxHeight,
              child: pw.Image(sigImage),
            )
          else
            _positionedField(
              posX: TourismLayoutConfig.sigBoxX,
              posY: TourismLayoutConfig.sigBoxY,
              width: TourismLayoutConfig.sigBoxWidth,
              height: TourismLayoutConfig.sigBoxHeight,
              child: pw.Center(
                child: pw.Text(
                  "Abhishek Prajapati",
                  style: pw.TextStyle(
                    font: pw.Font.timesItalic(),
                    fontSize: 11 * scale,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1D4ED8),
                  ),
                ),
              ),
            ),

          _positionedField(
            posX: 388, posY: 648, width: 185, height: 10,
            child: pw.Text(
              signatoryTitle.toString().toUpperCase(),
              style: pw.TextStyle(fontSize: 7.0 * scale, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0B3B60)),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _fieldRow(String label, String value, double scale, {double labelWidth = 75}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: labelWidth * scale,
            child: pw.Text(
              "$label :",
              style: pw.TextStyle(fontSize: 7 * scale, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 7 * scale),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _dottedFieldRow(String label, String value, double scale, {double labelWidth = 75, bool isLast = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: labelWidth * scale,
                child: pw.Text(
                  "$label :",
                  style: pw.TextStyle(fontSize: 7 * scale, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  value,
                  style: pw.TextStyle(fontSize: 7 * scale),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          pw.Container(
            height: 0.5,
            margin: const pw.EdgeInsets.only(bottom: 2),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, style: pw.BorderStyle.dashed, width: 0.5),
              ),
            ),
          ),
      ],
    );
  }

  static pw.TableRow _totalTableRow(String label, String value, double scale, {bool isBold = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 6.5 * scale,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: pw.Text(
            "Rs. " + value,
            style: pw.TextStyle(
              fontSize: 6.5 * scale,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // --- Dynamic Section Layout Builders ---

  static pw.Widget _buildCompanyDetailsHeader(
    SectionSchema sec,
    pw.ImageProvider? logoImage,
    Invoice invoice,
    CompanyProfile company,
    double scale,
    DateFormat df,
  ) {
    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final deepBlue = PdfColor.fromInt(0xFF0B3B60);
    final accentOrange = PdfColor.fromInt(0xFFE57A25);

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 12 * scale),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Company Profile Info
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  company.name.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: pw.FontWeight.bold,
                    color: deepBlue,
                  ),
                ),
                pw.Text(
                  "TOURS & TRAVELS | CAR RENTAL | TRANSPORT SOLUTIONS",
                  style: pw.TextStyle(
                    fontSize: 7 * scale,
                    fontWeight: pw.FontWeight.bold,
                    color: accentOrange,
                  ),
                ),
                pw.SizedBox(height: 6 * scale),
                pw.Text("Ph: ${company.contactNumber}", style: pw.TextStyle(fontSize: 8 * scale)),
                pw.Text("Email: ${company.email}", style: pw.TextStyle(fontSize: 8 * scale)),
                pw.Text("Office Address: ${company.address}", style: pw.TextStyle(fontSize: 8 * scale)),
              ],
            ),
          ),
          
          // Middle: Logo
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              children: [
                if (logoImage != null)
                  pw.Image(logoImage, height: 35 * scale)
                else
                  pw.Container(
                    height: 35 * scale,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Text(
                      company.name.isNotEmpty ? company.name[0] : 'L',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryGreen, fontSize: 12 * scale),
                    ),
                  ),
                pw.SizedBox(height: 2),
                pw.Text(
                  "LN TOURISM",
                  style: pw.TextStyle(fontSize: 7 * scale, fontWeight: pw.FontWeight.bold, color: deepBlue),
                ),
              ],
            ),
          ),

          // Right: Green Header box
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
                        _invMetaRow("Invoice No.", invoice.invoiceNumber, scale),
                        _invMetaRow("Invoice Date", df.format(invoice.invoiceDate), scale),
                        _invMetaRow("GSTIN", company.gstNumber, scale),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerDetailsBlock(
    SectionSchema sec,
    Map<String, dynamic> values,
    double scale,
  ) {
    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final deepBlue = PdfColor.fromInt(0xFF0B3B60);

    final visibleFields = sec.fields.where((f) => f.isVisible).toList();

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 8 * scale),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            sec.title.toUpperCase(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8 * scale, color: deepBlue),
          ),
          pw.Container(height: 1, color: primaryGreen, margin: pw.EdgeInsets.only(top: 1, bottom: 4 * scale)),
          pw.Wrap(
            spacing: 12 * scale,
            runSpacing: 2 * scale,
            children: visibleFields.map((f) {
              final rawVal = values[f.id];
              final valStr = rawVal != null ? _formatValue(rawVal, f.valueType) : '';
              final color = _parseColor(f.textColor);

              return pw.Container(
                width: 140 * scale,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${f.label}: ",
                      style: pw.TextStyle(fontSize: (f.fontSize - 1) * scale, fontWeight: pw.FontWeight.bold, color: color),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        valStr,
                        style: pw.TextStyle(
                          fontSize: (f.fontSize - 1) * scale,
                          fontWeight: f.fontWeight == 'bold' ? pw.FontWeight.bold : pw.FontWeight.normal,
                          color: color,
                        ),
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
    SectionSchema sec,
    Map<String, dynamic> values,
    double scale,
    DateFormat df,
  ) {
    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final deepBlue = PdfColor.fromInt(0xFF0B3B60);

    final visibleFields = sec.fields.where((f) => f.isVisible).toList();

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 10 * scale),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            sec.title.toUpperCase(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8 * scale, color: deepBlue),
          ),
          pw.Container(height: 1, color: primaryGreen, margin: pw.EdgeInsets.only(top: 1, bottom: 4 * scale)),
          pw.Wrap(
            spacing: 16 * scale,
            runSpacing: 3 * scale,
            children: visibleFields.map((f) {
              final rawVal = values[f.id];
              final valStr = rawVal != null ? _formatValue(rawVal, f.valueType) : '';
              final color = _parseColor(f.textColor);

              return pw.Container(
                width: 160 * scale,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${f.label}: ",
                      style: pw.TextStyle(fontSize: (f.fontSize - 1) * scale, fontWeight: pw.FontWeight.bold, color: color),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        valStr,
                        style: pw.TextStyle(
                          fontSize: (f.fontSize - 1) * scale,
                          fontWeight: f.fontWeight == 'bold' ? pw.FontWeight.bold : pw.FontWeight.normal,
                          color: color,
                        ),
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
    String templateType,
    List<InvoiceItem> items,
    double scale,
    DateFormat df,
    NumberFormat simpleCurrencyFmt,
  ) {
    final primaryGreen = PdfColor.fromInt(0xFF499F34);

    final isTourism = templateType == 'tourism';
    final isTransport = templateType == 'transport';

    // Map columns depending on template layout
    List<String> headers;
    Map<int, pw.TableColumnWidth> columnWidths;

    if (isTourism) {
      headers = ["S No.", "Description of Service", "Vehicles", "Date", "Route / From-To", "Days", "Rate (Rs.)", "Amt (Rs.)"];
      columnWidths = {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(40),
        3: const pw.FixedColumnWidth(45),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FixedColumnWidth(35),
        6: const pw.FixedColumnWidth(45),
        7: const pw.FixedColumnWidth(50),
      };
    } else if (isTransport) {
      headers = ["S No.", "Service Description", "Vehicle No", "Delivery Date", "Route", "Qty", "Rate (Rs.)", "Amt (Rs.)"];
      columnWidths = {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(55),
        3: const pw.FixedColumnWidth(45),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FixedColumnWidth(35),
        6: const pw.FixedColumnWidth(45),
        7: const pw.FixedColumnWidth(50),
      };
    } else {
      // Standard / Service
      headers = ["S No.", "Description of Goods / Services", "Qty", "Rate (Rs.)", "Amt (Rs.)"];
      columnWidths = {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(60),
        4: const pw.FixedColumnWidth(70),
      };
    }

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 8 * scale),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
        columnWidths: columnWidths,
        children: [
          // Table Header
          pw.TableRow(
            decoration: pw.BoxDecoration(color: primaryGreen),
            children: headers.map((h) => _cellHeader(h, scale)).toList(),
          ),
          
          // Table Body (Only display rows containing actual data, no empty filler rows)
          ...List.generate(
            items.length,
            (index) {
              final item = items[index];
              if (isTourism) {
                return pw.TableRow(
                  children: [
                    _cellBody((index + 1).toString(), scale, align: pw.TextAlign.center),
                    _cellBody(item.description, scale),
                    _cellBody(item.noOfVehicles?.toString() ?? '1', scale, align: pw.TextAlign.center),
                    _cellBody(item.itemDate != null ? df.format(item.itemDate!) : '', scale, align: pw.TextAlign.center),
                    _cellBody(item.fromTo ?? '', scale),
                    _cellBody(item.quantityDays.toString(), scale, align: pw.TextAlign.center),
                    _cellBody(simpleCurrencyFmt.format(item.rate), scale, align: pw.TextAlign.right),
                    _cellBody(simpleCurrencyFmt.format(item.amount), scale, align: pw.TextAlign.right),
                  ],
                );
              } else if (isTransport) {
                return pw.TableRow(
                  children: [
                    _cellBody((index + 1).toString(), scale, align: pw.TextAlign.center),
                    _cellBody(item.description, scale),
                    _cellBody(item.noOfVehicles?.toString() ?? '', scale, align: pw.TextAlign.center), // Vehicle count maps to NoOfVehicles column mapping
                    _cellBody(item.itemDate != null ? df.format(item.itemDate!) : '', scale, align: pw.TextAlign.center),
                    _cellBody(item.fromTo ?? '', scale),
                    _cellBody(item.quantityDays.toString(), scale, align: pw.TextAlign.center),
                    _cellBody(simpleCurrencyFmt.format(item.rate), scale, align: pw.TextAlign.right),
                    _cellBody(simpleCurrencyFmt.format(item.amount), scale, align: pw.TextAlign.right),
                  ],
                );
              } else {
                return pw.TableRow(
                  children: [
                    _cellBody((index + 1).toString(), scale, align: pw.TextAlign.center),
                    _cellBody(item.description, scale),
                    _cellBody(item.quantityDays.toString(), scale, align: pw.TextAlign.center),
                    _cellBody(simpleCurrencyFmt.format(item.rate), scale, align: pw.TextAlign.right),
                    _cellBody(simpleCurrencyFmt.format(item.amount), scale, align: pw.TextAlign.right),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTaxSummaryBlock(
    Invoice invoice,
    double scale,
    NumberFormat simpleCurrencyFmt,
    NumberFormat currencyFmt,
  ) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 6 * scale),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 180 * scale,
            child: pw.Column(
              children: [
                _totalRow("Sub Total", simpleCurrencyFmt.format(invoice.subTotal), scale),
                _totalRow("CGST", simpleCurrencyFmt.format(invoice.cgst), scale),
                _totalRow("SGST", simpleCurrencyFmt.format(invoice.sgst), scale),
                
                // Total Amount Box
                pw.Container(
                  color: PdfColors.black,
                  padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3 * scale),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Total Amount",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8 * scale),
                      ),
                      pw.Text(
                        currencyFmt.format(invoice.grandTotal),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8 * scale),
                      ),
                    ],
                  ),
                ),
                
                _totalRow("Advance Paid", simpleCurrencyFmt.format(invoice.advancePaid), scale),
                pw.Container(height: 0.5, color: PdfColors.black),
                _totalRow("Amount To Be Paid", simpleCurrencyFmt.format(invoice.grandTotal - invoice.advancePaid), scale, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentInfoBlock(
    SectionSchema sec,
    CompanyProfile company,
    Invoice invoice,
    double scale,
    NumberFormat simpleCurrencyFmt,
    NumberFormat currencyFmt,
  ) {
    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final deepBlue = PdfColor.fromInt(0xFF0B3B60);

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 8 * scale),
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
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7 * scale, color: deepBlue),
                ),
                pw.SizedBox(height: 4 * scale),
                _bankItem("Account Name", company.bankAccountName, scale),
                _bankItem("Bank Name", company.bankName, scale),
                _bankItem("Account No", company.bankAccountNumber, scale),
                _bankItem("IFSC Code", company.bankIfscCode, scale),
                pw.SizedBox(height: 6 * scale),
                pw.Text(
                  "Amount to be paid in words: ${invoice.amountPaidInWords}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7 * scale),
                ),
              ],
            ),
          ),
          
          // Right: Dynamic QR Code and Barcode (satisfying visual layout designer options)
          pw.Expanded(
            flex: 1,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // QR code representing payment details
                pw.Container(
                  height: 45 * scale,
                  width: 45 * scale,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'upi://pay?pa=lntourism@okaxis&pn=LN%20Tourism&am=${invoice.grandTotal - invoice.advancePaid}&cu=INR',
                  ),
                ),
                pw.SizedBox(width: 8 * scale),
                // Barcode representing Invoice ID
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

  static pw.Widget _buildTermsConditionsBlock(SectionSchema sec, double scale) {
    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final deepBlue = PdfColor.fromInt(0xFF0B3B60);

    final field = sec.fields.firstWhere((f) => f.id == 'terms_text', orElse: () => FieldSchema(id: 'terms_text', label: 'Terms', valueType: 'text'));
    final termsString = field.defaultValue?.toString() ?? '1. Subject to local jurisdiction.\n2. E&OE.';
    final termsList = termsString.split('\n');

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 8 * scale),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 1, color: primaryGreen),
          pw.SizedBox(height: 2),
          pw.Text(
            sec.title.toUpperCase(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7 * scale, color: deepBlue),
          ),
          pw.SizedBox(height: 4 * scale),
          ...termsList.map((term) => _termItem(term, scale)).toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureBlock(
    SectionSchema sec,
    CompanyProfile company,
    pw.ImageProvider? sigImage,
    double scale,
  ) {
    final primaryGreen = PdfColor.fromInt(0xFF499F34);
    final deepBlue = PdfColor.fromInt(0xFF0B3B60);

    final field = sec.fields.firstWhere((f) => f.id == 'signatory_title', orElse: () => FieldSchema(id: 'signatory_title', label: 'Title', valueType: 'text'));
    final title = field.defaultValue?.toString() ?? 'AUTHORIZED SIGNATORY';

    return pw.Container(
      margin: pw.EdgeInsets.only(top: 8 * scale),
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
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7 * scale, color: deepBlue),
                ),
                pw.SizedBox(height: 2),
                
                // Signature image
                pw.Container(
                  height: 25 * scale,
                  alignment: pw.Alignment.bottomCenter,
                  child: sigImage != null
                      ? pw.Image(sigImage, height: 22 * scale)
                      : pw.Text(
                          company.name.split(' ').first,
                          style: pw.TextStyle(
                            fontSize: 9 * scale,
                            fontWeight: pw.FontWeight.bold,
                            fontStyle: pw.FontStyle.italic,
                            color: deepBlue,
                          ),
                        ),
                ),
                pw.Container(height: 0.5, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(vertical: 2)),
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6 * scale, color: deepBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Static Formatter / Colors Helpers ---

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
              style: pw.TextStyle(fontSize: 6 * scale, fontWeight: pw.FontWeight.bold, color: deepBlue),
            ),
          ),
          pw.Text(
            ":  $value",
            style: pw.TextStyle(fontSize: 6 * scale),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cellHeader(String text, double scale) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 6.5 * scale),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _cellBody(String text, double scale, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 6.5 * scale),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, double scale, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 7 * scale, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 7 * scale, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ],
      ),
    );
  }

  static pw.Widget _termItem(String text, double scale) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 5.5 * scale),
      ),
    );
  }

  static pw.Widget _bankItem(String label, String value, double scale) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Container(
            width: 50 * scale,
            child: pw.Text(
              "$label:",
              style: pw.TextStyle(fontSize: 5.5 * scale, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 5.5 * scale),
          ),
        ],
      ),
    );
  }
}
