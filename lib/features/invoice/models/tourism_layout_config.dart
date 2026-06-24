import 'invoice_template_schema.dart';

class FieldLayout {
  final double x;
  final double y;
  final double width;
  final double height;
  FieldLayout(this.x, this.y, this.width, this.height);
}

class _TourismBlock {
  final String id;
  final double orderIndex;
  final bool isVisible;
  _TourismBlock(this.id, this.orderIndex, this.isVisible);
}

class TourismLayoutConfig {
  final InvoiceTemplateSchema template;
  final int itemCount;
  final Map<String, dynamic> fieldValues;

  // Cache of calculated field coordinates
  final Map<String, FieldLayout> _fieldLayouts = {};

  // Dynamic layout calculations
  double _pageHeight = basePageHeight;
  double _headerTopLineY = 0.0;
  double _headerHeight = 110.0;
  double _headerBottomLineY = 0.0;
  double _headerDividerX = 0.0;
  double _logoX = 0.0;
  double _logoY = 0.0;
  double _logoWidth = 0.0;
  double _logoHeight = 0.0;
  double _invBoxX = 0.0;
  double _invBoxY = 0.0;
  double _invBoxWidth = 0.0;
  double _invBoxHeight = 0.0;
  double _invBoxHeaderHeight = 20.0;

  double _billToTopLineY = 0.0;
  double _billToHeight = 0.0;
  double _billToBottomLineY = 0.0;
  double _billToColumnUnderlineX1 = 0.0;
  double _billToColumnUnderlineX2 = 0.0;
  double _billToColumnUnderlineY = 0.0;
  double _serviceColumnUnderlineX1 = 0.0;
  double _serviceColumnUnderlineX2 = 0.0;
  double _serviceColumnUnderlineY = 0.0;

  double _tableStartY = 0.0;
  double _tableHeight = 0.0;
  double _tableEndY = 0.0;

  double _totalsBoxX = 0.0;
  double _totalsBoxY = 0.0;
  double _totalsBoxWidth = 0.0;
  double _totalsBoxHeight = 90.0;
  double _totalsBoxDividerX = 0.0;

  double _wordsBoxX = 0.0;
  double _wordsBoxY = 0.0;
  double _wordsBoxWidth = 0.0;
  double _wordsBoxHeight = 20.0;
  double _wordsBoxEndY = 0.0;

  double _footerTopLineY = 0.0;
  double _footerHeight = 125.0;
  double _footerBottomLineY = 0.0;

  TourismLayoutConfig(this.template, this.itemCount, [this.fieldValues = const {}]) {
    _calculateLayout();
  }

  // Static Fallback Constants for baseline settings
  static const double basePageWidth = 595.27;
  static const double basePageHeight = 841.89;
  static const double baseLeftMargin = 22.0;
  static const double baseRightMargin = 22.0;
  
  // Dynamic page measurements
  double get pageWidth => template.pageWidth;
  double get pageHeight => _pageHeight;
  double get leftMargin => template.marginLeft;
  double get rightMargin => template.marginRight;
  double get contentWidth => pageWidth - leftMargin - rightMargin;

  // Margins and Gaps
  double get sectionGap => template.sectionGap;
  double get tableGap => template.tableGap;
  double get footerGap => template.footerGap;

  // 1. Header Section
  double get headerTopLineY => _headerTopLineY;
  double get headerHeight => _headerHeight;
  double get headerBottomLineY => _headerBottomLineY;
  
  // Header dividers and widths
  double get headerDividerX => _headerDividerX;
  double get logoX => _logoX;
  double get logoY => _logoY;
  double get logoWidth => _logoWidth;
  double get logoHeight => _logoHeight;

  // Invoice Box
  double get invBoxX => _invBoxX;
  double get invBoxY => _invBoxY;
  double get invBoxWidth => _invBoxWidth;
  double get invBoxHeight => _invBoxHeight;
  double get invBoxHeaderHeight => _invBoxHeaderHeight;

  // 2. Bill To & Service Details Section
  double get billToTopLineY => _billToTopLineY;
  double get billToHeight => _billToHeight;
  double get billToBottomLineY => _billToBottomLineY;

  double get billToColumnUnderlineX1 => _billToColumnUnderlineX1;
  double get billToColumnUnderlineX2 => _billToColumnUnderlineX2;
  double get billToColumnUnderlineY => _billToColumnUnderlineY;

  double get serviceColumnUnderlineX1 => _serviceColumnUnderlineX1;
  double get serviceColumnUnderlineX2 => _serviceColumnUnderlineX2;
  double get serviceColumnUnderlineY => _serviceColumnUnderlineY;

