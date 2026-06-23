import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../models/tourism_layout_config.dart';

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

  const TourismInvoicePreviewWidget({
    super.key,
    required this.invoice,
    required this.items,
    required this.company,
    required this.fieldValues,
    this.scale = 1.0,
    this.isDesigner = false,
    this.selectedSectionId,
    this.selectedFieldId,
    this.onTapField,
  });

  @override
  Widget build(BuildContext context) {
    final double width = TourismLayoutConfig.pageWidth * scale;

    final double tableHeaderHeight = 20.0;
    final double tableRowHeight = 20.0;
    final double tableHeight = tableHeaderHeight + (items.length * tableRowHeight);

    final double totalsBoxY = 275.0 + tableHeight + 10.0;
    final double wordsBoxY = totalsBoxY + 90.0 + 10.0;
    final double footerTopLineY = wordsBoxY + 20.0 + 10.0;
    final double footerBottomLineY = footerTopLineY + 125.0;
    final double sigUnderlineY = footerTopLineY + 87.0; // 642.0 - 555.0 = 87.0
    final double sigBoxY = footerTopLineY + 43.0; // 598.0 - 555.0 = 43.0
    final double height = (footerBottomLineY + 30.0) * scale;

    // Formatting helpers
    final df = DateFormat('dd/MM/yyyy');
    final simpleCurrencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);

    // Resolve field values
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
                    totalsBoxY: totalsBoxY,
                    wordsBoxY: wordsBoxY,
                    footerTopLineY: footerTopLineY,
                    footerBottomLineY: footerBottomLineY,
                    sigUnderlineY: sigUnderlineY,
                  ),
                ),
              ),

              // 2. Company details Left
              _positionedField(
                id: 'company_name',
                sectionId: 'company_details',
                posX: 22, posY: 32, width: 230, height: 16,
                child: Text(
                  cName,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B3B60),
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
              _positionedField(
                id: 'company_tagline',
                sectionId: 'company_details',
                posX: 22, posY: 46, width: 230, height: 10,
                child: Text(
                  tagline,
                  style: TextStyle(
                    fontSize: 6.5 * scale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE57A25),
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
              _positionedField(
                id: 'company_phone',
                sectionId: 'company_details',
                posX: 22, posY: 78, width: 230, height: 10,
                child: Text(
                  "Ph: $phone",
                  style: TextStyle(fontSize: 7.5 * scale, fontFamily: 'Times New Roman', color: Colors.black87),
                ),
              ),
              _positionedField(
                id: 'company_email',
                sectionId: 'company_details',
                posX: 22, posY: 88, width: 340, height: 10,
                child: Text(
                  "Email: $email   Web: $web",
                  style: TextStyle(fontSize: 7.5 * scale, fontFamily: 'Times New Roman', color: Colors.black87),
                ),
              ),
              _positionedField(
                id: 'company_address',
                sectionId: 'company_details',
                posX: 22, posY: 98, width: 340, height: 20,
                child: Text(
                  "Office Address : $address",
                  style: TextStyle(fontSize: 7.5 * scale, fontFamily: 'Times New Roman', color: Colors.black87),
                  maxLines: 2,
                ),
              ),

              // Logo Middle
              if (company.logoPath != null && File(company.logoPath!).existsSync())
                Positioned(
                  left: TourismLayoutConfig.logoX * scale,
                  top: TourismLayoutConfig.logoY * scale,
                  width: TourismLayoutConfig.logoWidth * scale,
                  height: TourismLayoutConfig.logoHeight * scale,
                  child: Image.file(
                    File(company.logoPath!),
                    fit: BoxFit.contain,
                  ),
                )
              else
                Positioned(
                  left: TourismLayoutConfig.logoX * scale,
                  top: TourismLayoutConfig.logoY * scale,
                  width: TourismLayoutConfig.logoWidth * scale,
                  height: TourismLayoutConfig.logoHeight * scale,
                  child: Container(
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
              Positioned(
                left: (TourismLayoutConfig.invBoxX + 2) * scale,
                top: (TourismLayoutConfig.invBoxY + 4) * scale,
                width: (TourismLayoutConfig.invBoxWidth - 4) * scale,
                height: (TourismLayoutConfig.invBoxHeaderHeight - 4) * scale,
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

              // Invoice Info fields
              _invoiceInfoRow("Invoice No.", invoiceNo.toString(), 62, 'invoice_number'),
              _invoiceInfoRow("Invoice Date", invoiceDate.toString(), 73, 'invoice_date'),
              _invoiceInfoRow("Booking Ref.", bookingRef.toString(), 84, 'booking_ref'),
              _invoiceInfoRow("Booking Date", bookingDate.toString(), 95, 'booking_date'),
              _invoiceInfoRow("PAN No.", companyPan.toString(), 106, 'company_pan', isBold: true),
              _invoiceInfoRow("GSTIN", companyGstIn.toString(), 117, 'company_gst_in', isBold: true),

              // BILL TO column
              _positionedField(
                id: 'customer_details_title',
                sectionId: 'customer_details',
                posX: 22, posY: 154, width: 100, height: 12,
                child: Text(
                  "BILL TO",
                  style: TextStyle(fontSize: 8 * scale, fontWeight: FontWeight.bold, color: const Color(0xFF499F34), fontFamily: 'Times New Roman'),
                ),
              ),
              _dottedFieldRow("Name / Company", customerName.toString(), 172, 'customer_name', 'customer_details'),
              _dottedFieldRow("Address", customerAddress.toString(), 186, 'customer_address', 'customer_details'),
              _dottedFieldRow("City / State / PIN", customerCityStatePin.toString(), 200, 'customer_city_state_pin', 'customer_details'),
              _dottedFieldRow("GSTIN", customerGst.toString(), 214, 'customer_gst', 'customer_details'),
              _dottedFieldRow("Contact No.", customerPhone.toString(), 228, 'customer_phone', 'customer_details'),

              // SERVICE DETAIL column
              _positionedField(
                id: 'service_details_title',
                sectionId: 'service_details',
                posX: 300, posY: 154, width: 150, height: 12,
                child: Text(
                  "SERVICE DETAIL 8",
                  style: TextStyle(fontSize: 8 * scale, fontWeight: FontWeight.bold, color: const Color(0xFF499F34), fontFamily: 'Times New Roman'),
                ),
              ),
              _dottedFieldRow("Tour / Trip", tourTrip.toString(), 172, 'tour_trip', 'service_details', isRightCol: true),
              _dottedFieldRow("Travel Date", travelDate.toString(), 186, 'travel_date', 'service_details', isRightCol: true),
              _dottedFieldRow("No. of Days", noOfDays.toString(), 200, 'no_of_days', 'service_details', isRightCol: true),
              _dottedFieldRow("No. of Vehicles", noOfVehicles.toString(), 214, 'no_of_vehicles', 'service_details', isRightCol: true),
              _dottedFieldRow("Co-ordinator Name", coordinatorName.toString(), 228, 'coordinator_name', 'service_details', isRightCol: true),

              // 3. Service Table
              Positioned(
                left: TourismLayoutConfig.leftMargin * scale,
                top: TourismLayoutConfig.tableStartY * scale,
                width: TourismLayoutConfig.contentWidth * scale,
                child: Table(
                  border: TableBorder.all(color: Colors.black, width: 0.8 * scale),
                  columnWidths: Map.fromIterables(
                    Iterable<int>.generate(TourismLayoutConfig.tableColumnWidths.length),
                    TourismLayoutConfig.tableColumnWidths.map((w) => FixedColumnWidth(w * scale)),
                  ),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFF499F34)),
                      children: TourismLayoutConfig.tableColumnLabels.map((lbl) => Container(
                        height: 20.0 * scale,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 1 * scale),
                        child: Text(
                          lbl,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 7.5 * scale, fontFamily: 'Times New Roman'),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                    ),
                    ...List.generate(items.length, (idx) {
                      final item = items[idx];
                      final itemDateStr = item.itemDate != null ? df.format(item.itemDate!) : '';
                      return TableRow(
                        children: [
                          _cellBody((idx + 1).toString(), align: TextAlign.center),
                          _cellBody(item.description),
                          _cellBody(item.noOfVehicles?.toString() ?? '1', align: TextAlign.center),
                          _cellBody(itemDateStr, align: TextAlign.center),
                          _cellBody(item.fromTo ?? ''),
                          _cellBody(item.quantityDays.toStringAsFixed(item.quantityDays % 1 == 0 ? 0 : 1), align: TextAlign.center),
                          _cellBody(simpleCurrencyFmt.format(item.rate), align: TextAlign.right),
                          _cellBody(simpleCurrencyFmt.format(item.amount), align: TextAlign.right),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              // 4. Totals Block (Right side)
              _totalsRow(totalsBoxY, "Sub Total", simpleCurrencyFmt.format(invoice.subTotal), 0, 'tax_summary'),
              _totalsRow(totalsBoxY, "CGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%", simpleCurrencyFmt.format(invoice.cgst), 1, 'tax_summary'),
              _totalsRow(totalsBoxY, "SGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%", simpleCurrencyFmt.format(invoice.sgst), 2, 'tax_summary'),
              _totalsRow(totalsBoxY, "Total Amount", simpleCurrencyFmt.format(invoice.grandTotal), 3, 'tax_summary', isTotalAmount: true),
              _totalsRow(totalsBoxY, "Advance Payment Received", simpleCurrencyFmt.format(invoice.advancePaid), 4, 'tax_summary'),
              _totalsRow(totalsBoxY, "Amount To Be Paid", simpleCurrencyFmt.format(invoice.grandTotal - invoice.advancePaid), 5, 'tax_summary', isBold: true),

              // Amount in words box (Left side, full width)
              _positionedField(
                id: 'amount_paid_in_words',
                sectionId: 'tax_summary',
                posX: TourismLayoutConfig.wordsBoxX,
                posY: wordsBoxY,
                width: TourismLayoutConfig.wordsBoxWidth,
                height: TourismLayoutConfig.wordsBoxHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 4 * scale),
                  child: Text(
                    "Amount to be paid in words : ${invoice.amountPaidInWords.endsWith(' Only') ? '${invoice.amountPaidInWords}.' : (invoice.amountPaidInWords.endsWith(' Only.') ? invoice.amountPaidInWords : '${invoice.amountPaidInWords} Only.')}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8.0 * scale, fontFamily: 'Times New Roman', color: Colors.black),
                  ),
                ),
              ),

              // 5. Footer Section
              // Column 1: Terms
              _positionedField(
                id: 'terms_title',
                sectionId: 'terms_conditions',
                posX: 28, posY: footerTopLineY + 7.0, width: 170, height: 10,
                child: Text(
                  "TERM & CONDITION 8",
                  style: TextStyle(fontSize: 8.0 * scale, fontWeight: FontWeight.bold, color: const Color(0xFF499F34), fontFamily: 'Times New Roman'),
                ),
              ),
              _positionedField(
                id: 'terms_text',
                sectionId: 'terms_conditions',
                posX: 28, posY: footerTopLineY + 19.0, width: 170, height: 75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: termsList.map((t) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 0.5 * scale),
                    child: Text(t, style: TextStyle(fontSize: 6.5 * scale, fontFamily: 'Times New Roman', color: Colors.black87)),
                  )).toList(),
                ),
              ),

              // Column 2: Bank details
              _positionedField(
                id: 'bank_title',
                sectionId: 'payment_info',
                posX: 218, posY: footerTopLineY + 7.0, width: 155, height: 10,
                child: Text(
                  "BANK DETAIL 8",
                  style: TextStyle(fontSize: 8.0 * scale, fontWeight: FontWeight.bold, color: const Color(0xFF499F34), fontFamily: 'Times New Roman'),
                ),
              ),
              _bankItemRow("Aooount Name", bankAccountName.toString(), footerTopLineY + 19.0, 'bank_account_name'),
              _bankItemRow("Bank Name", bankName.toString(), footerTopLineY + 30.0, 'bank_name'),
              _bankItemRow("Aooount No.", bankAccountNo.toString(), footerTopLineY + 41.0, 'bank_account_no'),
              _bankItemRow("IFSC Code", bankIfsc.toString(), footerTopLineY + 52.0, 'bank_ifsc'),

              // Column 3: Signatory
              _positionedField(
                id: 'signatory_company',
                sectionId: 'signature',
                posX: 388, posY: footerTopLineY + 7.0, width: 185, height: 10,
                child: Text(
                  "FOR $cName",
                  style: TextStyle(fontSize: 7.5 * scale, fontWeight: FontWeight.bold, color: const Color(0xFF0B3B60), fontFamily: 'Times New Roman'),
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                left: 388 * scale,
                top: (footerTopLineY + 19.0) * scale,
                width: 185 * scale,
                child: Text(
                  "This is a computer-generated invoice.\nSubject to applicable laws of India.",
                  style: TextStyle(fontSize: 6.0 * scale, color: Colors.grey.shade600, fontFamily: 'Times New Roman'),
                  textAlign: TextAlign.center,
                ),
              ),

              // Signature Image Box
              if (company.signaturePath != null && File(company.signaturePath!).existsSync())
                Positioned(
                  left: TourismLayoutConfig.sigBoxX * scale,
                  top: sigBoxY * scale,
                  width: TourismLayoutConfig.sigBoxWidth * scale,
                  height: TourismLayoutConfig.sigBoxHeight * scale,
                  child: Image.file(
                    File(company.signaturePath!),
                    fit: BoxFit.contain,
                  ),
                )
              else
                _positionedField(
                  id: 'signature_fallback',
                  sectionId: 'signature',
                  posX: TourismLayoutConfig.sigBoxX,
                  posY: sigBoxY,
                  width: TourismLayoutConfig.sigBoxWidth,
                  height: TourismLayoutConfig.sigBoxHeight,
                  child: Center(
                    child: Text(
                      "Abhishek Prajapati",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ),
                ),

              _positionedField(
                id: 'signatory_title',
                sectionId: 'signature',
                posX: 388, posY: footerTopLineY + 93.0, width: 185, height: 10,
                child: Text(
                  signatoryTitle.toString().toUpperCase(),
                  style: TextStyle(fontSize: 7.0 * scale, fontWeight: FontWeight.bold, color: const Color(0xFF0B3B60), fontFamily: 'Times New Roman'),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers for modular rendering ---

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

  Widget _invoiceInfoRow(String label, String value, double posY, String id, {bool isBold = false}) {
    return Positioned(
      left: (TourismLayoutConfig.invBoxX + 6) * scale,
      top: posY * scale,
      width: (TourismLayoutConfig.invBoxWidth - 12) * scale,
      height: 10 * scale,
      child: GestureDetector(
        onTap: onTapField != null ? () => onTapField!('invoice_info', id) : null,
        child: Container(
          decoration: isDesigner && selectedFieldId == id
              ? BoxDecoration(border: Border.all(color: AppTheme.primaryGreen), color: AppTheme.primaryGreen.withOpacity(0.06))
              : null,
          child: Row(
            children: [
              SizedBox(
                width: 60 * scale,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 7.5 * scale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B3B60),
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
              Text(
                ":  $value",
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
  }

  Widget _dottedFieldRow(String label, String value, double posY, String id, String sectionId, {bool isRightCol = false}) {
    final double left = (isRightCol ? 300 : 22);
    final double width = (isRightCol ? 273.27 : 263);

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
                  style: TextStyle(fontSize: 8.0 * scale, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Times New Roman'),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 8.0 * scale, color: Colors.black, fontFamily: 'Times New Roman'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _totalsRow(double totalsBoxY, String label, String value, int rowIndex, String sectionId, {bool isBold = false, bool isTotalAmount = false}) {
    final double top = totalsBoxY + (rowIndex * TourismLayoutConfig.totalsRowHeight);
    
    return Positioned(
      left: TourismLayoutConfig.totalsBoxX * scale,
      top: top * scale,
      width: TourismLayoutConfig.totalsBoxWidth * scale,
      height: TourismLayoutConfig.totalsRowHeight * scale,
      child: Container(
        color: isTotalAmount ? Colors.black : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 3 * scale),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 7.5 * scale,
                fontWeight: (isBold || isTotalAmount) ? FontWeight.bold : FontWeight.normal,
                color: isTotalAmount ? Colors.white : Colors.black87,
                fontFamily: 'Times New Roman',
              ),
            ),
            Text(
              "Rs. $value",
              style: TextStyle(
                fontSize: 7.5 * scale,
                fontWeight: (isBold || isTotalAmount) ? FontWeight.bold : FontWeight.normal,
                color: isTotalAmount ? Colors.white : Colors.black87,
                fontFamily: 'Times New Roman',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankItemRow(String label, String value, double posY, String id) {
    return Positioned(
      left: 218 * scale,
      top: posY * scale,
      width: 155 * scale,
      height: 10 * scale,
      child: GestureDetector(
        onTap: onTapField != null ? () => onTapField!('payment_info', id) : null,
        child: Container(
          decoration: isDesigner && selectedFieldId == id
              ? BoxDecoration(border: Border.all(color: AppTheme.primaryGreen), color: AppTheme.primaryGreen.withOpacity(0.06))
              : null,
          child: Row(
            children: [
              SizedBox(
                width: 62 * scale,
                child: Text(
                  "$label:",
                  style: TextStyle(fontSize: 7.5 * scale, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Times New Roman'),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 7.5 * scale, color: Colors.black87, fontFamily: 'Times New Roman'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cellBody(String text, {TextAlign align = TextAlign.left}) {
    return Container(
      height: 20.0 * scale,
      alignment: align == TextAlign.center
          ? Alignment.center
          : (align == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
      padding: EdgeInsets.symmetric(horizontal: 4 * scale),
      child: Text(
        text,
        style: TextStyle(fontSize: 7.5 * scale, color: Colors.black87, fontFamily: 'Times New Roman'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
}

class TourismInvoiceBackgroundPainter extends CustomPainter {
  final double scale;
  final double totalsBoxY;
  final double wordsBoxY;
  final double footerTopLineY;
  final double footerBottomLineY;
  final double sigUnderlineY;

  TourismInvoiceBackgroundPainter({
    required this.scale,
    required this.totalsBoxY,
    required this.wordsBoxY,
    required this.footerTopLineY,
    required this.footerBottomLineY,
    required this.sigUnderlineY,
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

    void drawDotLine(double x1, double y1, double x2, double y2, Paint paint) {
      const double dotSpace = 2.0;
      double dx = x2 - x1;
      if (dx != 0) {
        double currentX = x1;
        while (currentX < x2) {
          canvas.drawCircle(Offset(currentX, y1), 0.4 * scale, paint);
          currentX += dotSpace * scale;
        }
      }
    }

    // 1. Header dashed borders
    drawDashLine(
      TourismLayoutConfig.leftMargin * scale,
      TourismLayoutConfig.headerTopLineY * scale,
      (TourismLayoutConfig.pageWidth - TourismLayoutConfig.rightMargin) * scale,
      TourismLayoutConfig.headerTopLineY * scale,
      dashPaint,
    );
    drawDashLine(
      TourismLayoutConfig.leftMargin * scale,
      TourismLayoutConfig.headerBottomLineY * scale,
      (TourismLayoutConfig.pageWidth - TourismLayoutConfig.rightMargin) * scale,
      TourismLayoutConfig.headerBottomLineY * scale,
      dashPaint,
    );

    // Green Divider
    canvas.drawLine(
      Offset(TourismLayoutConfig.headerDividerX * scale, TourismLayoutConfig.headerTopLineY * scale),
      Offset(TourismLayoutConfig.headerDividerX * scale, TourismLayoutConfig.headerBottomLineY * scale),
      solidGreen..strokeWidth = 1.2 * scale,
    );

    // Invoice Box green border
    final Rect invBoxRect = Rect.fromLTWH(
      TourismLayoutConfig.invBoxX * scale,
      TourismLayoutConfig.invBoxY * scale,
      TourismLayoutConfig.invBoxWidth * scale,
      TourismLayoutConfig.invBoxHeight * scale,
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
      TourismLayoutConfig.invBoxX * scale,
      TourismLayoutConfig.invBoxY * scale,
      TourismLayoutConfig.invBoxWidth * scale,
      TourismLayoutConfig.invBoxHeaderHeight * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        invHeaderRect,
        topLeft: Radius.circular(3 * scale),
        topRight: Radius.circular(3 * scale),
      ),
      fillPaint,
    );

    // 2. Bill To Area Top/Bottom dashed lines
    drawDashLine(
      TourismLayoutConfig.leftMargin * scale,
      TourismLayoutConfig.billToTopLineY * scale,
      (TourismLayoutConfig.pageWidth - TourismLayoutConfig.rightMargin) * scale,
      TourismLayoutConfig.billToTopLineY * scale,
      solidBlack,
    );
    drawDashLine(
      TourismLayoutConfig.leftMargin * scale,
      TourismLayoutConfig.billToBottomLineY * scale,
      (TourismLayoutConfig.pageWidth - TourismLayoutConfig.rightMargin) * scale,
      TourismLayoutConfig.billToBottomLineY * scale,
      solidBlack,
    );

    // Column Underlines
    canvas.drawLine(
      Offset(TourismLayoutConfig.billToColumnUnderlineX1 * scale, TourismLayoutConfig.billToColumnUnderlineY * scale),
      Offset(TourismLayoutConfig.billToColumnUnderlineX2 * scale, TourismLayoutConfig.billToColumnUnderlineY * scale),
      solidBlack..strokeWidth = 1.0 * scale,
    );
    canvas.drawLine(
      Offset(TourismLayoutConfig.serviceColumnUnderlineX1 * scale, TourismLayoutConfig.serviceColumnUnderlineY * scale),
      Offset(TourismLayoutConfig.serviceColumnUnderlineX2 * scale, TourismLayoutConfig.serviceColumnUnderlineY * scale),
      solidBlack..strokeWidth = 1.0 * scale,
    );

    // Dotted Separators under Bill To fields (Name, Address, City, GSTIN)
    final fieldDotPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 0.5 * scale
      ..style = PaintingStyle.fill;
    for (double y in [184.0, 198.0, 212.0, 226.0]) {
      drawDotLine(
        TourismLayoutConfig.billToColumnUnderlineX1 * scale,
        y * scale,
        TourismLayoutConfig.billToColumnUnderlineX2 * scale,
        y * scale,
        fieldDotPaint,
      );
      drawDotLine(
        TourismLayoutConfig.serviceColumnUnderlineX1 * scale,
        y * scale,
        TourismLayoutConfig.serviceColumnUnderlineX2 * scale,
        y * scale,
        fieldDotPaint,
      );
    }

    // 4. Totals Block Outer Dashed Box
    drawDashLine(
      TourismLayoutConfig.totalsBoxX * scale,
      totalsBoxY * scale,
      (TourismLayoutConfig.totalsBoxX + TourismLayoutConfig.totalsBoxWidth) * scale,
      totalsBoxY * scale,
      solidBlack,
    );
    drawDashLine(
      TourismLayoutConfig.totalsBoxX * scale,
      (totalsBoxY + TourismLayoutConfig.totalsBoxHeight) * scale,
      (TourismLayoutConfig.totalsBoxX + TourismLayoutConfig.totalsBoxWidth) * scale,
      (totalsBoxY + TourismLayoutConfig.totalsBoxHeight) * scale,
      solidBlack,
    );
    drawDashLine(
      TourismLayoutConfig.totalsBoxX * scale,
      totalsBoxY * scale,
      TourismLayoutConfig.totalsBoxX * scale,
      (totalsBoxY + TourismLayoutConfig.totalsBoxHeight) * scale,
      solidBlack,
    );
    drawDashLine(
      (TourismLayoutConfig.totalsBoxX + TourismLayoutConfig.totalsBoxWidth) * scale,
      totalsBoxY * scale,
      (TourismLayoutConfig.totalsBoxX + TourismLayoutConfig.totalsBoxWidth) * scale,
      (totalsBoxY + TourismLayoutConfig.totalsBoxHeight) * scale,
      solidBlack,
    );

    // Totals Box Inside horizontal lines
    for (int i = 1; i < 6; i++) {
      final double y = totalsBoxY + (i * TourismLayoutConfig.totalsRowHeight);
      drawDashLine(
        TourismLayoutConfig.totalsBoxX * scale,
        y * scale,
        (TourismLayoutConfig.totalsBoxX + TourismLayoutConfig.totalsBoxWidth) * scale,
        y * scale,
        dashPaint..strokeWidth = 0.4 * scale,
      );
    }
    // Totals Box Inside vertical divider
    drawDashLine(
      TourismLayoutConfig.totalsBoxDividerX * scale,
      totalsBoxY * scale,
      TourismLayoutConfig.totalsBoxDividerX * scale,
      (totalsBoxY + TourismLayoutConfig.totalsBoxHeight) * scale,
      dashPaint..strokeWidth = 0.4 * scale,
    );

    // 5. Amount in words dashed box
    drawDashLine(
      TourismLayoutConfig.wordsBoxX * scale,
      wordsBoxY * scale,
      (TourismLayoutConfig.wordsBoxX + TourismLayoutConfig.wordsBoxWidth) * scale,
      wordsBoxY * scale,
      solidBlack,
    );
    drawDashLine(
      TourismLayoutConfig.wordsBoxX * scale,
      (wordsBoxY + TourismLayoutConfig.wordsBoxHeight) * scale,
      (TourismLayoutConfig.wordsBoxX + TourismLayoutConfig.wordsBoxWidth) * scale,
      (wordsBoxY + TourismLayoutConfig.wordsBoxHeight) * scale,
      solidBlack,
    );
    drawDashLine(
      TourismLayoutConfig.wordsBoxX * scale,
      wordsBoxY * scale,
      TourismLayoutConfig.wordsBoxX * scale,
      (wordsBoxY + TourismLayoutConfig.wordsBoxHeight) * scale,
      solidBlack,
    );
    drawDashLine(
      (TourismLayoutConfig.wordsBoxX + TourismLayoutConfig.wordsBoxWidth) * scale,
      wordsBoxY * scale,
      (TourismLayoutConfig.wordsBoxX + TourismLayoutConfig.wordsBoxWidth) * scale,
      (wordsBoxY + TourismLayoutConfig.wordsBoxHeight) * scale,
      solidBlack,
    );

    // 6. Footer Section Top/Bottom dashed lines
    drawDashLine(
      TourismLayoutConfig.leftMargin * scale,
      footerTopLineY * scale,
      (TourismLayoutConfig.pageWidth - TourismLayoutConfig.rightMargin) * scale,
      footerTopLineY * scale,
      solidBlack,
    );
    drawDashLine(
      TourismLayoutConfig.leftMargin * scale,
      footerBottomLineY * scale,
      (TourismLayoutConfig.pageWidth - TourismLayoutConfig.rightMargin) * scale,
      footerBottomLineY * scale,
      solidBlack,
    );

    // Footer Columns Green solid dividers
    canvas.drawLine(
      Offset(TourismLayoutConfig.footerDivider1X * scale, footerTopLineY * scale),
      Offset(TourismLayoutConfig.footerDivider1X * scale, footerBottomLineY * scale),
      solidGreen..strokeWidth = 1.0 * scale,
    );
    canvas.drawLine(
      Offset(TourismLayoutConfig.footerDivider2X * scale, footerTopLineY * scale),
      Offset(TourismLayoutConfig.footerDivider2X * scale, footerBottomLineY * scale),
      solidGreen..strokeWidth = 1.0 * scale,
    );

    // Signature label dotted separator
    drawDotLine(
      395 * scale,
      sigUnderlineY * scale,
      566 * scale,
      sigUnderlineY * scale,
      fieldDotPaint..color = Colors.grey.shade500,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
