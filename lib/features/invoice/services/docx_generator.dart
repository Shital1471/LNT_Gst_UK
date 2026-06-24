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

    // 2. Parse dynamic values
    Map<String, dynamic> fieldValues = {};
    if (invoice.fieldValuesJson != null &&
        invoice.fieldValuesJson!.isNotEmpty) {
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

    final bankAccountName =
        fieldValues['bank_account_name'] ?? company.bankAccountName;
    final bankName = fieldValues['bank_name'] ?? company.bankName;
    final bankAccountNo =
        fieldValues['bank_account_no'] ?? company.bankAccountNumber;
    final bankIfsc = fieldValues['bank_ifsc'] ?? company.bankIfscCode;

    final termsSec = adjustedTemplate.sections.firstWhere(
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
      orElse: () => FieldSchema(
        id: 'terms_text',
        label: 'Terms',
        valueType: 'text',
      ),
    );
    final termsString = fieldValues['terms_text'] ??
        termsField.defaultValue?.toString() ??
        '';
    final termsList = termsString
        .toString()
        .split('\n')
        .where((t) => t.isNotEmpty)
        .toList();

    final sigSec = adjustedTemplate.sections.firstWhere(
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
      orElse: () => FieldSchema(
        id: 'signatory_title',
        label: 'Title',
        valueType: 'text',
      ),
    );
    final signatoryTitle = fieldValues['signatory_title'] ??
        sigField.defaultValue?.toString() ??
        'AUTHORISED SIGNATORY';

    final double gstPercentage = (invoice.subTotal == 0)
        ? 0.0
        : ((invoice.cgst + invoice.sgst) / invoice.subTotal * 100);
    final gstHalfRate = gstPercentage / 2;

    final isTourism = adjustedTemplate.id == 'tourism';

    // Build DOCX document
    final document = docx();

    // Set margins based on template configuration (converting points to twips)
    document.section(
      pageSize: DocxPageSize.a4,
      orientation: DocxPageOrientation.portrait,
      marginTop: (adjustedTemplate.marginTop * 20).toInt(),
      marginBottom: (adjustedTemplate.marginBottom * 20).toInt(),
      marginLeft: (adjustedTemplate.marginLeft * 20).toInt(),
      marginRight: (adjustedTemplate.marginRight * 20).toInt(),
    );

    // Calculate available page width in twips
    final int totalWidthTwips =
        ((adjustedTemplate.pageWidth -
                    adjustedTemplate.marginLeft -
                    adjustedTemplate.marginRight) *
                20)
            .toInt();

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

    // Colors
    final primaryBlue = DocxColor('0B3B60');
    final primaryOrange = DocxColor('E57A25');
    final primaryGreen = DocxColor('499F34');
    final blackColor = DocxColor('000000');
    final whiteColor = DocxColor('FFFFFF');
    final greyBorderColor = DocxColor('A0A0A0');

    // Retrieve Typography styles
    final headerStyle =
        adjustedTemplate.typography['header'] ??
        TextStyleSchema(
          fontSize: 12,
          fontWeight: 'bold',
          fontFamily: 'Times New Roman',
          textColor: '#0B3B60',
        );
    final subheaderStyle =
        adjustedTemplate.typography['subheader'] ??
        TextStyleSchema(
          fontSize: 6.5,
          fontWeight: 'bold',
          fontFamily: 'Times New Roman',
          textColor: '#E57A25',
        );
    final sectionTitleStyle =
        adjustedTemplate.typography['section_title'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'bold',
          fontFamily: 'Times New Roman',
          textColor: '#499F34',
        );
    final subsectionTitleStyle =
        adjustedTemplate.typography['subsection_title'] ??
        TextStyleSchema(
          fontSize: 8,
          fontWeight: 'bold',
          fontFamily: 'Times New Roman',
          textColor: '#000000',
        );
    final bodyStyle =
        adjustedTemplate.typography['body'] ??
        TextStyleSchema(
          fontSize: 7.5,
          fontWeight: 'normal',
          fontFamily: 'Times New Roman',
          textColor: '#000000',
        );
    final tableHeaderStyle =
        adjustedTemplate.typography['table_header'] ??
        TextStyleSchema(
          fontSize: 7.5,
          fontWeight: 'bold',
          fontFamily: 'Times New Roman',
          textColor: '#FFFFFF',
        );
    final tableDataStyle =
        adjustedTemplate.typography['table_data'] ??
        TextStyleSchema(
          fontSize: 7.5,
          fontWeight: 'normal',
          fontFamily: 'Times New Roman',
          textColor: '#000000',
        );
    final footerStyle =
        adjustedTemplate.typography['footer'] ??
        TextStyleSchema(
          fontSize: 6.5,
          fontWeight: 'normal',
          fontFamily: 'Times New Roman',
          textColor: '#000000',
        );

    if (isTourism) {
      // -------------------------------------------------------------
      // Dynamic Tourism Template Design
      // -------------------------------------------------------------
      final companyName = (fieldValues['company_name'] ?? company.name)
          .toString()
          .toUpperCase();
      final tagline =
          (fieldValues['company_tagline'] ??
                  'TOURS & TRAVELS | CAR RENTAL | TRANSPORT SOLUTIONS')
              .toString()
              .toUpperCase();
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
      final invoiceDate = invoiceDateRaw != null
          ? _formatValue(invoiceDateRaw, 'date', df)
          : '';
      final bookingRef = fieldValues['booking_ref'] ?? '';
      final bookingDateRaw = fieldValues['booking_date'];
      final bookingDate = bookingDateRaw != null
          ? _formatValue(bookingDateRaw, 'date', df)
          : '';
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
                    DocxText(
                      '$label :',
                      fontWeight: DocxFontWeight.bold,
                      fontSize: 8,
                      fontFamily: 'Times New Roman',
                    ),
                  ],
                ),
              ],
            ),
            DocxTableCell(
              width: (rightColWidth * 0.55).toInt(),
              children: [
                DocxParagraph(
                  children: [
                    DocxText(value, fontSize: 8, fontFamily: 'Times New Roman'),
                  ],
                ),
              ],
            ),
          ],
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
                      DocxText(
                        companyName,
                        fontSize: headerStyle.fontSize,
                        fontWeight: _getDocxWeight(headerStyle.fontWeight),
                        color:
                            _getDocxColor(headerStyle.textColor) ?? primaryBlue,
                        fontFamily: headerStyle.fontFamily,
                      ),
                    ],
                  ),
                  DocxParagraph(
                    children: [
                      DocxText(
                        tagline,
                        fontSize: subheaderStyle.fontSize,
                        fontWeight: _getDocxWeight(subheaderStyle.fontWeight),
                        color:
                            _getDocxColor(subheaderStyle.textColor) ??
                            primaryOrange,
                        fontFamily: subheaderStyle.fontFamily,
                      ),
                    ],
                  ),
                  DocxParagraph(
                    children: [
                      DocxText(
                        "Ph: $phone   Email: $email   Web: $web",
                        fontSize: 7,
                        fontFamily: 'Times New Roman',
                      ),
                    ],
                  ),
                  DocxParagraph(
                    children: [
                      DocxText(
                        "Office Address : $address",
                        fontSize: 7,
                        fontFamily: 'Times New Roman',
                      ),
                    ],
                  ),
                ],
              ),
              // Middle Cell: vertical green separator
              DocxTableCell(
                width: middleColWidth,
                borderLeft: DocxBorderSide(
                  style: DocxBorder.thick,
                  color: primaryGreen,
                  size: 12,
                ),
                children: [DocxParagraph(children: [])],
              ),
              // Right Cell: green-bordered metadata box
              DocxTableCell(
                width: rightColWidth,
                children: [
                  DocxTable(
                    width: rightColWidth,
                    widthType: DocxWidthType.dxa,
                    style: DocxTableStyle(
                      borderTop: DocxBorderSide(
                        style: DocxBorder.single,
                        color: primaryGreen,
                        size: 8,
                      ),
                      borderBottom: DocxBorderSide(
                        style: DocxBorder.single,
                        color: primaryGreen,
                        size: 8,
                      ),
                      borderLeft: DocxBorderSide(
                        style: DocxBorder.single,
                        color: primaryGreen,
                        size: 8,
                      ),
                      borderRight: DocxBorderSide(
                        style: DocxBorder.single,
                        color: primaryGreen,
                        size: 8,
                      ),
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
                                  DocxText(
                                    "INVOICE",
                                    color: whiteColor,
                                    fontWeight: DocxFontWeight.bold,
                                    fontSize: 10,
                                    fontFamily: 'Times New Roman',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      _metaRow("Invoice No.", invoiceNo.toString()),
                      _metaRow("Invoice Date", invoiceDate.toString()),
                      _metaRow("Booking Ref.", bookingRef.toString()),
                      _metaRow("Booking Date", bookingDate.toString()),
                      _metaRow("PAN No.", companyPan.toString()),
                      _metaRow("GSTIN", companyGstIn.toString()),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      document.addTable(headerTable);
      document.p(''); // Spacer

      // -- 2. Bill-To & Service Details Table --
      final tourTrip = fieldValues['tour_trip'] ?? '';
      final travelDateRaw = fieldValues['travel_date'];
      final travelDate = travelDateRaw != null
          ? _formatValue(travelDateRaw, 'date', df)
          : '';
      final noOfDays = fieldValues['no_of_days']?.toString() ?? '';
      final noOfVehicles = fieldValues['no_of_vehicles']?.toString() ?? '';
      final coordinatorName = fieldValues['coordinator_name'] ?? '';

      final int colWidth = (totalWidthTwips * 0.48).toInt();
      final int spaceWidth = totalWidthTwips - colWidth * 2;

      DocxTableRow _dottedRow(
        String label,
        String value,
        int tableW, {
        bool isLast = false,
      }) {
        final borderBottom = isLast
            ? null
            : DocxBorderSide(
                style: DocxBorder.dotted,
                color: greyBorderColor,
                size: 4,
              );
        return DocxTableRow(
          cells: [
            DocxTableCell(
              width: (tableW * 0.35).toInt(),
              borderBottom: borderBottom,
              children: [
                DocxParagraph(
                  children: [
                    DocxText(
                      '$label :',
                      fontWeight: _getDocxWeight(
                        subsectionTitleStyle.fontWeight,
                      ),
                      color: _getDocxColor(subsectionTitleStyle.textColor),
                      fontSize: subsectionTitleStyle.fontSize,
                      fontFamily: subsectionTitleStyle.fontFamily,
                    ),
                  ],
                ),
              ],
            ),
            DocxTableCell(
              width: (tableW * 0.65).toInt(),
              borderBottom: borderBottom,
              children: [
                DocxParagraph(
                  children: [
                    DocxText(
                      value,
                      fontSize: bodyStyle.fontSize,
                      color: _getDocxColor(bodyStyle.textColor),
                      fontFamily: bodyStyle.fontFamily,
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      }

      final billToAndServiceTable = DocxTable(
        width: totalWidthTwips,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          borderTop: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
          borderBottom: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
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
                    borderBottomSide: DocxBorderSide(
                      style: DocxBorder.single,
                      color: blackColor,
                      size: 8,
                    ),
                    children: [
                      DocxText(
                        "BILL TO",
                        color:
                            _getDocxColor(sectionTitleStyle.textColor) ??
                            primaryGreen,
                        fontWeight: _getDocxWeight(
                          sectionTitleStyle.fontWeight,
                        ),
                        fontSize: sectionTitleStyle.fontSize,
                        fontFamily: sectionTitleStyle.fontFamily,
                      ),
                    ],
                  ),
                  DocxTable(
                    width: colWidth,
                    widthType: DocxWidthType.dxa,
                    style: DocxTableStyle.plain,
                    rows: [
                      _dottedRow(
                        "Name / Company",
                        customerName.toString(),
                        colWidth,
                      ),
                      _dottedRow(
                        "Address",
                        customerAddress.toString(),
                        colWidth,
                      ),
                      _dottedRow(
                        "City / State / PIN",
                        customerCityStatePin.toString(),
                        colWidth,
                      ),
                      _dottedRow("GSTIN", customerGst.toString(), colWidth),
                      _dottedRow(
                        "Contact No.",
                        customerPhone.toString(),
                        colWidth,
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              ),
              // Spacer Column
              DocxTableCell(
                width: spaceWidth,
                children: [DocxParagraph(children: [])],
              ),
              // SERVICE DETAIL Column
              DocxTableCell(
                width: colWidth,
                children: [
                  DocxParagraph(
                    borderBottomSide: DocxBorderSide(
                      style: DocxBorder.single,
                      color: blackColor,
                      size: 8,
                    ),
                    children: [
                      DocxText(
                        "SERVICE DETAIL 8",
                        color:
                            _getDocxColor(sectionTitleStyle.textColor) ??
                            primaryGreen,
                        fontWeight: _getDocxWeight(
                          sectionTitleStyle.fontWeight,
                        ),
                        fontSize: sectionTitleStyle.fontSize,
                        fontFamily: sectionTitleStyle.fontFamily,
                      ),
                    ],
                  ),
                  DocxTable(
                    width: colWidth,
                    widthType: DocxWidthType.dxa,
                    style: DocxTableStyle.plain,
                    rows: [
                      _dottedRow("Tour / Trip", tourTrip.toString(), colWidth),
                      _dottedRow(
                        "Travel Date",
                        travelDate.toString(),
                        colWidth,
                      ),
                      _dottedRow("No. of Days", noOfDays.toString(), colWidth),
                      _dottedRow(
                        "No. of Vehicles",
                        noOfVehicles.toString(),
                        colWidth,
                      ),
                      _dottedRow(
                        "Co-ordinator Name",
                        coordinatorName.toString(),
                        colWidth,
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      document.addTable(billToAndServiceTable);
      document.p(''); // Spacer

      // -- 3. Items Table (Dynamic Columns) --
      final visibleCols =
          adjustedTemplate.tableColumns.where((c) => c.isVisible).toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      final List<int> colWidths = visibleCols.map((c) {
        // Distribute content width twips proportionally
        return (totalWidthTwips * (c.width / adjustedTemplate.pageWidth))
            .toInt();
      }).toList();

      final List<DocxTableRow> tblRows = [];
      // Header
      tblRows.add(
        DocxTableRow(
          cells: List.generate(visibleCols.length, (idx) {
            final col = visibleCols[idx];
            return DocxTableCell(
              width: colWidths[idx],
              shadingFill: '499F34',
              children: [
                DocxParagraph(
                  align: DocxAlign.center,
                  children: [
                    DocxText(
                      col.label,
                      color:
                          _getDocxColor(tableHeaderStyle.textColor) ??
                          whiteColor,
                      fontWeight: _getDocxWeight(tableHeaderStyle.fontWeight),
                      fontSize: tableHeaderStyle.fontSize,
                      fontFamily: tableHeaderStyle.fontFamily,
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      );

      // Items Rows
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        tblRows.add(
          DocxTableRow(
            cells: List.generate(visibleCols.length, (idx) {
              final col = visibleCols[idx];
              final cellText = _getItemCellText(
                item,
                col,
                i,
                df,
                simpleCurrencyFmt,
              );

              DocxAlign align = DocxAlign.left;
              if (col.id == 's_no' ||
                  col.id == 'no_of_vehicles' ||
                  col.id == 'date' ||
                  col.id == 'qty') {
                align = DocxAlign.center;
              } else if (col.id == 'rate' || col.id == 'amount') {
                align = DocxAlign.right;
              } else {
                align = col.alignment == 'right'
                    ? DocxAlign.right
                    : (col.alignment == 'center'
                          ? DocxAlign.center
                          : DocxAlign.left);
              }

              return DocxTableCell(
                width: colWidths[idx],
                children: [
                  DocxParagraph(
                    align: align,
                    children: [
                      DocxText(
                        cellText,
                        fontSize: tableDataStyle.fontSize,
                        color: _getDocxColor(tableDataStyle.textColor),
                        fontFamily: tableDataStyle.fontFamily,
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        );
      }

      final itemsTable = DocxTable(
        width: totalWidthTwips,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          border: DocxBorder.single,
          borderColor: '000000',
          borderWidth: 4,
        ),
        rows: tblRows,
      );

      document.addTable(itemsTable);
      document.p(''); // Spacer

      // -- 4. Totals Block --
      final int leftTotalW = (totalWidthTwips * 0.55).toInt();
      final int rightTotalW = (totalWidthTwips * 0.40).toInt();
      final int spaceTotalW = totalWidthTwips - leftTotalW - rightTotalW;

      final wordsTable = DocxTable(
        width: leftTotalW,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          borderTop: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
          borderBottom: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
          borderLeft: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
          borderRight: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
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
                      DocxText(
                        "Amount to be paid in words : ${invoice.amountPaidInWords.endsWith(' Only') ? '${invoice.amountPaidInWords}.' : (invoice.amountPaidInWords.endsWith(' Only.') ? invoice.amountPaidInWords : '${invoice.amountPaidInWords} Only.')}",
                        fontWeight: _getDocxWeight(bodyStyle.fontWeight),
                        color: _getDocxColor(bodyStyle.textColor),
                        fontSize: bodyStyle.fontSize,
                        fontFamily: bodyStyle.fontFamily,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      DocxTableRow _totalsRow(
        String label,
        String value, {
        bool isBold = false,
        bool isTotalAmount = false,
      }) {
        final shading = isTotalAmount ? '000000' : null;
        final textColor = isTotalAmount
            ? whiteColor
            : _getDocxColor(tableDataStyle.textColor);
        final weight = (isBold || isTotalAmount)
            ? DocxFontWeight.bold
            : DocxFontWeight.normal;
        return DocxTableRow(
          cells: [
            DocxTableCell(
              width: (rightTotalW * 0.60).toInt(),
              shadingFill: shading,
              children: [
                DocxParagraph(
                  children: [
                    DocxText(
                      label,
                      fontWeight: weight,
                      color: textColor,
                      fontSize: tableDataStyle.fontSize,
                      fontFamily: tableDataStyle.fontFamily,
                    ),
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
                    DocxText(
                      "Rs. $value",
                      fontWeight: weight,
                      color: textColor,
                      fontSize: tableDataStyle.fontSize,
                      fontFamily: tableDataStyle.fontFamily,
                    ),
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
          borderTop: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
          borderBottom: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
          borderLeft: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
          borderRight: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
          borderInsideH: DocxBorderSide(
            style: DocxBorder.single,
            color: blackColor,
            size: 6,
          ),
          borderInsideV: DocxBorderSide(
            style: DocxBorder.single,
            color: blackColor,
            size: 6,
          ),
        ),
        rows: [
          _totalsRow("Sub Total", simpleCurrencyFmt.format(invoice.subTotal)),
          _totalsRow(
            "CGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%",
            simpleCurrencyFmt.format(invoice.cgst),
          ),
          _totalsRow(
            "SGST @ ${gstHalfRate.toStringAsFixed(gstHalfRate % 1 == 0 ? 0 : 1)}%",
            simpleCurrencyFmt.format(invoice.sgst),
          ),
          _totalsRow(
            "Total Amount",
            simpleCurrencyFmt.format(invoice.grandTotal),
            isTotalAmount: true,
          ),
          _totalsRow(
            "Advance Payment Received",
            simpleCurrencyFmt.format(invoice.advancePaid),
          ),
          _totalsRow(
            "Amount To Be Paid",
            simpleCurrencyFmt.format(invoice.grandTotal - invoice.advancePaid),
            isBold: true,
          ),
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
              DocxTableCell(
                width: spaceTotalW,
                children: [DocxParagraph(children: [])],
              ),
              DocxTableCell(width: rightTotalW, children: [totalsTable]),
            ],
          ),
        ],
      );

      document.addTable(totalsLayoutTable);
      document.p(''); // Spacer

      // -- 5. Footer Block (Ordered columns horizontally) --
      final visibleFooters = adjustedTemplate.footerSections.where((f) {
        if (!f.isVisible) return false;
        if (f.id == 'terms_conditions') {
          return adjustedTemplate.sections.firstWhere((s) => s.id == 'terms_conditions', orElse: () => SectionSchema(id: 'terms_conditions', title: '', orderIndex: 0, fields: [])).isVisible;
        }
        if (f.id == 'bank_details') {
          return adjustedTemplate.sections.firstWhere((s) => s.id == 'payment_info', orElse: () => SectionSchema(id: 'payment_info', title: '', orderIndex: 0, fields: [])).isVisible;
        }
        if (f.id == 'signature') {
          return adjustedTemplate.sections.firstWhere((s) => s.id == 'signature', orElse: () => SectionSchema(id: 'signature', title: '', orderIndex: 0, fields: [])).isVisible;
        }
        return true;
      }).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      double sum = visibleFooters.fold(0.0, (prev, f) => prev + f.widthPercent);
      if (sum == 0.0) sum = 1.0;
      
      final normalizedFooters = visibleFooters.map((f) => f.copyWith(
        widthPercent: (f.widthPercent / sum) * 100.0
      )).toList();

      final List<int> footerColWidths = [];
      for (int i = 0; i < normalizedFooters.length; i++) {
        final fSec = normalizedFooters[i];
        // Calculate cell width based on width percent
        final colTwips = (totalWidthTwips * (fSec.widthPercent / 100)).toInt();
        footerColWidths.add(colTwips);
      }

      final List<DocxTableCell> footerCells = [];

      for (int i = 0; i < normalizedFooters.length; i++) {
        final fSec = normalizedFooters[i];
        final colW = footerColWidths[i];

        final cellParagraphs = <DocxParagraph>[];

        if (fSec.id == 'terms_conditions') {
          cellParagraphs.add(
            DocxParagraph(
              children: [
                DocxText(
                  fSec.title.toUpperCase(),
                  color:
                      _getDocxColor(sectionTitleStyle.textColor) ??
                      primaryGreen,
                  fontWeight: _getDocxWeight(sectionTitleStyle.fontWeight),
                  fontSize: sectionTitleStyle.fontSize,
                  fontFamily: sectionTitleStyle.fontFamily,
                ),
              ],
            ),
          );
          for (final term in termsList) {
            cellParagraphs.add(
              DocxParagraph(
                children: [
                  DocxText(
                    term,
                    fontSize: footerStyle.fontSize,
                    color: _getDocxColor(footerStyle.textColor),
                    fontFamily: footerStyle.fontFamily,
                  ),
                ],
              ),
            );
          }
        } else if (fSec.id == 'bank_details') {
          cellParagraphs.add(
            DocxParagraph(
              children: [
                DocxText(
                  fSec.title.toUpperCase(),
                  color:
                      _getDocxColor(sectionTitleStyle.textColor) ??
                      primaryGreen,
                  fontWeight: _getDocxWeight(sectionTitleStyle.fontWeight),
                  fontSize: sectionTitleStyle.fontSize,
                  fontFamily: sectionTitleStyle.fontFamily,
                ),
              ],
            ),
          );

          DocxTableRow _bankItemRow(String label, String value, int tableW) {
            return DocxTableRow(
              cells: [
                DocxTableCell(
                  width: (tableW * 0.40).toInt(),
                  children: [
                    DocxParagraph(
                      children: [
                        DocxText(
                          '$label:',
                          fontWeight: DocxFontWeight.bold,
                          fontSize: footerStyle.fontSize,
                          fontFamily: footerStyle.fontFamily,
                          color: _getDocxColor(footerStyle.textColor),
                        ),
                      ],
                    ),
                  ],
                ),
                DocxTableCell(
                  width: (tableW * 0.60).toInt(),
                  children: [
                    DocxParagraph(
                      children: [
                        DocxText(
                          value,
                          fontSize: footerStyle.fontSize,
                          fontFamily: footerStyle.fontFamily,
                          color: _getDocxColor(footerStyle.textColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          }

          final bankTable = DocxTable(
            width: colW,
            widthType: DocxWidthType.dxa,
            style: DocxTableStyle.plain,
            rows: [
              _bankItemRow("Account Name", bankAccountName.toString(), colW),
              _bankItemRow("Bank Name", bankName.toString(), colW),
              _bankItemRow("Account No", bankAccountNo.toString(), colW),
              _bankItemRow("IFSC Code", bankIfsc.toString(), colW),
            ],
          );
          cellParagraphs.add(DocxParagraph(children: [])); // spacing
          // We can't nest tables inside table cells directly easily in DocxTable API sometimes,
          // so let's write paragraphs for bank info instead of nested tables to be safe!
          cellParagraphs.add(
            DocxParagraph(
              children: [
                DocxText(
                  "Account Name: $bankAccountName",
                  fontSize: footerStyle.fontSize,
                  fontFamily: footerStyle.fontFamily,
                  color: _getDocxColor(footerStyle.textColor),
                ),
              ],
            ),
          );
          cellParagraphs.add(
            DocxParagraph(
              children: [
                DocxText(
                  "Bank Name: $bankName",
                  fontSize: footerStyle.fontSize,
                  fontFamily: footerStyle.fontFamily,
                  color: _getDocxColor(footerStyle.textColor),
                ),
              ],
            ),
          );
          cellParagraphs.add(
            DocxParagraph(
              children: [
                DocxText(
                  "Account No: $bankAccountNo",
                  fontSize: footerStyle.fontSize,
                  fontFamily: footerStyle.fontFamily,
                  color: _getDocxColor(footerStyle.textColor),
                ),
              ],
            ),
          );
          cellParagraphs.add(
            DocxParagraph(
              children: [
                DocxText(
                  "IFSC Code: $bankIfsc",
                  fontSize: footerStyle.fontSize,
                  fontFamily: footerStyle.fontFamily,
                  color: _getDocxColor(footerStyle.textColor),
                ),
              ],
            ),
          );
        } else {
          // signature
          cellParagraphs.add(
            DocxParagraph(
              align: DocxAlign.center,
              children: [
                DocxText(
                  "FOR ${companyName.toUpperCase()}",
                  fontWeight: DocxFontWeight.bold,
                  fontSize: 7.5,
                  color: primaryBlue,
                  fontFamily: 'Times New Roman',
                ),
              ],
            ),
          );
          cellParagraphs.add(
            DocxParagraph(
              align: DocxAlign.center,
              children: [
                DocxText(
                  "This is a computer-generated invoice.",
                  fontSize: 5.5,
                  color: DocxColor('555555'),
                  fontFamily: 'Times New Roman',
                ),
              ],
            ),
          );
          cellParagraphs.add(
            DocxParagraph(
              align: DocxAlign.center,
              children: [
                DocxText(
                  "Subject to applicable laws of India.",
                  fontSize: 5.5,
                  color: DocxColor('555555'),
                  fontFamily: 'Times New Roman',
                ),
              ],
            ),
          );
          cellParagraphs.add(DocxParagraph(children: [])); // spacing

          if (sigBytes != null) {
            cellParagraphs.add(
              DocxParagraph(
                align: DocxAlign.center,
                borderBottomSide: DocxBorderSide(
                  style: DocxBorder.single,
                  color: DocxColor('CCCCCC'),
                  size: 4,
                ),
                children: [
                  DocxInlineImage(
                    bytes: sigBytes,
                    extension: sigExt ?? 'png',
                    width: 60,
                    height: 22,
                  ),
                ],
              ),
            );
          } else {
            cellParagraphs.add(
              DocxParagraph(
                align: DocxAlign.center,
                borderBottomSide: DocxBorderSide(
                  style: DocxBorder.single,
                  color: DocxColor('CCCCCC'),
                  size: 4,
                ),
                children: [
                  DocxText(
                    "Abhishek Prajapati",
                    color: DocxColor('1D4ED8'),
                    fontStyle: DocxFontStyle.italic,
                    fontWeight: DocxFontWeight.bold,
                    fontSize: 10,
                    fontFamily: 'Times New Roman',
                  ),
                ],
              ),
            );
          }

          cellParagraphs.add(
            DocxParagraph(
              align: DocxAlign.center,
              children: [
                DocxText(
                  signatoryTitle.toUpperCase(),
                  fontWeight: DocxFontWeight.bold,
                  fontSize: 7,
                  color: primaryBlue,
                  fontFamily: 'Times New Roman',
                ),
              ],
            ),
          );
        }

        // Draw left borders as separator lines
        final borderLeft = i > 0
            ? DocxBorderSide(
                style: DocxBorder.single,
                color: primaryGreen,
                size: 8,
              )
            : DocxBorderSide.none();

        footerCells.add(
          DocxTableCell(
            width: colW,
            borderLeft: borderLeft,
            children: cellParagraphs,
          ),
        );
      }

      final footerLayoutTable = DocxTable(
        width: totalWidthTwips,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          borderTop: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
          borderBottom: DocxBorderSide(
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
          borderLeft: DocxBorderSide.none(),
          borderRight: DocxBorderSide.none(),
          borderInsideH: DocxBorderSide.none(),
          borderInsideV: DocxBorderSide.none(),
        ),
        rows: [DocxTableRow(cells: footerCells)],
      );

      document.addTable(footerLayoutTable);
      document.p(''); // Spacer
    } else {
      // -------------------------------------------------------------
      // Dynamic Sequential standard/transport/service layout
      // -------------------------------------------------------------
      final visibleSections =
          adjustedTemplate.sections.where((s) => s.isVisible).toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      for (final sec in visibleSections) {
        if (sec.id == 'company_details') {
          final cName = (fieldValues['company_name'] ?? company.name)
              .toString()
              .toUpperCase();
          final cAddr = fieldValues['company_address'] ?? company.address;
          final cPhone = fieldValues['company_phone'] ?? company.contactNumber;
          final cEmail = fieldValues['company_email'] ?? company.email;
          final cWeb = fieldValues['company_website'] ?? 'www.lntourism.com';
          final cPan = fieldValues['company_pan'] ?? 'AAGCL7813B';
          final cGstin = fieldValues['company_gst_in'] ?? company.gstNumber;

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
                          DocxText(
                            cName,
                            fontSize: headerStyle.fontSize,
                            fontWeight: _getDocxWeight(headerStyle.fontWeight),
                            color:
                                _getDocxColor(headerStyle.textColor) ??
                                primaryBlue,
                            fontFamily: headerStyle.fontFamily,
                          ),
                        ],
                      ),
                      DocxParagraph(
                        children: [
                          DocxText(
                            "TOURS & TRAVELS | CAR RENTAL | TRANSPORT SOLUTIONS",
                            fontSize: subheaderStyle.fontSize,
                            fontWeight: _getDocxWeight(
                              subheaderStyle.fontWeight,
                            ),
                            color:
                                _getDocxColor(subheaderStyle.textColor) ??
                                primaryOrange,
                            fontFamily: subheaderStyle.fontFamily,
                          ),
                        ],
                      ),
                      DocxParagraph(
                        children: [
                          DocxText("Office Address: $cAddr", fontSize: 8),
                        ],
                      ),
                      DocxParagraph(
                        children: [
                          DocxText(
                            "Ph: $cPhone | Email: $cEmail | Web: $cWeb",
                            fontSize: 8,
                          ),
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
                          borderTop: DocxBorderSide(
                            style: DocxBorder.single,
                            color: primaryGreen,
                            size: 8,
                          ),
                          borderBottom: DocxBorderSide(
                            style: DocxBorder.single,
                            color: primaryGreen,
                            size: 8,
                          ),
                          borderLeft: DocxBorderSide(
                            style: DocxBorder.single,
                            color: primaryGreen,
                            size: 8,
                          ),
                          borderRight: DocxBorderSide(
                            style: DocxBorder.single,
                            color: primaryGreen,
                            size: 8,
                          ),
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
                                      DocxText(
                                        "INVOICE",
                                        color: whiteColor,
                                        fontWeight: DocxFontWeight.bold,
                                        fontSize: 9.5,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          DocxTableRow(
                            cells: [
                              DocxTableCell(
                                width: (rightW * 0.45).toInt(),
                                children: [
                                  DocxParagraph(
                                    children: [
                                      DocxText(
                                        "Invoice No. :",
                                        fontWeight: DocxFontWeight.bold,
                                        fontSize: 8,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              DocxTableCell(
                                width: (rightW * 0.55).toInt(),
                                children: [
                                  DocxParagraph(
                                    children: [
                                      DocxText(
                                        invoice.invoiceNumber,
                                        fontSize: 8,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          DocxTableRow(
                            cells: [
                              DocxTableCell(
                                width: (rightW * 0.45).toInt(),
                                children: [
                                  DocxParagraph(
                                    children: [
                                      DocxText(
                                        "Invoice Date :",
                                        fontWeight: DocxFontWeight.bold,
                                        fontSize: 8,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              DocxTableCell(
                                width: (rightW * 0.55).toInt(),
                                children: [
                                  DocxParagraph(
                                    children: [
                                      DocxText(
                                        df.format(invoice.invoiceDate),
                                        fontSize: 8,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          DocxTableRow(
                            cells: [
                              DocxTableCell(
                                width: (rightW * 0.45).toInt(),
                                children: [
                                  DocxParagraph(
                                    children: [
                                      DocxText(
                                        "PAN No. :",
                                        fontWeight: DocxFontWeight.bold,
                                        fontSize: 8,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              DocxTableCell(
                                width: (rightW * 0.55).toInt(),
                                children: [
                                  DocxParagraph(
                                    children: [DocxText(cPan, fontSize: 8)],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          DocxTableRow(
                            cells: [
                              DocxTableCell(
                                width: (rightW * 0.45).toInt(),
                                children: [
                                  DocxParagraph(
                                    children: [
                                      DocxText(
                                        "GSTIN :",
                                        fontWeight: DocxFontWeight.bold,
                                        fontSize: 8,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              DocxTableCell(
                                width: (rightW * 0.55).toInt(),
                                children: [
                                  DocxParagraph(
                                    children: [DocxText(cGstin, fontSize: 8)],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );

          document.addTable(headerTable);
          document.p('');
        } else if (sec.id == 'customer_details' ||
            sec.id == 'invoice_info' ||
            sec.id == 'service_details') {
          final fields = sec.fields.where((field) => field.isVisible).toList();
          if (fields.isEmpty) continue;

          document.paragraph(
            DocxParagraph(
              borderBottomSide: DocxBorderSide(
                style: DocxBorder.single,
                color: primaryGreen,
                size: 8,
              ),
              children: [
                DocxText(
                  sec.title.toUpperCase(),
                  color:
                      _getDocxColor(sectionTitleStyle.textColor) ?? primaryBlue,
                  fontWeight: _getDocxWeight(sectionTitleStyle.fontWeight),
                  fontSize: sectionTitleStyle.fontSize,
                  fontFamily: sectionTitleStyle.fontFamily,
                ),
              ],
            ),
          );

          final cellW = (totalWidthTwips * 0.48).toInt();
          final spacerW = totalWidthTwips - cellW * 2;
          final List<DocxTableRow> fieldRows = [];

          for (int i = 0; i < fields.length; i += 2) {
            final f1 = fields[i];
            final raw1 = fieldValues[f1.id];
            final val1 = raw1 != null
                ? _formatValue(raw1, f1.valueType, df)
                : '';

            String label2 = '';
            String val2 = '';
            if (i + 1 < fields.length) {
              final f2 = fields[i + 1];
              final raw2 = fieldValues[f2.id];
              label2 = f2.label;
              val2 = raw2 != null ? _formatValue(raw2, f2.valueType, df) : '';
            }

            fieldRows.add(
              DocxTableRow(
                cells: [
                  DocxTableCell(
                    width: cellW,
                    children: [
                      DocxParagraph(
                        children: [
                          DocxText(
                            "${f1.label}: ",
                            fontWeight: _getDocxWeight(
                              subsectionTitleStyle.fontWeight,
                            ),
                            color: _getDocxColor(
                              subsectionTitleStyle.textColor,
                            ),
                            fontSize: subsectionTitleStyle.fontSize,
                            fontFamily: subsectionTitleStyle.fontFamily,
                          ),
                          DocxText(
                            val1,
                            fontSize: bodyStyle.fontSize,
                            color: _getDocxColor(bodyStyle.textColor),
                            fontFamily: bodyStyle.fontFamily,
                          ),
                        ],
                      ),
                    ],
                  ),
                  DocxTableCell(
                    width: spacerW,
                    children: [DocxParagraph(children: [])],
                  ),
                  DocxTableCell(
                    width: cellW,
                    children: [
                      label2.isNotEmpty
                          ? DocxParagraph(
                              children: [
                                DocxText(
                                  "$label2: ",
                                  fontWeight: _getDocxWeight(
                                    subsectionTitleStyle.fontWeight,
                                  ),
                                  color: _getDocxColor(
                                    subsectionTitleStyle.textColor,
                                  ),
                                  fontSize: subsectionTitleStyle.fontSize,
                                  fontFamily: subsectionTitleStyle.fontFamily,
                                ),
                                DocxText(
                                  val2,
                                  fontSize: bodyStyle.fontSize,
                                  color: _getDocxColor(bodyStyle.textColor),
                                  fontFamily: bodyStyle.fontFamily,
                                ),
                              ],
                            )
                          : DocxParagraph(children: []),
                    ],
                  ),
                ],
              ),
            );
          }

          document.addTable(
            DocxTable(
              width: totalWidthTwips,
              widthType: DocxWidthType.dxa,
              style: DocxTableStyle.plain,
              rows: fieldRows,
            ),
          );
          document.p('');
        } else if (sec.id == 'items_table') {
          final visibleColsStandard =
              adjustedTemplate.tableColumns.where((c) => c.isVisible).toList()
                ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

          final List<int> colWidthsStandard = visibleColsStandard.map((c) {
            return (totalWidthTwips * (c.width / adjustedTemplate.pageWidth))
                .toInt();
          }).toList();

          final List<DocxTableRow> tblRows = [];
          // Header
          tblRows.add(
            DocxTableRow(
              cells: List.generate(visibleColsStandard.length, (idx) {
                final col = visibleColsStandard[idx];
                return DocxTableCell(
                  width: colWidthsStandard[idx],
                  shadingFill: '499F34',
                  children: [
                    DocxParagraph(
                      align: DocxAlign.center,
                      children: [
                        DocxText(
                          col.label,
                          color:
                              _getDocxColor(tableHeaderStyle.textColor) ??
                              whiteColor,
                          fontWeight: _getDocxWeight(
                            tableHeaderStyle.fontWeight,
                          ),
                          fontSize: tableHeaderStyle.fontSize,
                          fontFamily: tableHeaderStyle.fontFamily,
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          );

          // Body rows
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            tblRows.add(
              DocxTableRow(
                cells: List.generate(visibleColsStandard.length, (idx) {
                  final col = visibleColsStandard[idx];
                  final cellText = _getItemCellText(
                    item,
                    col,
                    i,
                    df,
                    simpleCurrencyFmt,
                  );

                  DocxAlign align = DocxAlign.left;
                  if (col.id == 's_no' ||
                      col.id == 'no_of_vehicles' ||
                      col.id == 'date' ||
                      col.id == 'qty') {
                    align = DocxAlign.center;
                  } else if (col.id == 'rate' || col.id == 'amount') {
                    align = DocxAlign.right;
                  } else {
                    align = col.alignment == 'right'
                        ? DocxAlign.right
                        : (col.alignment == 'center'
                              ? DocxAlign.center
                              : DocxAlign.left);
                  }

                  return DocxTableCell(
                    width: colWidthsStandard[idx],
                    children: [
                      DocxParagraph(
                        align: align,
                        children: [
                          DocxText(
                            cellText,
                            fontSize: tableDataStyle.fontSize,
                            color: _getDocxColor(tableDataStyle.textColor),
                            fontFamily: tableDataStyle.fontFamily,
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            );
          }

          document.addTable(
            DocxTable(
              width: totalWidthTwips,
              widthType: DocxWidthType.dxa,
              style: DocxTableStyle(
                border: DocxBorder.single,
                borderColor: '000000',
                borderWidth: 4,
              ),
              rows: tblRows,
            ),
          );
          document.p('');
        } else if (sec.id == 'tax_summary') {
          final rightW = (totalWidthTwips * 0.40).toInt();
          final leftW = totalWidthTwips - rightW;

          DocxTableRow _totalsRow(
            String label,
            String value, {
            bool isBold = false,
            bool isTotalAmount = false,
          }) {
            final shading = isTotalAmount ? '000000' : null;
            final textColor = isTotalAmount
                ? whiteColor
                : _getDocxColor(tableDataStyle.textColor);
            final weight = (isBold || isTotalAmount)
                ? DocxFontWeight.bold
                : DocxFontWeight.normal;
            return DocxTableRow(
              cells: [
                DocxTableCell(
                  width: (rightW * 0.60).toInt(),
                  shadingFill: shading,
                  children: [
                    DocxParagraph(
                      children: [
                        DocxText(
                          label,
                          fontWeight: weight,
                          color: textColor,
                          fontSize: tableDataStyle.fontSize,
                          fontFamily: tableDataStyle.fontFamily,
                        ),
                      ],
                    ),
                  ],
                ),
                DocxTableCell(
                  width: (rightW * 0.40).toInt(),
                  shadingFill: shading,
                  children: [
                    DocxParagraph(
                      align: DocxAlign.right,
                      children: [
                        DocxText(
                          "Rs. $value",
                          fontWeight: weight,
                          color: textColor,
                          fontSize: tableDataStyle.fontSize,
                          fontFamily: tableDataStyle.fontFamily,
                        ),
                      ],
                    ),
                  ],
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
              _totalsRow(
                "Sub Total",
                simpleCurrencyFmt.format(invoice.subTotal),
              ),
              _totalsRow("CGST", simpleCurrencyFmt.format(invoice.cgst)),
              _totalsRow("SGST", simpleCurrencyFmt.format(invoice.sgst)),
              _totalsRow(
                "Total Amount",
                simpleCurrencyFmt.format(invoice.grandTotal),
                isTotalAmount: true,
              ),
              _totalsRow(
                "Advance Paid",
                simpleCurrencyFmt.format(invoice.advancePaid),
              ),
              _totalsRow(
                "Amount To Be Paid",
                simpleCurrencyFmt.format(balance),
                isBold: true,
              ),
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
                          DocxText(
                            "Amount to be paid in words: ",
                            fontWeight: DocxFontWeight.bold,
                            fontSize: 8,
                          ),
                          DocxText(invoice.amountPaidInWords, fontSize: 8),
                        ],
                      ),
                    ],
                  ),
                  DocxTableCell(width: rightW, children: [summaryTable]),
                ],
              ),
            ],
          );

          document.addTable(summaryLayout);
          document.p('');
        } else if (sec.id == 'payment_info') {
          document.paragraph(
            DocxParagraph(
              borderBottomSide: DocxBorderSide(
                style: DocxBorder.single,
                color: primaryGreen,
                size: 8,
              ),
              children: [
                DocxText(
                  sec.title.toUpperCase(),
                  color:
                      _getDocxColor(sectionTitleStyle.textColor) ?? primaryBlue,
                  fontWeight: _getDocxWeight(sectionTitleStyle.fontWeight),
                  fontSize: sectionTitleStyle.fontSize,
                  fontFamily: sectionTitleStyle.fontFamily,
                ),
              ],
            ),
          );

          document.p("Account Name: $bankAccountName");
          document.p("Bank Name: $bankName");
          document.p("Account Number: $bankAccountNo");
          document.p("IFSC Code: $bankIfsc");
          document.p('');
        } else if (sec.id == 'terms_conditions') {
          document.paragraph(
            DocxParagraph(
              borderBottomSide: DocxBorderSide(
                style: DocxBorder.single,
                color: primaryGreen,
                size: 8,
              ),
              children: [
                DocxText(
                  sec.title.toUpperCase(),
                  color:
                      _getDocxColor(sectionTitleStyle.textColor) ?? primaryBlue,
                  fontWeight: _getDocxWeight(sectionTitleStyle.fontWeight),
                  fontSize: sectionTitleStyle.fontSize,
                  fontFamily: sectionTitleStyle.fontFamily,
                ),
              ],
            ),
          );

          for (final term in termsList) {
            document.p(term);
          }
          document.p('');
        } else if (sec.id == 'signature') {
          final sigTable = DocxTable(
            width: totalWidthTwips,
            widthType: DocxWidthType.dxa,
            style: DocxTableStyle.plain,
            rows: [
              DocxTableRow(
                cells: [
                  DocxTableCell(
                    width: (totalWidthTwips * 0.6).toInt(),
                    children: [DocxParagraph(children: [])],
                  ),
                  DocxTableCell(
                    width: (totalWidthTwips * 0.4).toInt(),
                    children: [
                      DocxParagraph(
                        align: DocxAlign.center,
                        children: [
                          DocxText(
                            "FOR ${company.name.toUpperCase()}",
                            fontWeight: DocxFontWeight.bold,
                            fontSize: 8.5,
                            color: primaryBlue,
                          ),
                        ],
                      ),
                      sigBytes != null
                          ? DocxParagraph(
                              align: DocxAlign.center,
                              children: [
                                DocxInlineImage(
                                  bytes: sigBytes,
                                  extension: sigExt ?? 'png',
                                  width: 60,
                                  height: 25,
                                ),
                              ],
                            )
                          : DocxParagraph(children: []),
                      DocxParagraph(
                        align: DocxAlign.center,
                        borderBottomSide: DocxBorderSide(
                          style: DocxBorder.single,
                          color: DocxColor('CCCCCC'),
                          size: 4,
                        ),
                        children: [
                          DocxText(
                            company.name.split(' ').first,
                            fontStyle: DocxFontStyle.italic,
                            fontWeight: DocxFontWeight.bold,
                            fontSize: 10,
                            color: primaryBlue,
                          ),
                        ],
                      ),
                      DocxParagraph(
                        align: DocxAlign.center,
                        children: [
                          DocxText(
                            signatoryTitle.toUpperCase(),
                            fontWeight: DocxFontWeight.bold,
                            fontSize: 7.5,
                            color: primaryBlue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );

          document.addTable(sigTable);
        }
      }
    }

    final builtDoc = document.build();
    final bytes = await DocxExporter().exportToBytes(builtDoc);
    return Uint8List.fromList(bytes);
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

  static DocxColor? _getDocxColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '').trim();
      return DocxColor(clean);
    } catch (_) {
      return null;
    }
  }

  static DocxFontWeight _getDocxWeight(String weight) {
    return weight == 'bold' ? DocxFontWeight.bold : DocxFontWeight.normal;
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
