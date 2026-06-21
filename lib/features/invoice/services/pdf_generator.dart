import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';

class PdfGeneratorService {
  static const PdfColor primaryGreen = PdfColor.fromInt(0xFF499F34);
  static const PdfColor deepBlue = PdfColor.fromInt(0xFF0B3B60);
  static const PdfColor accentOrange = PdfColor.fromInt(0xFFE57A25);

  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required CompanyProfile company,
  }) async {
    final pdf = pw.Document();

    final df = DateFormat('dd/MM/yyyy');
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);
    final simpleCurrencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);

    // Load logo and signature if available
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER ROW
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Side Info
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          company.name.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: deepBlue,
                          ),
                        ),
                        pw.Text(
                          "TOURS & TRAVELS | CAR RENTAL | TRANSPORT SOLUTIONS",
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: accentOrange,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text("Ph: ${company.contactNumber}", style: const pw.TextStyle(fontSize: 8)),
                        pw.Text("Email: ${company.email}", style: const pw.TextStyle(fontSize: 8)),
                        pw.Text("Web: www.lntourism.com", style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(
                          "Office Address: ${company.address}",
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                  
                  // Middle Logo
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      children: [
                        if (logoImage != null)
                          pw.Image(logoImage, height: 40)
                        else
                          pw.Container(
                            height: 40,
                            alignment: pw.Alignment.center,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey300),
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Text(
                              company.name.isNotEmpty ? company.name[0] : 'L',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryGreen),
                            ),
                          ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "LN TOURISM",
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: deepBlue),
                        ),
                      ],
                    ),
                  ),

                  // Right Side Invoice Block (Green header box)
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
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              "INVOICE",
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _invMetaRow("Invoice No.", invoice.invoiceNumber),
                                _invMetaRow("Invoice Date", df.format(invoice.invoiceDate)),
                                _invMetaRow("Booking Ref.", invoice.bookingRef ?? ''),
                                _invMetaRow("Booking Date.", invoice.bookingDate != null ? df.format(invoice.bookingDate!) : ''),
                                _invMetaRow("PAN No.", "AAGCL7813B"),
                                _invMetaRow("GSTIN", company.gstNumber),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
              
              pw.SizedBox(height: 12),

              // BILL TO & SERVICE DETAILS
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Bill To Column
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "BILL TO",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: deepBlue),
                        ),
                        pw.Container(height: 1, color: primaryGreen, margin: const pw.EdgeInsets.only(top: 2, bottom: 4)),
                        _detailRow("Name / Company", invoice.customerName),
                        _detailRow("Address", invoice.customerAddress),
                        _detailRow("City/State/PIN", ""),
                        _detailRow("GSTIN", invoice.customerGstNumber ?? ''),
                        _detailRow("Contact No.", invoice.customerContactNumber ?? ''),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 24),
                  
                  // Service Details Column
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "SERVICE DETAILS",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: deepBlue),
                        ),
                        pw.Container(height: 1, color: primaryGreen, margin: const pw.EdgeInsets.only(top: 2, bottom: 4)),
                        _detailRow("Tour / Trip", invoice.tourTrip ?? ''),
                        _detailRow("Travel Date", invoice.travelDate != null ? df.format(invoice.travelDate!) : ''),
                        _detailRow("No. of Days", invoice.noOfDays != null ? invoice.noOfDays.toString() : ''),
                        _detailRow("No. of Vehicles", invoice.noOfVehicles != null ? invoice.noOfVehicles.toString() : ''),
                        _detailRow("Co-ordinator Name", invoice.coordinatorName ?? ''),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // ITEMS TABLE (Mimicking the image, with green header and padded to at least 5 rows)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: {
                  0: const pw.FixedColumnWidth(25),  // S No
                  1: const pw.FlexColumnWidth(3),   // Description
                  2: const pw.FixedColumnWidth(55),  // No. of Vehicles
                  3: const pw.FixedColumnWidth(45),  // Date
                  4: const pw.FlexColumnWidth(2),   // From-To
                  5: const pw.FixedColumnWidth(45),  // Qty/Days
                  6: const pw.FixedColumnWidth(45),  // Rate (Rs)
                  7: const pw.FixedColumnWidth(50),  // Amt (Rs)
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: primaryGreen),
                    children: [
                      _cellHeader("S No."),
                      _cellHeader("Description of Service"),
                      _cellHeader("No. of Vehicles"),
                      _cellHeader("Date"),
                      _cellHeader("From-To"),
                      _cellHeader("Qty/Days"),
                      _cellHeader("Rate (Rs.)"),
                      _cellHeader("Amt (Rs.)"),
                    ],
                  ),
                  
                  // Table Body
                  ...List.generate(
                    items.length > 5 ? items.length : 5,
                    (index) {
                      if (index < items.length) {
                        final item = items[index];
                        return pw.TableRow(
                          children: [
                            _cellBody((index + 1).toString(), align: pw.TextAlign.center),
                            _cellBody(item.description),
                            _cellBody(item.noOfVehicles?.toString() ?? '', align: pw.TextAlign.center),
                            _cellBody(item.itemDate != null ? df.format(item.itemDate!) : '', align: pw.TextAlign.center),
                            _cellBody(item.fromTo ?? ''),
                            _cellBody(item.quantityDays.toString(), align: pw.TextAlign.center),
                            _cellBody(simpleCurrencyFmt.format(item.rate), align: pw.TextAlign.right),
                            _cellBody(simpleCurrencyFmt.format(item.amount), align: pw.TextAlign.right),
                          ],
                        );
                      } else {
                        // Empty spacer row matching reference layout
                        return pw.TableRow(
                          children: [
                            _cellBody((index + 1).toString(), align: pw.TextAlign.center),
                            _cellBody(''),
                            _cellBody(''),
                            _cellBody(''),
                            _cellBody(''),
                            _cellBody(''),
                            _cellBody(''),
                            _cellBody(''),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              // TOTALS BLOCK
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        _totalRow("Sub Total", simpleCurrencyFmt.format(invoice.subTotal)),
                        _totalRow("CGST @ ${(invoice.totalGst / invoice.subTotal * 50).toStringAsFixed(1)}%", simpleCurrencyFmt.format(invoice.cgst)),
                        _totalRow("SGST @ ${(invoice.totalGst / invoice.subTotal * 50).toStringAsFixed(1)}%", simpleCurrencyFmt.format(invoice.sgst)),
                        
                        // Total Amount Highlight Box (white on black/dark background block)
                        pw.Container(
                          color: PdfColors.black,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "Total Amount",
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                              ),
                              pw.Text(
                                currencyFmt.format(invoice.grandTotal),
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                              ),
                            ],
                          ),
                        ),
                        
                        _totalRow("Advance Payment Received", simpleCurrencyFmt.format(invoice.advancePaid)),
                        
                        pw.Container(height: 1, color: PdfColors.black),
                        _totalRow("Amount To Be Paid", simpleCurrencyFmt.format(invoice.grandTotal - invoice.advancePaid), isBold: true),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              // AMOUNT IN WORDS
              pw.Text(
                "Amount to be paid in words: ${invoice.amountPaidInWords}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              ),

              pw.Spacer(),

              // BOTTOM METADATA PANELS (Terms & Conditions, Bank Details, and Authorized Signatory)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Terms and Conditions Column
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(height: 1.5, color: primaryGreen),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "TERMS & CONDITIONS",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: deepBlue),
                        ),
                        pw.SizedBox(height: 4),
                        _termItem("1. Payment to be made within 7 days from invoice date."),
                        _termItem("2. Extra charges (State Tax, Night Halt, Extra Km) will be charged as per actual."),
                        _termItem("3. Vehicle will be provided as per the itinerary only."),
                        _termItem("4. No refund for unused days or cancellations post journey."),
                        _termItem("5. All disputes are subject to Dehradun jurisdiction only."),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  
                  // Bank Details Column
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(height: 1.5, color: primaryGreen),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "BANK DETAILS",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: deepBlue),
                        ),
                        pw.SizedBox(height: 4),
                        _bankItem("Account Name", company.bankAccountName),
                        _bankItem("Bank Name", company.bankName),
                        _bankItem("Account No", company.bankAccountNumber),
                        _bankItem("IFSC Code", company.bankIfscCode),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),

                  // Signature Column
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(height: 1.5, color: primaryGreen),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "FOR ${company.name.toUpperCase()}",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: deepBlue),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "This is a computer-generated invoice.\nSubject to applicable laws of India.",
                          style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700),
                          textAlign: pw.TextAlign.center,
                        ),
                        
                        // Signature area
                        pw.Container(
                          height: 30,
                          alignment: pw.Alignment.bottomCenter,
                          child: sigImage != null
                              ? pw.Image(sigImage, height: 26)
                              : pw.Text(
                                  company.name.split(' ').first,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    fontStyle: pw.FontStyle.italic,
                                    color: deepBlue,
                                  ),
                                ),
                        ),
                        pw.Container(height: 0.5, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(vertical: 2)),
                        pw.Text(
                          "AUTHORIZED SIGNATORY",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6, color: deepBlue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _invMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
      child: pw.Row(
        children: [
          pw.Container(
            width: 50,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: deepBlue),
            ),
          ),
          pw.Text(
            ":  $value",
            style: const pw.TextStyle(fontSize: 6.5),
          ),
        ],
      ),
    );
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 70,
            child: pw.Text(
              "$label   :",
              style: const pw.TextStyle(fontSize: 7),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 7),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _cellBody(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 7),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ],
      ),
    );
  }

  static pw.Widget _termItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 6),
      ),
    );
  }

  static pw.Widget _bankItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.Container(
            width: 55,
            child: pw.Text(
              "$label:",
              style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 6),
          ),
        ],
      ),
    );
  }
}