  // 3. Service Items Table
  double get tableStartY => _tableStartY;
  double get tableHeaderHeight => 20.0;
  double get tableRowHeight => 20.0;
  double get tableHeight => _tableHeight;
  double get tableEndY => _tableEndY;

  // 4. Totals & Words Block
  double get totalsBoxX => _totalsBoxX;
  double get totalsBoxY => _totalsBoxY;
  double get totalsBoxWidth => _totalsBoxWidth;
  double get totalsBoxHeight => _totalsBoxHeight;
  double get totalsRowHeight => 15.0;
  double get totalsBoxDividerX => _totalsBoxDividerX;

  double get wordsBoxX => _wordsBoxX;
  double get wordsBoxY => _wordsBoxY;
  double get wordsBoxWidth => _wordsBoxWidth;
  double get wordsBoxHeight => _wordsBoxHeight;
  double get wordsBoxEndY => _wordsBoxEndY;

  // 5. Footer Section
  double get footerTopLineY => _footerTopLineY;
  double get footerHeight => _footerHeight;
  double get footerBottomLineY => _footerBottomLineY;

  // Signature Block Coordinates
  double get sigBoxX => leftMargin + (contentWidth * 0.72);
  double get sigBoxY => footerTopLineY + 43.0;
  double get sigBoxWidth => contentWidth * 0.22;
  double get sigBoxHeight => 40.0;
  double get sigUnderlineY => footerTopLineY + 87.0;
  double get signatoryTitleY => footerTopLineY + 93.0;

  // Helpers to get field layout coordinates
  double getFieldX(String fieldId) => _fieldLayouts[fieldId]?.x ?? 0.0;
  double getFieldY(String fieldId) => _fieldLayouts[fieldId]?.y ?? 0.0;
  double getFieldWidth(String fieldId) => _fieldLayouts[fieldId]?.width ?? 0.0;
  double getFieldHeight(String fieldId) => _fieldLayouts[fieldId]?.height ?? 0.0;

