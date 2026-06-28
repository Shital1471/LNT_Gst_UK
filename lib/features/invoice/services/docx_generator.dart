import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
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
    final bankBranch = fieldValues['bank_branch'] ?? '';

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
    final double leftMarginVal = isTourism ? 15 : adjustedTemplate.marginLeft;
    final double rightMarginVal = isTourism ? 15 : adjustedTemplate.marginRight;
    final double topMarginVal = isTourism ? 15 : adjustedTemplate.marginTop;
    final double bottomMarginVal = isTourism ? 15 : adjustedTemplate.marginBottom;

    document.section(
      pageSize: DocxPageSize.a4,
      orientation: DocxPageOrientation.portrait,
      marginTop: (topMarginVal * 20).toInt(),
      marginBottom: (bottomMarginVal * 20).toInt(),
      marginLeft: (leftMarginVal * 20).toInt(),
      marginRight: (rightMarginVal * 20).toInt(),
    );

    // Calculate available page width in twips
    final int totalWidthTwips =
        ((adjustedTemplate.pageWidth - leftMarginVal - rightMarginVal) * 20).toInt();

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

    final String signatureType = fieldValues['signature_type']?.toString() ?? 'company';
    final String signatureText = fieldValues['signature_text']?.toString() ?? 'Abhishek Prajapati';
    final String? signatureImagePath = fieldValues['signature_image_path']?.toString();

    if (signatureType == 'upload' && signatureImagePath != null && signatureImagePath.isNotEmpty) {
      try {
        final file = File(signatureImagePath);
        if (await file.exists()) {
          sigBytes = await file.readAsBytes();
          sigExt = signatureImagePath.split('.').last.toLowerCase();
        }
      } catch (_) {}
    } else if (signatureType == 'company') {
      if (company.signaturePath != null && company.signaturePath!.isNotEmpty) {
        try {
          final file = File(company.signaturePath!);
          if (await file.exists()) {
            sigBytes = await file.readAsBytes();
            sigExt = company.signaturePath!.split('.').last.toLowerCase();
          }
        } catch (_) {}
      }
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

      final customerSec = adjustedTemplate.sections.firstWhere(
        (s) => s.id == 'customer_details',
        orElse: () => SectionSchema(
          id: 'customer_details',
          title: 'BILL TO',
          orderIndex: 1,
          fields: [],
        ),
      );
      final serviceSec = adjustedTemplate.sections.firstWhere(
        (s) => s.id == 'service_details',
        orElse: () => SectionSchema(
          id: 'service_details',
          title: 'SERVICE DETAILS',
          orderIndex: 3,
          fields: [],
        ),
      );

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
              width: (rightColWidth * 0.43).toInt(),
              children: [
                DocxParagraph(
                  spacingBefore: 0,
                  spacingAfter: 0,
                  children: [
                    DocxText(
                      label,
                      fontWeight: DocxFontWeight.bold,
                      fontSize: 8,
                      fontFamily: 'Times New Roman',
                    ),
                  ],
                ),
              ],
            ),
            DocxTableCell(
              width: (rightColWidth * 0.57).toInt(),
              children: [
                DocxParagraph(
                  spacingBefore: 0,
                  spacingAfter: 0,
                  children: [
                    DocxText(
                      value.isEmpty ? '' : ':  $value',
                      fontSize: 8,
                      fontFamily: 'Times New Roman',
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      }

      // --- Single Header Table: Company Details + Logo (Row 1), Address (Row 2), Green Divider, and Invoice Details ---
      final int leftAreaW = (totalWidthTwips * 0.65).toInt();
      final int col1Width = (leftAreaW * 0.70).toInt();
      final int col2Width = leftAreaW - col1Width;
      final int col3Width = (totalWidthTwips * 0.02).toInt();
      final int col4Width = totalWidthTwips - leftAreaW - col3Width;

      final companyDetailsTableCellChildren = <DocxParagraph>[
        DocxParagraph(
          spacingBefore: 0,
          spacingAfter: 0,
          children: [
            DocxText(
              companyName,
              fontSize: 10,
              fontWeight: _getDocxWeight(headerStyle.fontWeight),
              color: _getDocxColor(headerStyle.textColor) ?? primaryBlue,
              fontFamily: headerStyle.fontFamily,
            ),
          ],
        ),
        DocxParagraph(
          spacingBefore: 0,
          spacingAfter: 0,
          children: [
            DocxText(
              tagline,
              fontSize: subheaderStyle.fontSize,
              fontWeight: _getDocxWeight(subheaderStyle.fontWeight),
              color: _getDocxColor(subheaderStyle.textColor) ?? primaryOrange,
              fontFamily: subheaderStyle.fontFamily,
            ),
          ],
        ),
        DocxParagraph(
          spacingBefore: 0,
          spacingAfter: 0,
          children: [
            DocxText(
              phone.toString(),
              fontSize: 7.5,
              fontWeight: DocxFontWeight.bold,
              color: primaryOrange,
              fontFamily: 'Times New Roman',
            ),
          ],
        ),
        DocxParagraph(
          spacingBefore: 0,
          spacingAfter: 0,
          children: [
            DocxText(
              email.toString(),
              fontSize: 7.5,
              fontWeight: DocxFontWeight.bold,
              color: primaryOrange,
              fontFamily: 'Times New Roman',
            ),
          ],
        ),
        DocxParagraph(
          spacingBefore: 0,
          spacingAfter: 0,
          children: [
            DocxText(
              web.toString(),
              fontSize: 7.5,
              fontWeight: DocxFontWeight.bold,
              color: primaryOrange,
              fontFamily: 'Times New Roman',
            ),
          ],
        ),
      ];

      final logoTableCellChildren = <DocxParagraph>[];
      if (logoBytes != null) {
        logoTableCellChildren.add(
          DocxParagraph(
            align: DocxAlign.center,
            spacingBefore: 0,
            spacingAfter: 0,
            children: [
              DocxInlineImage(
                bytes: logoBytes,
                extension: logoExt ?? 'png',
                width: 100.0 * template.headerConfig.logoSize,
                height: 45.0 * template.headerConfig.logoSize,
              ),
            ],
          ),
        );
      } else {
        logoTableCellChildren.add(
          DocxParagraph(
            align: DocxAlign.center,
            spacingBefore: 0,
            spacingAfter: 0,
            children: [
              DocxText(
                'LN TOURISM',
                fontWeight: DocxFontWeight.bold,
                fontSize: 10,
                color: primaryBlue,
                fontFamily: 'Times New Roman',
              ),
            ],
          ),
        );
      }

      final leftAreaTable = DocxTable(
        width: leftAreaW,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          cellPadding: 0,
          border: DocxBorder.none,
        ),
        rows: [
          DocxTableRow(
            cells: [
              DocxTableCell(
                width: col1Width,
                children: companyDetailsTableCellChildren,
              ),
              DocxTableCell(
                width: col2Width,
                children: logoTableCellChildren,
              ),
            ],
          ),
          DocxTableRow(
            cells: [
              DocxTableCell(
                width: leftAreaW,
                colSpan: 2,
                children: [
                  DocxParagraph(
                    spacingBefore: 0,
                    spacingAfter: 0,
                    children: [
                      DocxText(
                        "Office Address : $address",
                        fontSize: 7.5,
                        fontFamily: 'Times New Roman',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final invoiceBoxTable = DocxTable(
        width: col4Width,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          cellPadding: 40,
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
                    spacingBefore: 0,
                    spacingAfter: 0,
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
      );

      final headerTable = DocxTable(
        width: totalWidthTwips,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          cellPadding: 40,
          borderTop: DocxBorderSide(
            style: DocxBorder.dashed,
            color: greyBorderColor,
            size: 4,
          ),
          borderBottom: DocxBorderSide(
            style: DocxBorder.dashed,
            color: greyBorderColor,
            size: 4,
          ),
          borderLeft: DocxBorderSide.none(),
          borderRight: DocxBorderSide.none(),
          borderInsideH: DocxBorderSide.none(),
          borderInsideV: DocxBorderSide.none(),
        ),
        rows: [
          DocxTableRow(
            cells: [
              DocxTableCell(
                width: leftAreaW,
                children: [
                  leftAreaTable,
                ],
              ),
              DocxTableCell(
                width: col3Width,
                borderLeft: DocxBorderSide(
                  style: DocxBorder.thick,
                  color: primaryGreen,
                  size: 12,
                ),
                children: [DocxParagraph(spacingBefore: 0, spacingAfter: 0, children: [])],
              ),
              DocxTableCell(
                width: col4Width,
                children: [
                  invoiceBoxTable,
                ],
              ),
            ],
          ),
        ],
      );

      document.addTable(headerTable);
      
      // Tight precise spacer gap matching the template's dynamic sectionGap
      document.paragraph(
        DocxParagraph(
          spacingBefore: 0,
          spacingAfter: (adjustedTemplate.sectionGap * 20).toInt(),
          children: [DocxText("", fontSize: 1)],
        ),
      );

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
                  spacingBefore: 0,
                  spacingAfter: 0,
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
                  spacingBefore: 0,
                  spacingAfter: 0,
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
          cellPadding: 40,
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
                    spacingBefore: 0,
                    spacingAfter: 40,
                    borderBottomSide: DocxBorderSide(
                      style: DocxBorder.single,
                      color: blackColor,
                      size: 8,
                    ),
                    children: [
                      DocxText(
                        customerSec.title.toUpperCase(),
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
                    style: DocxTableStyle(
                      border: DocxBorder.none,
                      cellPadding: 20,
                    ),
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
                children: [DocxParagraph(spacingBefore: 0, spacingAfter: 0, children: [])],
              ),
              // SERVICE DETAIL Column
              DocxTableCell(
                width: colWidth,
                children: [
                  DocxParagraph(
                    spacingBefore: 0,
                    spacingAfter: 40,
                    borderBottomSide: DocxBorderSide(
                      style: DocxBorder.single,
                      color: blackColor,
                      size: 8,
                    ),
                    children: [
                      DocxText(
                        serviceSec.title.toUpperCase(),
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
                    style: DocxTableStyle(
                      border: DocxBorder.none,
                      cellPadding: 20,
                    ),
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
      
      // Tight precise spacer gap matching the template's dynamic sectionGap
      document.paragraph(
        DocxParagraph(
          spacingBefore: 0,
          spacingAfter: (adjustedTemplate.sectionGap * 20).toInt(),
          children: [DocxText("", fontSize: 1)],
        ),
      );

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
                  spacingBefore: 0,
                  spacingAfter: 0,
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
                    spacingBefore: 0,
                    spacingAfter: 0,
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
          cellPadding: 70,
        ),
        rows: tblRows,
      );

      document.addTable(itemsTable);
      
      // Tight precise spacer gap matching the template's dynamic sectionGap
      document.paragraph(
        DocxParagraph(
          spacingBefore: 0,
          spacingAfter: (adjustedTemplate.sectionGap * 20).toInt(),
          children: [DocxText("", fontSize: 1)],
        ),
      );

      // -- 4. Totals Block --
      final int leftTotalW = (totalWidthTwips * 0.55).toInt();
      final int rightTotalW = (totalWidthTwips * 0.40).toInt();
      final int spaceTotalW = totalWidthTwips - leftTotalW - rightTotalW;

      final wordsTable = DocxTable(
        width: totalWidthTwips,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          cellPadding: 60,
          borderTop: DocxBorderSide.none(),
          borderBottom: DocxBorderSide(
            style: DocxBorder.dotted,
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
              DocxTableCell(
                width: totalWidthTwips,
                children: [
                  DocxParagraph(
                    spacingBefore: 0,
                    spacingAfter: 0,
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
                  spacingBefore: 0,
                  spacingAfter: 0,
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
                  spacingBefore: 0,
                  spacingAfter: 0,
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
          cellPadding: 50,
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
            style: DocxBorder.dashed,
            color: blackColor,
            size: 6,
          ),
          borderInsideV: DocxBorderSide(
            style: DocxBorder.dashed,
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
        style: DocxTableStyle(
          cellPadding: 0,
          border: DocxBorder.none,
        ),
        rows: [
          DocxTableRow(
            cells: [
              DocxTableCell(
                width: leftTotalW + spaceTotalW,
                children: [DocxParagraph(spacingBefore: 0, spacingAfter: 0, children: [])],
              ),
              DocxTableCell(
                width: rightTotalW,
                children: [
                  totalsTable,
                ],
              ),
            ],
          ),
        ],
      );

      document.addTable(totalsLayoutTable);
      
      // Tight precise spacer gap matching the template's dynamic sectionGap
      document.paragraph(
        DocxParagraph(
          spacingBefore: 0,
          spacingAfter: (adjustedTemplate.sectionGap * 20).toInt(),
          children: [DocxText("", fontSize: 1)],
        ),
      );

      // Add Words Box Table below the subtotal / totals table block
      document.addTable(wordsTable);

      // Tight precise spacer gap matching the template's dynamic sectionGap
      document.paragraph(
        DocxParagraph(
          spacingBefore: 0,
          spacingAfter: (adjustedTemplate.sectionGap * 20).toInt(),
          children: [DocxText("", fontSize: 1)],
        ),
      );

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
              spacingBefore: 0,
              spacingAfter: 40,
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
                spacingBefore: 0,
                spacingAfter: 10,
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
              spacingBefore: 0,
              spacingAfter: 40,
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

          void _addBankField(String label, String value) {
            cellParagraphs.add(
              DocxParagraph(
                spacingBefore: 0,
                spacingAfter: 20,
                children: [
                  DocxText(
                    "$label: ",
                    fontWeight: DocxFontWeight.bold,
                    fontSize: footerStyle.fontSize,
                    fontFamily: footerStyle.fontFamily,
                    color: _getDocxColor(footerStyle.textColor),
                  ),
                  DocxText(
                    value,
                    fontSize: footerStyle.fontSize,
                    fontFamily: footerStyle.fontFamily,
                    color: _getDocxColor(footerStyle.textColor),
                  ),
                ],
              ),
            );
          }

          _addBankField("Account Name", bankAccountName.toString());
          _addBankField("Bank Name", bankName.toString());
          _addBankField("Account No", bankAccountNo.toString());
          _addBankField("IFSC Code", bankIfsc.toString());
          if (bankBranch.isNotEmpty) {
            _addBankField("Branch", bankBranch.toString());
          }
        } else {
          // signature
          cellParagraphs.add(
            DocxParagraph(
              align: DocxAlign.center,
              spacingBefore: 0,
              spacingAfter: 20,
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
              spacingBefore: 0,
              spacingAfter: 0,
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
              spacingBefore: 0,
              spacingAfter: 20,
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

          if (sigBytes != null) {
            cellParagraphs.add(
              DocxParagraph(
                align: DocxAlign.center,
                spacingBefore: 10,
                spacingAfter: 10,
                borderBottomSide: DocxBorderSide(
                  style: DocxBorder.single,
                  color: DocxColor('CCCCCC'),
                  size: 4,
                ),
                children: [
                  DocxInlineImage(
                    bytes: sigBytes,
                    extension: sigExt ?? 'png',
                    width: 60.0,
                    height: 22.0,
                  ),
                ],
              ),
            );
          } else {
            cellParagraphs.add(
              DocxParagraph(
                align: DocxAlign.center,
                spacingBefore: 10,
                spacingAfter: 10,
                borderBottomSide: DocxBorderSide(
                  style: DocxBorder.single,
                  color: DocxColor('CCCCCC'),
                  size: 4,
                ),
                children: [
                  DocxText(
                    signatureText,
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
              spacingBefore: 10,
              spacingAfter: 0,
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

        footerCells.add(
          DocxTableCell(
            width: colW,
            children: cellParagraphs,
          ),
        );
      }

      final footerLayoutTable = DocxTable(
        width: totalWidthTwips,
        widthType: DocxWidthType.dxa,
        style: DocxTableStyle(
          cellPadding: 60,
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
          borderLeft: DocxBorderSide.none(),
          borderRight: DocxBorderSide.none(),
          borderInsideH: DocxBorderSide.none(),
          borderInsideV: DocxBorderSide(
            style: DocxBorder.single,
            color: primaryGreen,
            size: 8,
          ),
        ),
        rows: [DocxTableRow(cells: footerCells)],
      );

      document.addTable(footerLayoutTable);
      document.paragraph(DocxParagraph(spacingBefore: 0, spacingAfter: 40, children: []));
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

          final showLogo = adjustedTemplate.headerConfig.logoIsVisible && logoBytes != null;
          final int leftW = (totalWidthTwips * (showLogo ? 0.50 : 0.65)).toInt();
          final int middleW = showLogo ? (totalWidthTwips * 0.16).toInt() : 0;
          final int rightW = totalWidthTwips - leftW - middleW;

          final List<DocxTableCell> headerCells = [
            // Left company details
            DocxTableCell(
              width: leftW,
              children: [
                DocxParagraph(
                  spacingBefore: 0,
                  spacingAfter: 20,
                  children: [
                    DocxText(
                      cName,
                      fontSize: headerStyle.fontSize,
                      fontWeight: _getDocxWeight(headerStyle.fontWeight),
                      color: _getDocxColor(headerStyle.textColor) ?? primaryBlue,
                      fontFamily: headerStyle.fontFamily,
                    ),
                  ],
                ),
                DocxParagraph(
                  spacingBefore: 0,
                  spacingAfter: 10,
                  children: [
                    DocxText(
                      "Ph: $cPhone",
                      fontSize: subheaderStyle.fontSize,
                      fontFamily: subheaderStyle.fontFamily,
                      color: _getDocxColor(subheaderStyle.textColor) ?? DocxColor('555555'),
                    ),
                  ],
                ),
                DocxParagraph(
                  spacingBefore: 0,
                  spacingAfter: 10,
                  children: [
                    DocxText(
                      "Email: $cEmail   Web: $cWeb",
                      fontSize: subheaderStyle.fontSize,
                      fontFamily: subheaderStyle.fontFamily,
                      color: _getDocxColor(subheaderStyle.textColor) ?? DocxColor('555555'),
                    ),
                  ],
                ),
                DocxParagraph(
                  spacingBefore: 0,
                  spacingAfter: 0,
                  children: [
                    DocxText(
                      "Office Address: $cAddr",
                      fontSize: subheaderStyle.fontSize,
                      fontFamily: subheaderStyle.fontFamily,
                      color: _getDocxColor(subheaderStyle.textColor) ?? DocxColor('555555'),
                    ),
                  ],
                ),
              ],
            ),
          ];

          if (showLogo) {
            headerCells.add(
              DocxTableCell(
                width: middleW,
                children: [
                  DocxParagraph(
                    align: DocxAlign.center,
                    spacingBefore: 0,
                    spacingAfter: 0,
                    children: [
                      DocxInlineImage(
                        bytes: logoBytes!,
                        extension: logoExt ?? 'png',
                        width: 60.0 * adjustedTemplate.headerConfig.logoSize,
                        height: 35.0 * adjustedTemplate.headerConfig.logoSize,
                      ),
                    ],
                  ),
                  DocxParagraph(
                    align: DocxAlign.center,
                    spacingBefore: 10,
                    spacingAfter: 0,
                    children: [
                      DocxText(
                        "LN TOURISM",
                        fontSize: 7.0,
                        fontWeight: DocxFontWeight.bold,
                        color: primaryBlue,
                        fontFamily: 'Times New Roman',
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // Right invoice details
          final invoiceBoxTable = DocxTable(
            width: rightW,
            widthType: DocxWidthType.dxa,
            style: DocxTableStyle(
              cellPadding: 40,
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
                        spacingBefore: 0,
                        spacingAfter: 0,
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
                        spacingBefore: 0,
                        spacingAfter: 0,
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
                        spacingBefore: 0,
                        spacingAfter: 0,
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
                        spacingBefore: 0,
                        spacingAfter: 0,
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
                        spacingBefore: 0,
                        spacingAfter: 0,
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
                        spacingBefore: 0,
                        spacingAfter: 0,
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
                        spacingBefore: 0,
                        spacingAfter: 0,
                        children: [
                          DocxText(
                            cPan,
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
                        spacingBefore: 0,
                        spacingAfter: 0,
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
                        spacingBefore: 0,
                        spacingAfter: 0,
                        children: [
                          DocxText(
                            cGstin,
                            fontSize: 8,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );

          headerCells.add(
            DocxTableCell(
              width: rightW,
              children: [
                invoiceBoxTable,
              ],
            ),
          );

          final headerTable = DocxTable(
            width: totalWidthTwips,
            widthType: DocxWidthType.dxa,
            style: DocxTableStyle(
              cellPadding: 0,
              border: DocxBorder.none,
            ),
            rows: [DocxTableRow(cells: headerCells)],
          );

          document.addTable(headerTable);
          
          // Tight precise spacer gap matching the template's dynamic sectionGap
          document.paragraph(
            DocxParagraph(
              spacingBefore: 0,
              spacingAfter: (adjustedTemplate.sectionGap * 20).toInt(),
              children: [DocxText("", fontSize: 1)],
            ),
          );
        } else if (sec.id == 'customer_details' ||
            sec.id == 'invoice_info' ||
            sec.id == 'service_details') {
          final fields = sec.fields.where((field) => field.isVisible).toList();
          if (fields.isEmpty) continue;

          document.paragraph(
            DocxParagraph(
              spacingBefore: (adjustedTemplate.sectionGap * 20).toInt(),
              spacingAfter: 40,
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
                        spacingBefore: 0,
                        spacingAfter: 0,
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
                    children: [DocxParagraph(spacingBefore: 0, spacingAfter: 0, children: [])],
                  ),
                  DocxTableCell(
                    width: cellW,
                    children: [
                      label2.isNotEmpty
                          ? DocxParagraph(
                              spacingBefore: 0,
                              spacingAfter: 0,
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
                          : DocxParagraph(spacingBefore: 0, spacingAfter: 0, children: []),
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
              style: DocxTableStyle(
                cellPadding: 40,
                border: DocxBorder.none,
              ),
              rows: fieldRows,
            ),
          );
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
                      spacingBefore: 0,
                      spacingAfter: 0,
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
                        spacingBefore: 0,
                        spacingAfter: 0,
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

          // Gap before items table
          document.paragraph(
            DocxParagraph(
              spacingBefore: (adjustedTemplate.sectionGap * 20).toInt(),
              spacingAfter: 0,
              children: [DocxText("", fontSize: 1)],
            ),
          );

          document.addTable(
            DocxTable(
              width: totalWidthTwips,
              widthType: DocxWidthType.dxa,
              style: DocxTableStyle(
                border: DocxBorder.single,
                borderColor: '000000',
                borderWidth: 4,
                cellPadding: 70,
              ),
              rows: tblRows,
            ),
          );
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
                      spacingBefore: 0,
                      spacingAfter: 0,
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
                      spacingBefore: 0,
                      spacingAfter: 0,
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
              cellPadding: 50,
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
            style: DocxTableStyle(
              cellPadding: 0,
              border: DocxBorder.none,
            ),
            rows: [
              DocxTableRow(
                cells: [
                  DocxTableCell(
                    width: leftW,
                    children: [
                      DocxParagraph(
                        spacingBefore: 0,
                        spacingAfter: 0,
                        children: [
                          DocxText(
                            "Amount to be paid in words : ",
                            fontWeight: DocxFontWeight.bold,
                            fontSize: 8,
                          ),
                          DocxText(
                            invoice.amountPaidInWords.endsWith(' Only') ? '${invoice.amountPaidInWords}.' : (invoice.amountPaidInWords.endsWith(' Only.') ? invoice.amountPaidInWords : '${invoice.amountPaidInWords} Only.'),
                            fontSize: 8,
                          ),
                        ],
                      ),
                    ],
                  ),
                  DocxTableCell(
                    width: rightW,
                    children: [
                      summaryTable,
                    ],
                  ),
                ],
              ),
            ],
          );

          // Gap before tax summary layout
          document.paragraph(
            DocxParagraph(
              spacingBefore: (adjustedTemplate.sectionGap * 20).toInt(),
              spacingAfter: 0,
              children: [DocxText("", fontSize: 1)],
            ),
          );

          document.addTable(summaryLayout);
        } else if (sec.id == 'payment_info') {
          document.paragraph(
            DocxParagraph(
              spacingBefore: (adjustedTemplate.sectionGap * 20).toInt(),
              spacingAfter: 40,
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

          void _addBankField(String label, String value) {
            document.paragraph(
              DocxParagraph(
                spacingBefore: 0,
                spacingAfter: 20,
                children: [
                  DocxText(
                    "$label: ",
                    fontWeight: DocxFontWeight.bold,
                    fontSize: bodyStyle.fontSize,
                    fontFamily: bodyStyle.fontFamily,
                    color: _getDocxColor(bodyStyle.textColor),
                  ),
                  DocxText(
                    value,
                    fontSize: bodyStyle.fontSize,
                    fontFamily: bodyStyle.fontFamily,
                    color: _getDocxColor(bodyStyle.textColor),
                  ),
                ],
              ),
            );
          }

          _addBankField("Account Name", bankAccountName.toString());
          _addBankField("Bank Name", bankName.toString());
          _addBankField("Account Number", bankAccountNo.toString());
          _addBankField("IFSC Code", bankIfsc.toString());
          if (bankBranch.isNotEmpty) {
            _addBankField("Branch", bankBranch.toString());
          }
        } else if (sec.id == 'terms_conditions') {
          document.paragraph(
            DocxParagraph(
              spacingBefore: (adjustedTemplate.sectionGap * 20).toInt(),
              spacingAfter: 40,
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
            document.paragraph(
              DocxParagraph(
                spacingBefore: 0,
                spacingAfter: 20,
                children: [
                  DocxText(
                    term,
                    fontSize: bodyStyle.fontSize,
                    color: _getDocxColor(bodyStyle.textColor),
                    fontFamily: bodyStyle.fontFamily,
                  ),
                ],
              ),
            );
          }
        } else if (sec.id == 'signature') {
          final sigTable = DocxTable(
            width: totalWidthTwips,
            widthType: DocxWidthType.dxa,
            style: DocxTableStyle(
              cellPadding: 0,
              border: DocxBorder.none,
            ),
            rows: [
              DocxTableRow(
                cells: [
                  DocxTableCell(
                    width: (totalWidthTwips * 0.6).toInt(),
                    children: [DocxParagraph(spacingBefore: 0, spacingAfter: 0, children: [])],
                  ),
                  DocxTableCell(
                    width: (totalWidthTwips * 0.4).toInt(),
                    children: [
                      DocxParagraph(
                        align: DocxAlign.center,
                        spacingBefore: 0,
                        spacingAfter: 20,
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
                              spacingBefore: 0,
                              spacingAfter: 20,
                              children: [
                                DocxInlineImage(
                                  bytes: sigBytes,
                                  extension: sigExt ?? 'png',
                                  width: 60.0,
                                  height: 25.0,
                                ),
                              ],
                            )
                          : DocxParagraph(spacingBefore: 0, spacingAfter: 0, children: []),
                      DocxParagraph(
                        align: DocxAlign.center,
                        spacingBefore: 0,
                        spacingAfter: 10,
                        borderBottomSide: DocxBorderSide(
                          style: DocxBorder.single,
                          color: DocxColor('CCCCCC'),
                          size: 4,
                        ),
                        children: [
                          DocxText(
                            sigBytes != null ? "" : signatureText,
                            fontStyle: DocxFontStyle.italic,
                            fontWeight: DocxFontWeight.bold,
                            fontSize: 10,
                            color: primaryBlue,
                          ),
                        ],
                      ),
                      DocxParagraph(
                        align: DocxAlign.center,
                        spacingBefore: 10,
                        spacingAfter: 0,
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

          // Gap before signature table
          document.paragraph(
            DocxParagraph(
              spacingBefore: (adjustedTemplate.sectionGap * 20).toInt(),
              spacingAfter: 0,
              children: [DocxText("", fontSize: 1)],
            ),
          );

          document.addTable(sigTable);
        }
      }
    }

    final builtDoc = document.build();
    final bytes = await DocxExporter().exportToBytes(builtDoc);
    // Post-process: fix invalid OOXML alignment values emitted by docx_creator.
    // Microsoft Word only accepts "left"/"right"/"center"/"both" for w:jc.
    // The docx_creator library incorrectly emits "start" and "end" instead.
    final fixedBytes = fixDocxAlignmentValues(Uint8List.fromList(bytes));
    return fixedBytes;
  }

  /// Patches the word/document.xml inside a DOCX ZIP to fix two classes of
  /// OOXML corruption that Microsoft Word rejects:
  ///
  /// 1. Invalid alignment values: `w:val="start"` → `w:val="left"` and
  ///    `w:val="end"` → `w:val="right"` (emitted incorrectly by docx_creator).
  ///
  /// 2. Missing trailing paragraph in table cells that contain nested tables:
  ///    OOXML requires every `<w:tc>` to end with a `<w:p>` element. When a
  ///    cell contains a nested `<w:tbl>`, a trailing `<w:p/>` must follow it
  ///    before `</w:tc>` closes. We inject `<w:p/>` wherever this is missing.
  ///
  /// This can be called on any existing .docx file to repair it.
  static Uint8List fixDocxAlignmentValues(Uint8List docxBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(docxBytes);
      final newArchive = Archive();

      for (final file in archive) {
        if (file.isFile && file.name == 'word/document.xml') {
          String xml = utf8.decode(file.content as List<int>);

          // Fix 1: Replace w:jc alignment values emitted as CSS logical names.
          xml = xml
              .replaceAll('w:val="start"', 'w:val="left"')
              .replaceAll('w:val="end"', 'w:val="right"');

          // Fix 2: Inject missing trailing <w:p/> in cells that end with a
          // nested table. OOXML mandates a paragraph at the end of every <w:tc>.
          xml = xml.replaceAll('</w:tbl></w:tc>', '</w:tbl><w:p/></w:tc>');

          final fixedContent = utf8.encode(xml);
          newArchive.addFile(
            ArchiveFile(file.name, fixedContent.length, fixedContent),
          );
        } else {
          newArchive.addFile(file);
        }
      }

      return Uint8List.fromList(ZipEncoder().encode(newArchive)!);
    } catch (_) {
      // If patching fails for any reason, return the original bytes unchanged.
      return docxBytes;
    }
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
