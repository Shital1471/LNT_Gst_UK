import 'dart:typed_data';
import 'package:docx_creator/docx_creator.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';

class DocxGeneratorService {
  static Future<Uint8List> generateInvoiceDocx({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required CompanyProfile company,
  }) async {
    final df = DateFormat('dd/MM/yyyy');
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);
    final simpleCurrencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);

    // Build the doc using the docx_creator builder
    final document = docx();

    // 1. Company Title and Header Details
    document
        .h1(company.name.toUpperCase())
        .p('TOURS & TRAVELS | CAR RENTAL | TRANSPORT SOLUTIONS')
        .p('Ph: ${company.contactNumber} | Email: ${company.email} | Web: www.lntourism.com')
        .p('Office Address: ${company.address}')
        .p('PAN No: AAGCL7813B | GSTIN: ${company.gstNumber}')
        .p('------------------------------------------------------------------------------------------------------------------------');

    // 2. Invoice Metadata Block
    document
        .h2('INVOICE')
        .p('Invoice Number: ${invoice.invoiceNumber}')
        .p('Invoice Date: ${df.format(invoice.invoiceDate)}')
        .p('Booking Ref: ${invoice.bookingRef ?? "N/A"}')
        .p('Booking Date: ${invoice.bookingDate != null ? df.format(invoice.bookingDate!) : "N/A"}')
        .p('------------------------------------------------------------------------------------------------------------------------');

    // 3. Billing & Service Details stacked in paragraphs for high readability in DOCX
    document
        .h3('BILL TO')
        .p('Customer Name: ${invoice.customerName}')
        .p('Customer Address: ${invoice.customerAddress}')
        .p('Customer GSTIN: ${invoice.customerGstNumber ?? "N/A"}')
        .p('Contact Number: ${invoice.customerContactNumber ?? "N/A"}')
        .p('------------------------------------------------------------------------------------------------------------------------')
        .h3('SERVICE DETAILS')
        .p('Tour / Trip: ${invoice.tourTrip ?? "N/A"}')
        .p('Travel Date: ${invoice.travelDate != null ? df.format(invoice.travelDate!) : "N/A"}')
        .p('No. of Days: ${invoice.noOfDays ?? "N/A"}')
        .p('No. of Vehicles: ${invoice.noOfVehicles ?? "N/A"}')
        .p('Co-ordinator Name: ${invoice.coordinatorName ?? "N/A"}')
        .p('------------------------------------------------------------------------------------------------------------------------');

    // 4. Line Items Table
    final List<List<String>> tableData = [];
    
    // Add Table Header
    tableData.add([
      'S No.',
      'Description of Service',
      'No. of Vehicles',
      'Date',
      'From-To',
      'Qty/Days',
      'Rate (Rs.)',
      'Amt (Rs.)'
    ]);

    // Add items rows
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      tableData.add([
        (i + 1).toString(),
        item.description,
        item.noOfVehicles?.toString() ?? '1',
        item.itemDate != null ? df.format(item.itemDate!) : 'N/A',
        item.fromTo ?? 'N/A',
        item.quantityDays.toString(),
        simpleCurrencyFmt.format(item.rate),
        simpleCurrencyFmt.format(item.amount),
      ]);
    }

    // Add empty rows up to 5 to preserve the exact aesthetic structure of the template
    if (items.length < 5) {
      for (int i = items.length; i < 5; i++) {
        tableData.add([
          (i + 1).toString(),
          '',
          '',
          '',
          '',
          '',
          '',
          ''
        ]);
      }
    }

    document.table(tableData);
    document.p('------------------------------------------------------------------------------------------------------------------------');

    // 5. Totals Section
    final double balance = invoice.grandTotal - invoice.advancePaid;
    document
        .p('Sub Total: ${simpleCurrencyFmt.format(invoice.subTotal)}')
        .p('CGST: ${simpleCurrencyFmt.format(invoice.cgst)}')
        .p('SGST: ${simpleCurrencyFmt.format(invoice.sgst)}')
        .p('Total Amount: ${currencyFmt.format(invoice.grandTotal)}')
        .p('Advance Paid: ${simpleCurrencyFmt.format(invoice.advancePaid)}')
        .p('Amount To Be Paid: ${currencyFmt.format(balance)}')
        .p('Amount to be paid in words: ${invoice.amountPaidInWords}')
        .p('------------------------------------------------------------------------------------------------------------------------');

    // 6. Bottom Panels (T&C, Bank Details, and Signatory)
    document
        .h3('TERMS & CONDITIONS')
        .p('1. Payment to be made within 7 days from invoice date.')
        .p('2. Extra charges (State Tax, Night Halt, Extra Km) will be charged as per actual.')
        .p('3. Vehicle will be provided as per the itinerary only.')
        .p('4. No refund for unused days or cancellations post journey.')
        .p('5. All disputes are subject to Dehradun jurisdiction only.')
        .p('------------------------------------------------------------------------------------------------------------------------')
        .h3('BANK DETAILS')
        .p('Account Name: ${company.bankAccountName}')
        .p('Bank Name: ${company.bankName}')
        .p('Account Number: ${company.bankAccountNumber}')
        .p('IFSC Code: ${company.bankIfscCode}')
        .p('------------------------------------------------------------------------------------------------------------------------')
        .h3('FOR ${company.name.toUpperCase()}')
        .p('This is a computer-generated invoice. Subject to applicable laws of India.')
        .p('AUTHORIZED SIGNATORY')
        .p('[ Signature Stamp / Image ]');

    // Export to docx bytes
    final builtDoc = document.build();
    final bytes = await DocxExporter().exportToBytes(builtDoc);
    return Uint8List.fromList(bytes);
  }
}