  void _calculateLayout() {
    final double contentW = contentWidth;

    // Resolve styles
    final headerStyle = template.typography['header'] ?? TextStyleSchema(fontSize: 12, fontWeight: 'bold', fontFamily: 'Times New Roman', textColor: '#0B3B60');
    final subheaderStyle = template.typography['subheader'] ?? TextStyleSchema(fontSize: 6.5, fontWeight: 'bold', fontFamily: 'Times New Roman', textColor: '#E57A25');
    final bodyStyle = template.typography['body'] ?? TextStyleSchema(fontSize: 7.5, fontWeight: 'normal', fontFamily: 'Times New Roman', textColor: '#000000');
    final subsectionTitleStyle = template.typography['subsection_title'] ?? TextStyleSchema(fontSize: 8, fontWeight: 'bold', fontFamily: 'Times New Roman', textColor: '#000000');
    final footerStyle = template.typography['footer'] ?? TextStyleSchema(fontSize: 6.5, fontWeight: 'normal', fontFamily: 'Times New Roman', textColor: '#000000');

    double getFieldHeight(FieldSchema f, TextStyleSchema style) {
      if (!f.isVisible) return 0.0;
      return (f.fontSize) * style.lineHeight + 4.0;
    }

    // Identify sections
    final companySec = template.sections.firstWhere((s) => s.id == 'company_details', orElse: () => SectionSchema(id: 'company_details', title: '', orderIndex: 0, fields: []));
    final companyFields = companySec.fields.where((f) => f.isVisible).toList();

    final invoiceSec = template.sections.firstWhere((s) => s.id == 'invoice_info', orElse: () => SectionSchema(id: 'invoice_info', title: '', orderIndex: 2, fields: []));
    final invoiceFields = invoiceSec.fields.where((f) => f.isVisible).toList();

    final customerSec = template.sections.firstWhere((s) => s.id == 'customer_details', orElse: () => SectionSchema(id: 'customer_details', title: '', orderIndex: 1, fields: []));
    final customerFields = customerSec.fields.where((f) => f.isVisible).toList();

    final serviceSec = template.sections.firstWhere((s) => s.id == 'service_details', orElse: () => SectionSchema(id: 'service_details', title: '', orderIndex: 3, fields: []));
    final serviceFields = serviceSec.fields.where((f) => f.isVisible).toList();

    final bankSec = template.sections.firstWhere((s) => s.id == 'payment_info', orElse: () => SectionSchema(id: 'payment_info', title: '', orderIndex: 6, fields: []));
    final bankFields = bankSec.fields.where((f) => f.isVisible).toList();

    final termsSec = template.sections.firstWhere((s) => s.id == 'terms_conditions', orElse: () => SectionSchema(id: 'terms_conditions', title: '', orderIndex: 7, fields: []));

    final sigSec = template.sections.firstWhere((s) => s.id == 'signature', orElse: () => SectionSchema(id: 'signature', title: '', orderIndex: 8, fields: []));

    final itemsSec = template.sections.firstWhere((s) => s.id == 'items_table', orElse: () => SectionSchema(id: 'items_table', title: '', orderIndex: 4, fields: []));
    final taxSec = template.sections.firstWhere((s) => s.id == 'tax_summary', orElse: () => SectionSchema(id: 'tax_summary', title: '', orderIndex: 5, fields: []));

    // Visibility of blocks
    final isHeaderVisible = companySec.isVisible || invoiceSec.isVisible;
    final isDetailsVisible = customerSec.isVisible || serviceSec.isVisible;
    final isTableVisible = itemsSec.isVisible;
    final isTotalsVisible = taxSec.isVisible;
    final isFooterVisible = bankSec.isVisible || termsSec.isVisible || sigSec.isVisible;

    // Sorting blocks by minimum orderIndex of their sections
    final headerIndex = companySec.orderIndex < invoiceSec.orderIndex ? companySec.orderIndex : invoiceSec.orderIndex;
    final detailsIndex = customerSec.orderIndex < serviceSec.orderIndex ? customerSec.orderIndex : serviceSec.orderIndex;
    final tableIndex = itemsSec.orderIndex;
    final totalsIndex = taxSec.orderIndex;
    
    double footerIndex = bankSec.orderIndex.toDouble();
    if (termsSec.orderIndex < footerIndex) footerIndex = termsSec.orderIndex.toDouble();
    if (sigSec.orderIndex < footerIndex) footerIndex = sigSec.orderIndex.toDouble();

    final blocks = [
      _TourismBlock('header', headerIndex.toDouble(), isHeaderVisible),
      _TourismBlock('details', detailsIndex.toDouble(), isDetailsVisible),
      _TourismBlock('table', tableIndex.toDouble(), isTableVisible),
      _TourismBlock('totals', totalsIndex.toDouble(), isTotalsVisible),
      _TourismBlock('footer', footerIndex.toDouble(), isFooterVisible),
    ]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    double currentY = template.marginTop;

    for (final block in blocks) {
      if (!block.isVisible) continue;

      if (block.id == 'header') {
        _headerTopLineY = currentY;

        double companyHeight = 8.0;
        for (final f in companyFields) {
          final style = f.id == 'company_name'
              ? headerStyle
              : (f.id == 'company_tagline' ? subheaderStyle : bodyStyle);
          final fh = getFieldHeight(f, style);
          _fieldLayouts[f.id] = FieldLayout(leftMargin, _headerTopLineY + companyHeight, contentW * 0.40, fh);
          companyHeight += fh + 2.0;
        }

        _logoX = leftMargin + (contentW * 0.43);
        _logoY = _headerTopLineY + 8.0;
        _logoWidth = 100.0 * template.headerConfig.logoSize;
        _logoHeight = 45.0 * template.headerConfig.logoSize;
        final logoTotalHeight = _logoHeight + 16.0;

        _invBoxX = leftMargin + (contentW * 0.65) + 12.0;
        _invBoxY = _headerTopLineY + 12.0;
        _invBoxWidth = contentW - (_invBoxX - leftMargin);
        _invBoxHeaderHeight = 20.0;

        double invFieldsHeight = 0.0;
        for (final f in invoiceFields) {
          final fh = getFieldHeight(f, bodyStyle);
          _fieldLayouts[f.id] = FieldLayout(_invBoxX + 6.0, _invBoxY + _invBoxHeaderHeight + 4.0 + invFieldsHeight, _invBoxWidth - 12.0, fh);
          invFieldsHeight += fh + 2.0;
        }
        _invBoxHeight = _invBoxHeaderHeight + invFieldsHeight + 8.0;

        _headerHeight = [companyHeight + 8.0, logoTotalHeight, _invBoxHeight + 12.0, template.headerConfig.headerHeight].reduce((a, b) => a > b ? a : b);
        _headerBottomLineY = _headerTopLineY + _headerHeight;
        _headerDividerX = leftMargin + (contentW * 0.65);

        currentY += _headerHeight + template.sectionGap;
      }
      else if (block.id == 'details') {
        _billToTopLineY = currentY;

        final swap = customerSec.orderIndex > serviceSec.orderIndex;

        final xLeft1 = leftMargin;
        final xLeft2 = leftMargin + (contentW * 0.48);
        final xRight1 = leftMargin + (contentW * 0.50);
        final xRight2 = pageWidth - rightMargin;

        _billToColumnUnderlineX1 = swap ? xRight1 : xLeft1;
        _billToColumnUnderlineX2 = swap ? xRight2 : xLeft2;
        _serviceColumnUnderlineX1 = swap ? xLeft1 : xRight1;
        _serviceColumnUnderlineX2 = swap ? xLeft2 : xRight2;

        _billToColumnUnderlineY = _billToTopLineY + 18.0;
        _serviceColumnUnderlineY = _billToTopLineY + 18.0;

        double customerHeight = 22.0;
        for (final f in customerFields) {
          final fh = getFieldHeight(f, subsectionTitleStyle);
          _fieldLayouts[f.id] = FieldLayout(_billToColumnUnderlineX1, _billToTopLineY + customerHeight, _billToColumnUnderlineX2 - _billToColumnUnderlineX1, fh);
          customerHeight += fh + 4.0;
        }

        double serviceHeight = 22.0;
        for (final f in serviceFields) {
          final fh = getFieldHeight(f, subsectionTitleStyle);
          _fieldLayouts[f.id] = FieldLayout(_serviceColumnUnderlineX1, _billToTopLineY + serviceHeight, _serviceColumnUnderlineX2 - _serviceColumnUnderlineX1, fh);
          serviceHeight += fh + 4.0;
        }

        _billToHeight = [customerHeight, serviceHeight, 80.0].reduce((a, b) => a > b ? a : b);
        _billToBottomLineY = _billToTopLineY + _billToHeight;

        currentY += _billToHeight + template.sectionGap;
      }
      else if (block.id == 'table') {
        _tableStartY = currentY;
        _tableHeight = tableHeaderHeight + itemCount * tableRowHeight;
        _tableEndY = _tableStartY + _tableHeight;

        currentY += _tableHeight + template.sectionGap;
      }
      else if (block.id == 'totals') {
        _totalsBoxX = leftMargin + (contentW * 0.58);
        _totalsBoxY = currentY;
        _totalsBoxWidth = contentW * 0.42;
        _totalsBoxHeight = 90.0;
        _totalsBoxDividerX = _totalsBoxX + (_totalsBoxWidth * 0.60);

        _wordsBoxX = leftMargin;
        _wordsBoxY = _totalsBoxY + _totalsBoxHeight + template.sectionGap;
        _wordsBoxWidth = contentW;
        _wordsBoxHeight = 20.0;
        _wordsBoxEndY = _wordsBoxY + _wordsBoxHeight;

        currentY += _totalsBoxHeight + template.sectionGap + _wordsBoxHeight + template.sectionGap;
      }
      else if (block.id == 'footer') {
        _footerTopLineY = currentY;

        final visibleFooters = template.footerSections.where((f) {
          if (!f.isVisible) return false;
          if (f.id == 'terms_conditions') return termsSec.isVisible;
          if (f.id == 'bank_details') return bankSec.isVisible;
          if (f.id == 'signature') return sigSec.isVisible;
          return true;
        }).toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        double sum = visibleFooters.fold(0.0, (prev, f) => prev + f.widthPercent);
        if (sum == 0.0) sum = 1.0;

        double termsHeight = 0.0;
        if (termsSec.isVisible) {
          final termsField = termsSec.fields.firstWhere((f) => f.id == 'terms_text', orElse: () => FieldSchema(id: 'terms_text', label: 'Terms', valueType: 'text'));
          final termsString = fieldValues['terms_text'] ?? termsField.defaultValue?.toString() ?? '';
          final linesCount = termsString.toString().split('\n').where((t) => t.isNotEmpty).length;
          termsHeight = 16.0 + (linesCount * (footerStyle.fontSize * footerStyle.lineHeight + 2.0));
        }

        double bankHeight = 0.0;
        if (bankSec.isVisible) {
          bankHeight = 16.0 + (bankFields.length * (footerStyle.fontSize * footerStyle.lineHeight + 4.0));
        }

        double sigHeight = sigSec.isVisible ? 100.0 : 0.0;

        _footerHeight = [termsHeight, bankHeight, sigHeight, 110.0].reduce((a, b) => a > b ? a : b);
        _footerBottomLineY = _footerTopLineY + _footerHeight;

        currentY += _footerHeight + template.sectionGap;
      }
    }

    _pageHeight = [currentY + template.marginBottom, basePageHeight].reduce((a, b) => a > b ? a : b);
  }
}
