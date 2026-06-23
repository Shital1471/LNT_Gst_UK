import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:docx_creator/docx_creator.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../models/invoice_template_schema.dart';

class DocxGeneratorService {
  static Future<Uint8List> generateInvoiceDocx({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required CompanyProfile company,
  }) async {
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

    // 2. Parse dynamic values
    Map<String, dynamic> fieldValues = {};
    if (invoice.fieldValuesJson != null && invoice.fieldValuesJson!.isNotEmpty) {
      try {
        fieldValues = jsonDecode(invoice.fieldValuesJson!);
      } catch (_) {}
    } else {
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

    if (company.name.isNotEmpty) {
      fieldValues['company_name'] = company.name;
    }
    if (company.address.isNotEmpty) {
      fieldValues['company_address'] = company.address;
    }
    if (company.gstNumber.isNotEmpty) {
      fieldValues['company_gst'] = company.gstNumber;
      fieldValues['company_gst_in'] = company.gstNumber;
    }
    if (company.contactNumber.isNotEmpty) {
      fieldValues['company_phone'] = company.contactNumber;
    }
    if (company.email.isNotEmpty) {
      fieldValues['company_email'] = company.email;
    }

    final isTourism = template.id == 'tourism';

    // Build DOCX document
    final document = docx();

    // Set margins based on template configuration (converting points to twips)
    document.section(
      pageSize: DocxPageSize.a4,
      orientation: DocxPageOrientation.portrait,
      marginTop: (template.marginTop * 20).toInt(),
      marginBottom: (template.marginBottom * 20).toInt(),
      marginLeft: (template.marginLeft * 20).toInt(),
      marginRight: (template.marginRight * 20).toInt(),
    );

    // Calculate available page width in twips (standard A4 is 595.27 points = 11905.4 twips)
    final int totalWidthTwips = ((template.pageWidth - template.marginLeft - template.marginRight) * 20).toInt();

    // Load logo and signature images if available
    Uint8List? logoBytes;
    String? logoExt;
    if (company.logoPath != null && company.logoPath!.isNotEmpty) {
      try {
        final file = File(company.logoPath!);
        if (await file.exists()) {
          logoBytes = await file.readAsBytes();
          logoExt = company.logoPath!.split('.').last.toLowerCase();
        }
      } catch (_) {}
    }

    Uint8List? sigBytes;
    String? sigExt;
    if (company.signaturePath != null && company.signaturePath!.isNotEmpty) {
      try {
        final file = File(company.signaturePath!);
        if (await file.exists()) {
          sigBytes = await file.readAsBytes();
          sigExt = company.signaturePath!.split('.').last.toLowerCase();
        }
      } catch (_) {}
    }

    final primaryBlue = DocxColor('0B3B60');
    final primaryOrange = DocxColor('E57A25');
    final primaryGreen = DocxColor('499F34');
    final blackColor = DocxColor('000000');
    final whiteColor = DocxColor('FFFFFF');
    final greyBorderColor = DocxColor('A0A0A0');

    if (isTourism) {
      // -------------------------------------------------------------
      // Tourism Template Design (Exact pixel-perfect match with PDF)
      // -------------------------------------------------------------
      final companyName = (fieldValues['company_name'] ?? company.name).toString().toUpperCase();
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
      final invoiceDate = invoiceDateRaw != null ? _formatValue(invoiceDateRaw, 'date', df) : '';
      final bookingRef = fieldValues['booking_ref'] ?? '';
      final bookingDateRaw = fieldValues['booking_date'];
      final bookingDate = bookingDateRaw != null ? _formatValue(bookingDateRaw, 'date', df) : '';
      final companyPan = fieldValues['company_pan'] ?? 'AAGCL7813B';
      final companyGstIn = fieldValues['company_gst_in'] ?? '05AAGCL7813B1ZU';

      // -- 1. Header Table (3 columns: Left details, middle separator, right green border invoice box) --
      final int leftColWidth = (totalWidthTwips * 0.53).toInt();
      final int middleColWidth = (totalWidthTwips * 0.02).toInt();
      final int rightColWidth = totalWidthTwips - leftColWidth - middleColWidth;

      DocxTableRow _metaRow(String label, String value) {
        return DocxTableRow(
          cells: [
            DocxTableCell(
              width: (rightColWidth * 0.45).toInt(),
              children: [
                DocxParagraph(
                  children: [
                    DocxText('$label :', fontWeight: DocxFontWeight.bold, fontSize: 8, fontFamily: 'Times New Roman')
                  ],
                )
              ],
            ),
            DocxTableCell(
              width: (rightColWidth * 0.55).toInt(),
              children: [
                DocxParagraph(
                  children: [
                    DocxText(value, fontSize: 8, fontFamily: 'Times New Roman')
                  ],
                )
              ],
            ),
          ]
        );
      }

      final headerTable = DocxTable(
        width: totalWidthTwips,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle.plain,
        rows: [
          DocxTableRow(
            cells: [
              // Left Cell: Company Details
              DocxTableCell(
                width: leftColWidth,
                children: [
                  DocxParagraph(
                    children: [
                      DocxText(companyName, fontSize: 13, fontWeight: DocxFontWeight.bold, color: primaryBlue, fontFamily: 'Times New Roman'),
                    ],
                  ),
                  DocxParagraph(
                    children: [
                      DocxText(tagline, fontSize: 6.5, fontWeight: DocxFontWeight.bold, color: primaryOrange, fontFamily: 'Times New Roman'),
                    ],
                  ),
                  DocxParagraph(
                    children: [
                      DocxText("Ph: $phone   Email: $email   Web: $web", fontSize: 7, fontFamily: 'Times New Roman'),
                    ],
                  ),
                  DocxParagraph(
                    children: [
                      DocxText("Office Address : $address", fontSize: 7, fontFamily: 'Times New Roman'),
                    ],
                  ),
                ],
              ),
              // Middle Cell: vertical green separator (using borderLeft on middle cell)
              DocxTableCell(
                width: middleColWidth,
                borderLeft: DocxBorderSide(style: DocxBorder.thick, color: primaryGreen, size: 12),
                children: [
                  DocxParagraph(children: []),
                ],
              ),
              // Right Cell: green-bordered metadata box
              DocxTableCell(
                width: rightColWidth,
                children: [
                  DocxTable(
                    width: rightColWidth,
                    widthType: DocxWidthType.dxa,
                    style: DocxTableStyle(
                      borderTop: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 8),
                      borderBottom: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 8),
                      borderLeft: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 8),
                      borderRight: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 8),
                      borderInsideH: DocxBorderSide.none(),
                      borderInsideV: DocxBorderSide.none(),
                    ),
                    rows: [
                      DocxTableRow(
                        cells: [
                          DocxTableCell(
                            colSpan: 2,
                            shadingFill: '499F34',
                            children: [
                              DocxParagraph(
                                align: DocxAlign.center,
                                children: [
                                  DocxText("INVOICE", color: whiteColor, fontWeight: DocxFontWeight.bold, fontSize: 10, fontFamily: 'Times New Roman'),
                                ],
                              )
                            ]
                          )
                        ]
                      ),
                      _metaRow("Invoice No.", invoiceNo.toString()),
                      _metaRow("Invoice Date", invoiceDate.toString()),
                      _metaRow("Booking Ref.", bookingRef.toString()),
                      _metaRow("Booking Date", bookingDate.toString()),
                      _metaRow("PAN No.", companyPan.toString()),
                      _metaRow("GSTIN", companyGstIn.toString()),
                    ],
                  )
                ],
              ),
            ]
          )
        ]
      );

      document.addTable(headerTable);
      document.p(''); // Spacer

      // -- 2. Bill-To & Service Details Table (Side-by-Side wrapped in dashed border) --
      final tourTrip = fieldValues['tour_trip'] ?? '';
      final travelDateRaw = fieldValues['travel_date'];
      final travelDate = travelDateRaw != null ? _formatValue(travelDateRaw, 'date', df) : '';
      final noOfDays = fieldValues['no_of_days']?.toString() ?? '';
      final noOfVehicles = fieldValues['no_of_vehicles']?.toString() ?? '';
      final coordinatorName = fieldValues['coordinator_name'] ?? '';

      final int colWidth = (totalWidthTwips * 0.48).toInt();
      final int spaceWidth = totalWidthTwips - colWidth * 2;

      DocxTableRow _dottedRow(String label, String value, int tableW, {bool isLast = false}) {
        final borderBottom = isLast
            ? null
            : DocxBorderSide(style: DocxBorder.dotted, color: greyBorderColor, size: 4);
        return DocxTableRow(
          cells: [
            DocxTableCell(
              width: (tableW * 0.35).toInt(),
              borderBottom: borderBottom,
              children: [
                DocxParagraph(
                  children: [
                    DocxText('$label :', fontWeight: DocxFontWeight.bold, fontSize: 8, fontFamily: 'Times New Roman')
                  ],
                )
              ],
            ),
            DocxTableCell(
              width: (tableW * 0.65).toInt(),
              borderBottom: borderBottom,
              children: [
                DocxParagraph(
                  children: [
                    DocxText(value, fontSize: 8, fontFamily: 'Times New Roman')
                  ],
                )
              ],
            ),
          ]
        );
      }

      final billToAndServiceTable = DocxTable(
        width: totalWidthTwips,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          borderTop: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderBottom: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderLeft: DocxBorderSide.none(),
          borderRight: DocxBorderSide.none(),
          borderInsideH: DocxBorderSide.none(),
          borderInsideV: DocxBorderSide.none(),
        ),
        rows: [
          DocxTableRow(
            cells: [
              // BILL TO Column
              DocxTableCell(
                width: colWidth,
                children: [
                  DocxParagraph(
                    borderBottomSide: DocxBorderSide(style: DocxBorder.single, color: blackColor, size: 8),
                    children: [
                      DocxText("BILL TO", color: primaryGreen, fontWeight: DocxFontWeight.bold, fontSize: 9, fontFamily: 'Times New Roman'),
                    ],
                  ),
                  DocxTable(
                    width: colWidth,
                    widthType: DocxWidthType.dxa,
                    style: DocxTableStyle.plain,
                    rows: [
                      _dottedRow("Name / Company", customerName.toString(), colWidth),
                      _dottedRow("Address", customerAddress.toString(), colWidth),
                      _dottedRow("City / State / PIN", customerCityStatePin.toString(), colWidth),
                      _dottedRow("GSTIN", customerGst.toString(), colWidth),
                      _dottedRow("Contact No.", customerPhone.toString(), colWidth, isLast: true),
                    ],
                  )
                ]
              ),
              // Spacer Column
              DocxTableCell(
                width: spaceWidth,
                children: [DocxParagraph(children: [])]
              ),
              // SERVICE DETAIL 8 Column
              DocxTableCell(
                width: colWidth,
                children: [
                  DocxParagraph(
                    borderBottomSide: DocxBorderSide(style: DocxBorder.single, color: blackColor, size: 8),
                    children: [
                      DocxText("SERVICE DETAIL 8", color: primaryGreen, fontWeight: DocxFontWeight.bold, fontSize: 9, fontFamily: 'Times New Roman'),
                    ],
                  ),
                  DocxTable(
                    width: colWidth,
                    widthType: DocxWidthType.dxa,
                    style: DocxTableStyle.plain,
                    rows: [
                      _dottedRow("Tour / Trip", tourTrip.toString(), colWidth),
                      _dottedRow("Travel Date", travelDate.toString(), colWidth),
                      _dottedRow("No. of Days", noOfDays.toString(), colWidth),
                      _dottedRow("No. of Vehicles", noOfVehicles.toString(), colWidth),
                      _dottedRow("Co-ordinator Name", coordinatorName.toString(), colWidth, isLast: true),
                    ],
                  )
                ]
              )
            ]
          )
        ]
      );

      document.addTable(billToAndServiceTable);
      document.p(''); // Spacer

      // -- 3. Items Table --
      final tourismHeaders = ['S No.', 'Description of Service', 'No. of Vehicles', 'Date', 'From-To', 'Qty/Days', 'Rate (Rs.)', 'Amt (Rs.)'];
      final tourismWidths = [
        (totalWidthTwips * 0.06).toInt(),
        (totalWidthTwips * 0.36).toInt(),
        (totalWidthTwips * 0.10).toInt(),
        (totalWidthTwips * 0.10).toInt(),
        (totalWidthTwips * 0.16).toInt(),
        (totalWidthTwips * 0.08).toInt(),
        (totalWidthTwips * 0.07).toInt(),
        (totalWidthTwips * 0.07).toInt(),
      ];
      final tourismAlignments = [
        DocxAlign.center,
        DocxAlign.left,
        DocxAlign.center,
        DocxAlign.center,
        DocxAlign.left,
        DocxAlign.center,
        DocxAlign.right,
        DocxAlign.right,
      ];

      final List<DocxTableRow> itemsRows = [];
      // Header Row
      itemsRows.add(DocxTableRow(
        cells: List.generate(tourismHeaders.length, (idx) {
          return DocxTableCell(
            width: tourismWidths[idx],
            shadingFill: '499F34',
            children: [
              DocxParagraph(
                align: DocxAlign.center,
                children: [
                  DocxText(tourismHeaders[idx], color: whiteColor, fontWeight: DocxFontWeight.bold, fontSize: 7.5, fontFamily: 'Times New Roman'),
                ],
              )
            ],
          );
        }),
      ));

      // Items Rows (No empty lines allowed)
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final itemDateStr = item.itemDate != null ? df.format(item.itemDate!) : '';
        final rowValues = [
          (i + 1).toString(),
          item.description,
          item.noOfVehicles?.toString() ?? '1',
          itemDateStr,
          item.fromTo ?? '',
          item.quantityDays.toStringAsFixed(item.quantityDays % 1 == 0 ? 0 : 1),
          simpleCurrencyFmt.format(item.rate),
          simpleCurrencyFmt.format(item.amount),
        ];

        itemsRows.add(DocxTableRow(
          cells: List.generate(rowValues.length, (idx) {
            return DocxTableCell(
              width: tourismWidths[idx],
              children: [
                DocxParagraph(
                  align: tourismAlignments[idx],
                  children: [
                    DocxText(rowValues[idx], fontSize: 8, fontFamily: 'Times New Roman'),
                  ],
                )
              ],
            );
          }),
        ));
      }

      final itemsTable = DocxTable(
        width: totalWidthTwips,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          border: DocxBorder.single,
          borderColor: '000000',
          borderWidth: 4,
        ),
        rows: itemsRows,
      );

      document.addTable(itemsTable);
      document.p(''); // Spacer

      // -- 4. Totals Block (Words on Left, Totals on Right) --
      final double gstPercentage = (invoice.subTotal == 0) ? 0.0 : ((invoice.cgst + invoice.sgst) / invoice.subTotal * 100);
      final gstHalfRate = gstPercentage / 2;

      final int leftTotalW = (totalWidthTwips * 0.55).toInt();
      final int rightTotalW = (totalWidthTwips * 0.40).toInt();
      final int spaceTotalW = totalWidthTwips - leftTotalW - rightTotalW;

      final wordsTable = DocxTable(
        width: leftTotalW,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          borderTop: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderBottom: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderLeft: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderRight: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderInsideH: DocxBorderSide.none(),
          borderInsideV: DocxBorderSide.none(),
        ),
        rows: [
          DocxTableRow(
            cells: [
              DocxTableCell(
                width: leftTotalW,
                children: [
                  DocxParagraph(
                    children: [
                      DocxText("Amount to be paid in words : ${invoice.amountPaidInWords.endsWith(' Only') ? '${invoice.amountPaidInWords}.' : (invoice.amountPaidInWords.endsWith(' Only.') ? invoice.amountPaidInWords : '${invoice.amountPaidInWords} Only.')}", fontWeight: DocxFontWeight.bold, fontSize: 8, fontFamily: 'Times New Roman'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      DocxTableRow _totalsRow(String label, String value, {bool isBold = false, bool isTotalAmount = false}) {
        final shading = isTotalAmount ? '000000' : null;
        final textColor = isTotalAmount ? whiteColor : null;
        final weight = (isBold || isTotalAmount) ? DocxFontWeight.bold : DocxFontWeight.normal;
        return DocxTableRow(
          cells: [
            DocxTableCell(
              width: (rightTotalW * 0.60).toInt(),
              shadingFill: shading,
              children: [
                DocxParagraph(
                  children: [
                    DocxText(label, fontWeight: weight, color: textColor, fontSize: 7.5, fontFamily: 'Times New Roman'),
                  ],
                ),
              ],
            ),
            DocxTableCell(
              width: (rightTotalW * 0.40).toInt(),
              shadingFill: shading,
              children: [
                DocxParagraph(
                  align: DocxAlign.right,
                  children: [
                    DocxText("Rs. $value", fontWeight: weight, color: textColor, fontSize: 7.5, fontFamily: 'Times New Roman'),
                  ],
                ),
              ],
            ),
          ],
        );
      }

      final totalsTable = DocxTable(
        width: rightTotalW,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          borderTop: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderBottom: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderLeft: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderRight: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderInsideH: DocxBorderSide(style: DocxBorder.single, color: blackColor, size: 4),
          borderInsideV: DocxBorderSide(style: DocxBorder.single, color: blackColor, size: 4),
        ),
        rows: [
          _totalsRow("Sub Total", simpleCurrencyFmt.format(invoice.subTotal)),
          _totalsRow("CGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%", simpleCurrencyFmt.format(invoice.cgst)),
          _totalsRow("SGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%", simpleCurrencyFmt.format(invoice.sgst)),
          _totalsRow("Total Amount", simpleCurrencyFmt.format(invoice.grandTotal), isTotalAmount: true),
          _totalsRow("Advance Payment Received", simpleCurrencyFmt.format(invoice.advancePaid)),
          _totalsRow("Amount To Be Paid", simpleCurrencyFmt.format(invoice.grandTotal - invoice.advancePaid), isBold: true),
        ],
      );

      final totalsLayoutTable = DocxTable(
        width: totalWidthTwips,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle.plain,
        rows: [
          DocxTableRow(
            cells: [
              DocxTableCell(width: leftTotalW, children: [wordsTable]),
              DocxTableCell(width: spaceTotalW, children: [DocxParagraph(children: [])]),
              DocxTableCell(width: rightTotalW, children: [totalsTable]),
            ],
          ),
        ],
      );

      document.addTable(totalsLayoutTable);

      document.p(''); // Spacer

      // -- 5. Footer Block (Terms on Left, Bank in Middle, Signatory on Right) --
      final bankAccountName = fieldValues['bank_account_name'] ?? company.bankAccountName;
      final bankName = fieldValues['bank_name'] ?? company.bankName;
      final bankAccountNo = fieldValues['bank_account_no'] ?? company.bankAccountNumber;
      final bankIfsc = fieldValues['bank_ifsc'] ?? company.bankIfscCode;

      final termsSec = template.sections.firstWhere((s) => s.id == 'terms_conditions', orElse: () => SectionSchema(id: 'terms_conditions', title: 'TERM & CONDITION 8', orderIndex: 7, fields: []));
      final termsField = termsSec.fields.firstWhere((f) => f.id == 'terms_text', orElse: () => FieldSchema(id: 'terms_text', label: 'Terms', valueType: 'text'));
      final termsString = fieldValues['terms_text'] ?? termsField.defaultValue?.toString() ?? '';
      final termsList = termsString.toString().split('\n').where((t) => t.isNotEmpty).toList();

      final int footerCol1W = (totalWidthTwips * 0.40).toInt();
      final int footerSepW = (totalWidthTwips * 0.02).toInt();
      final int footerCol2W = (totalWidthTwips * 0.28).toInt();
      final int footerCol3W = totalWidthTwips - footerCol1W - footerCol2W - footerSepW * 2;

      final termsParagraphs = <DocxParagraph>[
        DocxParagraph(
          children: [
            DocxText("TERM & CONDITION 8", color: primaryGreen, fontWeight: DocxFontWeight.bold, fontSize: 8, fontFamily: 'Times New Roman'),
          ],
        ),
      ];
      for (final term in termsList) {
        termsParagraphs.add(DocxParagraph(
          children: [
            DocxText(term, fontSize: 6.5, fontFamily: 'Times New Roman'),
          ],
        ));
      }

      DocxTableRow _bankItemRow(String label, String value, int tableW) {
        return DocxTableRow(
          cells: [
            DocxTableCell(
              width: (tableW * 0.40).toInt(),
              children: [
                DocxParagraph(
                  children: [
                    DocxText('$label:', fontWeight: DocxFontWeight.bold, fontSize: 7, fontFamily: 'Times New Roman')
                  ],
                )
              ],
            ),
            DocxTableCell(
              width: (tableW * 0.60).toInt(),
              children: [
                DocxParagraph(
                  children: [
                    DocxText(value, fontSize: 7, fontFamily: 'Times New Roman')
                  ],
                )
              ],
            ),
          ]
        );
      }

      final bankTable = DocxTable(
        width: footerCol2W,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle.plain,
        rows: [
          _bankItemRow("Aooount Name", bankAccountName.toString(), footerCol2W),
          _bankItemRow("Bank Name", bankName.toString(), footerCol2W),
          _bankItemRow("Aooount No.", bankAccountNo.toString(), footerCol2W),
          _bankItemRow("IFSC Code", bankIfsc.toString(), footerCol2W),
        ],
      );

      final signatoryParagraphs = <DocxParagraph>[
        DocxParagraph(
          align: DocxAlign.center,
          children: [
            DocxText("FOR ${companyName.toUpperCase()}", fontWeight: DocxFontWeight.bold, fontSize: 7.5, color: primaryBlue, fontFamily: 'Times New Roman'),
          ],
        ),
        DocxParagraph(
          align: DocxAlign.center,
          children: [
            DocxText("This is a computer-generated invoice.", fontSize: 5.5, color: DocxColor('555555'), fontFamily: 'Times New Roman'),
          ],
        ),
        DocxParagraph(
          align: DocxAlign.center,
          children: [
            DocxText("Subject to applicable laws of India.", fontSize: 5.5, color: DocxColor('555555'), fontFamily: 'Times New Roman'),
          ],
        ),
        DocxParagraph(children: []), // spacing
      ];

      if (sigBytes != null) {
        signatoryParagraphs.add(
          DocxParagraph(
            align: DocxAlign.center,
            borderBottomSide: DocxBorderSide(style: DocxBorder.single, color: DocxColor('CCCCCC'), size: 4),
            children: [
              DocxInlineImage(
                bytes: sigBytes,
                extension: sigExt ?? 'png',
                width: 60,
                height: 22,
              )
            ],
          )
        );
      } else {
        signatoryParagraphs.add(
          DocxParagraph(
            align: DocxAlign.center,
            borderBottomSide: DocxBorderSide(style: DocxBorder.single, color: DocxColor('CCCCCC'), size: 4),
            children: [
              DocxText("Abhishek Prajapati", color: DocxColor('1D4ED8'), fontStyle: DocxFontStyle.italic, fontWeight: DocxFontWeight.bold, fontSize: 10, fontFamily: 'Times New Roman'),
            ],
          )
        );
      }

      signatoryParagraphs.add(
        DocxParagraph(
          align: DocxAlign.center,
          children: [
            DocxText("AUTHORISED SIGNATORY", fontWeight: DocxFontWeight.bold, fontSize: 7, color: primaryBlue, fontFamily: 'Times New Roman'),
          ],
        )
      );

      final footerLayoutTable = DocxTable(
        width: totalWidthTwips,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          borderTop: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderBottom: DocxBorderSide(style: DocxBorder.dashed, color: blackColor, size: 6),
          borderLeft: DocxBorderSide.none(),
          borderRight: DocxBorderSide.none(),
          borderInsideH: DocxBorderSide.none(),
          borderInsideV: DocxBorderSide.none(),
        ),
        rows: [
          DocxTableRow(
            cells: [
              // Col 1: Terms
              DocxTableCell(width: footerCol1W, children: termsParagraphs),
              // Sep 1
              DocxTableCell(
                width: footerSepW,
                borderLeft: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 12),
                children: [DocxParagraph(children: [])]
              ),
              // Col 2: Bank details
              DocxTableCell(
                width: footerCol2W,
                children: [
                  DocxParagraph(
                    children: [
                      DocxText("BANK DETAIL 8", color: primaryGreen, fontWeight: DocxFontWeight.bold, fontSize: 8, fontFamily: 'Times New Roman'),
                    ],
                  ),
                  bankTable
                ]
              ),
              // Sep 2
              DocxTableCell(
                width: footerSepW,
                borderLeft: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 12),
                children: [DocxParagraph(children: [])]
              ),
              // Col 3: Signatory
              DocxTableCell(width: footerCol3W, children: signatoryParagraphs),
            ],
          ),
        ],
      );

      document.addTable(footerLayoutTable);
      document.p(''); // Spacer

    } else {
      // -------------------------------------------------------------
      // Sequential standard/transport/service layout using tables for structure
      // -------------------------------------------------------------
      final visibleSections = template.sections.where((s) => s.isVisible).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      bool spacerInserted = false;
      for (final sec in visibleSections) {
        // Footer sections will flow naturally without spacer paragraphs.
        if (sec.id == 'company_details') {
          final cName = (fieldValues['company_name'] ?? company.name).toString().toUpperCase();
          final cAddr = fieldValues['company_address'] ?? company.address;
          final cPhone = fieldValues['company_phone'] ?? company.contactNumber;
          final cEmail = fieldValues['company_email'] ?? company.email;
          final cWeb = fieldValues['company_website'] ?? 'www.lntourism.com';
          final cPan = fieldValues['company_pan'] ?? 'AAGCL7813B';
          final cGstin = fieldValues['company_gst_in'] ?? company.gstNumber;

          // Side-by-side header
          final leftW = (totalWidthTwips * 0.65).toInt();
          final rightW = totalWidthTwips - leftW;

          final headerTable = DocxTable(
            width: totalWidthTwips,
            widthType: DocxWidthType.dxa,
            style: DocxTableStyle.plain,
            rows: [
              DocxTableRow(
                cells: [
                  DocxTableCell(
                    width: leftW,
                    children: [
                      DocxParagraph(
                        children: [
                          DocxText(cName, fontSize: 14, fontWeight: DocxFontWeight.bold, color: primaryBlue),
                        ],
                      ),
                      DocxParagraph(
                        children: [
                          DocxText("TOURS & TRAVELS | CAR RENTAL | TRANSPORT SOLUTIONS", fontSize: 7, fontWeight: DocxFontWeight.bold, color: primaryOrange),
                        ],
                      ),
                      DocxParagraph(
                        children: [
                          DocxText("Office Address: $cAddr", fontSize: 8),
                        ],
                      ),
                      DocxParagraph(
                        children: [
                          DocxText("Ph: $cPhone | Email: $cEmail | Web: $cWeb", fontSize: 8),
                        ],
                      ),
                    ],
                  ),
                  DocxTableCell(
                    width: rightW,
                    children: [
                      DocxTable(
                        width: rightW,
                        widthType: DocxWidthType.dxa,
                        style: DocxTableStyle(
                          borderTop: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 8),
                          borderBottom: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 8),
                          borderLeft: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 8),
                          borderRight: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 8),
                          borderInsideH: DocxBorderSide.none(),
                          borderInsideV: DocxBorderSide.none(),
                        ),
                        rows: [
                          DocxTableRow(
                            cells: [
                              DocxTableCell(
                                colSpan: 2,
                                shadingFill: '499F34',
                                children: [
                                  DocxParagraph(
                                    align: DocxAlign.center,
                                    children: [
                                      DocxText("INVOICE", color: whiteColor, fontWeight: DocxFontWeight.bold, fontSize: 9.5),
                                    ],
                                  )
                                ]
                              )
                            ]
                          ),
                          DocxTableRow(
                            cells: [
                              DocxTableCell(
                                width: (rightW * 0.45).toInt(),
                                children: [DocxParagraph(children: [DocxText("Invoice No. :", fontWeight: DocxFontWeight.bold, fontSize: 8)])],
                              ),
                              DocxTableCell(
                                width: (rightW * 0.55).toInt(),
                                children: [DocxParagraph(children: [DocxText(invoice.invoiceNumber, fontSize: 8)])],
                              ),
                            ]
                          ),
                          DocxTableRow(
                            cells: [
                              DocxTableCell(
                                width: (rightW * 0.45).toInt(),
                                children: [DocxParagraph(children: [DocxText("Invoice Date :", fontWeight: DocxFontWeight.bold, fontSize: 8)])],
                              ),
                              DocxTableCell(
                                width: (rightW * 0.55).toInt(),
                                children: [DocxParagraph(children: [DocxText(df.format(invoice.invoiceDate), fontSize: 8)])],
                              ),
                            ]
                          ),
                          DocxTableRow(
                            cells: [
                              DocxTableCell(
                                width: (rightW * 0.45).toInt(),
                                children: [DocxParagraph(children: [DocxText("PAN No. :", fontWeight: DocxFontWeight.bold, fontSize: 8)])],
                              ),
                              DocxTableCell(
                                width: (rightW * 0.55).toInt(),
                                children: [DocxParagraph(children: [DocxText(cPan, fontSize: 8)])],
                              ),
                            ]
                          ),
                          DocxTableRow(
                            cells: [
                              DocxTableCell(
                                width: (rightW * 0.45).toInt(),
                                children: [DocxParagraph(children: [DocxText("GSTIN :", fontWeight: DocxFontWeight.bold, fontSize: 8)])],
                              ),
                              DocxTableCell(
                                width: (rightW * 0.55).toInt(),
                                children: [DocxParagraph(children: [DocxText(cGstin, fontSize: 8)])],
                              ),
                            ]
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ],
          );

          document.addTable(headerTable);
          document.p('');

        } else if (sec.id == 'customer_details' || sec.id == 'invoice_info' || sec.id == 'service_details') {
          final fields = sec.fields.where((field) => field.isVisible).toList();
          if (fields.isEmpty) continue;

          document.paragraph(
            DocxParagraph(
              borderBottomSide: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 8),
              children: [
                DocxText(sec.title.toUpperCase(), color: primaryBlue, fontWeight: DocxFontWeight.bold, fontSize: 9.5),
              ],
            )
          );

          // Build fields in 2 columns
          final cellW = (totalWidthTwips * 0.48).toInt();
          final spacerW = totalWidthTwips - cellW * 2;
          final List<DocxTableRow> fieldRows = [];
          
          for (int i = 0; i < fields.length; i += 2) {
            final f1 = fields[i];
            final raw1 = fieldValues[f1.id];
            final val1 = raw1 != null ? _formatValue(raw1, f1.valueType, df) : '';

            String label2 = '';
            String val2 = '';
            if (i + 1 < fields.length) {
              final f2 = fields[i + 1];
              final raw2 = fieldValues[f2.id];
              label2 = f2.label;
              val2 = raw2 != null ? _formatValue(raw2, f2.valueType, df) : '';
            }

            fieldRows.add(DocxTableRow(
              cells: [
                DocxTableCell(
                  width: cellW,
                  children: [
                    DocxParagraph(
                      children: [
                        DocxText("${f1.label}: ", fontWeight: DocxFontWeight.bold, fontSize: 8),
                        DocxText(val1, fontSize: 8),
                      ]
                    )
                  ]
                ),
                DocxTableCell(width: spacerW, children: [DocxParagraph(children: [])]),
                DocxTableCell(
                  width: cellW,
                  children: [
                    label2.isNotEmpty
                      ? DocxParagraph(
                          children: [
                            DocxText("$label2: ", fontWeight: DocxFontWeight.bold, fontSize: 8),
                            DocxText(val2, fontSize: 8),
                          ]
                        )
                      : DocxParagraph(children: [])
                  ]
                ),
              ]
            ));
          }

          document.addTable(DocxTable(
            width: totalWidthTwips,
            widthType: DocxWidthType.dxa,
            style: DocxTableStyle.plain,
            rows: fieldRows,
          ));
          document.p('');

        } else if (sec.id == 'items_table') {
          final isTransport = template.id == 'transport';
          
          final List<String> headers = [];
          final List<int> colWidths = [];
          final List<DocxAlign> alignments = [];

          if (isTransport) {
            headers.addAll(['S No.', 'Service Description', 'Vehicle No', 'Delivery Date', 'Route', 'Qty', 'Rate (Rs.)', 'Amt (Rs.)']);
            colWidths.addAll([
              (totalWidthTwips * 0.06).toInt(),
              (totalWidthTwips * 0.36).toInt(),
              (totalWidthTwips * 0.10).toInt(),
              (totalWidthTwips * 0.10).toInt(),
              (totalWidthTwips * 0.16).toInt(),
              (totalWidthTwips * 0.08).toInt(),
              (totalWidthTwips * 0.07).toInt(),
              (totalWidthTwips * 0.07).toInt(),
            ]);
            alignments.addAll([DocxAlign.center, DocxAlign.left, DocxAlign.center, DocxAlign.center, DocxAlign.left, DocxAlign.center, DocxAlign.right, DocxAlign.right]);
          } else {
            headers.addAll(['S No.', 'Description of Goods / Services', 'Qty', 'Rate (Rs.)', 'Amt (Rs.)']);
            colWidths.addAll([
              (totalWidthTwips * 0.08).toInt(),
              (totalWidthTwips * 0.52).toInt(),
              (totalWidthTwips * 0.12).toInt(),
              (totalWidthTwips * 0.13).toInt(),
              (totalWidthTwips * 0.15).toInt(),
            ]);
            alignments.addAll([DocxAlign.center, DocxAlign.left, DocxAlign.center, DocxAlign.right, DocxAlign.right]);
          }

          final List<DocxTableRow> tblRows = [];
          // Header
          tblRows.add(DocxTableRow(
            cells: List.generate(headers.length, (idx) {
              return DocxTableCell(
                width: colWidths[idx],
                shadingFill: '499F34',
                children: [
                  DocxParagraph(
                    align: DocxAlign.center,
                    children: [
                      DocxText(headers[idx], color: whiteColor, fontWeight: DocxFontWeight.bold, fontSize: 8),
                    ],
                  )
                ],
              );
            }),
          ));

          // Body rows (no empty placeholder rows)
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            final List<String> vals = [];
            if (isTransport) {
              final itemDateStr = item.itemDate != null ? df.format(item.itemDate!) : '';
              vals.addAll([
                (i + 1).toString(),
                item.description,
                item.noOfVehicles?.toString() ?? '',
                itemDateStr,
                item.fromTo ?? '',
                item.quantityDays.toString(),
                simpleCurrencyFmt.format(item.rate),
                simpleCurrencyFmt.format(item.amount),
              ]);
            } else {
              vals.addAll([
                (i + 1).toString(),
                item.description,
                item.quantityDays.toString(),
                simpleCurrencyFmt.format(item.rate),
                simpleCurrencyFmt.format(item.amount),
              ]);
            }

            tblRows.add(DocxTableRow(
              cells: List.generate(vals.length, (idx) {
                return DocxTableCell(
                  width: colWidths[idx],
                  children: [
                    DocxParagraph(
                      align: alignments[idx],
                      children: [
                        DocxText(vals[idx], fontSize: 8),
                      ],
                    )
                  ],
                );
              }),
            ));
          }

          document.addTable(DocxTable(
            width: totalWidthTwips,
            widthType: DocxWidthType.dxa,
            style: DocxTableStyle(
              border: DocxBorder.single,
              borderColor: '000000',
              borderWidth: 4,
            ),
            rows: tblRows,
          ));
          document.p('');

        } else if (sec.id == 'tax_summary') {
          final rightW = (totalWidthTwips * 0.40).toInt();
          final leftW = totalWidthTwips - rightW;

          DocxTableRow _totalsRow(String label, String value, {bool isBold = false, bool isTotalAmount = false}) {
            final shading = isTotalAmount ? '000000' : null;
            final textColor = isTotalAmount ? whiteColor : null;
            final weight = (isBold || isTotalAmount) ? DocxFontWeight.bold : DocxFontWeight.normal;
            return DocxTableRow(
              cells: [
                DocxTableCell(
                  width: (rightW * 0.60).toInt(),
                  shadingFill: shading,
                  children: [DocxParagraph(children: [DocxText(label, fontWeight: weight, color: textColor, fontSize: 8)])],
                ),
                DocxTableCell(
                  width: (rightW * 0.40).toInt(),
                  shadingFill: shading,
                  children: [DocxParagraph(align: DocxAlign.right, children: [DocxText("Rs. $value", fontWeight: weight, color: textColor, fontSize: 8)])],
                ),
              ],
            );
          }

          final balance = invoice.grandTotal - invoice.advancePaid;
          final summaryTable = DocxTable(
            width: rightW,
            widthType: DocxWidthType.dxa,
            style: DocxTableStyle(
              border: DocxBorder.single,
              borderColor: '000000',
              borderWidth: 4,
            ),
            rows: [
              _totalsRow("Sub Total", simpleCurrencyFmt.format(invoice.subTotal)),
              _totalsRow("CGST", simpleCurrencyFmt.format(invoice.cgst)),
              _totalsRow("SGST", simpleCurrencyFmt.format(invoice.sgst)),
              _totalsRow("Total Amount", simpleCurrencyFmt.format(invoice.grandTotal), isTotalAmount: true),
              _totalsRow("Advance Paid", simpleCurrencyFmt.format(invoice.advancePaid)),
              _totalsRow("Amount To Be Paid", simpleCurrencyFmt.format(balance), isBold: true),
            ],
          );

          final summaryLayout = DocxTable(
            width: totalWidthTwips,
            widthType: DocxWidthType.dxa,
            style: DocxTableStyle.plain,
            rows: [
              DocxTableRow(
                cells: [
                  DocxTableCell(
                    width: leftW,
                    children: [
                      DocxParagraph(
                        children: [
                          DocxText("Amount to be paid in words: ", fontWeight: DocxFontWeight.bold, fontSize: 8),
                          DocxText(invoice.amountPaidInWords, fontSize: 8),
                        ],
                      )
                    ],
                  ),
                  DocxTableCell(
                    width: rightW,
                    children: [summaryTable],
                  ),
                ],
              ),
            ],
          );

          document.addTable(summaryLayout);
          document.p('');

        } else if (sec.id == 'payment_info') {
          document.paragraph(
            DocxParagraph(
              borderBottomSide: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 8),
              children: [
                DocxText(sec.title.toUpperCase(), color: primaryBlue, fontWeight: DocxFontWeight.bold, fontSize: 9.5),
              ],
            )
          );

          document.p("Account Name: ${company.bankAccountName}");
          document.p("Bank Name: ${company.bankName}");
          document.p("Account Number: ${company.bankAccountNumber}");
          document.p("IFSC Code: ${company.bankIfscCode}");
          document.p('');

        } else if (sec.id == 'terms_conditions') {
          final field = sec.fields.firstWhere((f) => f.id == 'terms_text', orElse: () => FieldSchema(id: 'terms_text', label: 'Terms', valueType: 'text'));
          final termsString = field.defaultValue?.toString() ?? '1. Subject to local jurisdiction.\n2. E&OE.';
          final termsList = termsString.split('\n');

          document.paragraph(
            DocxParagraph(
              borderBottomSide: DocxBorderSide(style: DocxBorder.single, color: primaryGreen, size: 8),
              children: [
                DocxText(sec.title.toUpperCase(), color: primaryBlue, fontWeight: DocxFontWeight.bold, fontSize: 9.5),
              ],
            )
          );

          for (final term in termsList) {
            document.p(term);
          }
          document.p('');

        } else if (sec.id == 'signature') {
          final field = sec.fields.firstWhere((f) => f.id == 'signatory_title', orElse: () => FieldSchema(id: 'signatory_title', label: 'Title', valueType: 'text'));
          final title = field.defaultValue?.toString() ?? 'AUTHORIZED SIGNATORY';

          final sigTable = DocxTable(
            width: totalWidthTwips,
            widthType: DocxWidthType.dxa,
            style: DocxTableStyle.plain,
            rows: [
              DocxTableRow(
                cells: [
                  DocxTableCell(
                    width: (totalWidthTwips * 0.6).toInt(),
                    children: [DocxParagraph(children: [])]
                  ),
                  DocxTableCell(
                    width: (totalWidthTwips * 0.4).toInt(),
                    children: [
                      DocxParagraph(
                        align: DocxAlign.center,
                        children: [
                          DocxText("FOR ${company.name.toUpperCase()}", fontWeight: DocxFontWeight.bold, fontSize: 8.5, color: primaryBlue),
                        ],
                      ),
                      sigBytes != null
                        ? DocxParagraph(
                            align: DocxAlign.center,
                            children: [
                              DocxInlineImage(bytes: sigBytes, extension: sigExt ?? 'png', width: 60, height: 25)
                            ],
                          )
                        : DocxParagraph(children: []),
                      DocxParagraph(
                        align: DocxAlign.center,
                        borderBottomSide: DocxBorderSide(style: DocxBorder.single, color: DocxColor('CCCCCC'), size: 4),
                        children: [
                          DocxText(company.name.split(' ').first, fontStyle: DocxFontStyle.italic, fontWeight: DocxFontWeight.bold, fontSize: 10, color: primaryBlue),
                        ],
                      ),
                      DocxParagraph(
                        align: DocxAlign.center,
                        children: [
                          DocxText(title.toUpperCase(), fontWeight: DocxFontWeight.bold, fontSize: 7.5, color: primaryBlue),
                        ],
                      ),
                    ]
                  ),
                ]
              )
            ]
          );

          document.addTable(sigTable);
        }
      }
    }

    final builtDoc = document.build();
    final bytes = await DocxExporter().exportToBytes(builtDoc);
    return Uint8List.fromList(bytes);
  }

  static String _formatValue(dynamic val, String type, DateFormat df) {
    if (val == null) return '';
    if (val is DateTime) {
      return df.format(val);
    }
    final strVal = val.toString();
    if (type == 'date') {
      final parsed = DateTime.tryParse(strVal);
      if (parsed != null) return df.format(parsed);
    }
    return strVal;
  }
}
