import 'invoice_template_schema.dart';

class TourismLayoutConfig {
  final InvoiceTemplateSchema template;
  final int itemCount;

  TourismLayoutConfig(this.template, this.itemCount);

  // Static Fallback Constants for baseline settings
  static const double basePageWidth = 595.27;
  static const double basePageHeight = 841.89;
  static const double baseLeftMargin = 22.0;
  static const double baseRightMargin = 22.0;
  
  // Dynamic page measurements
  double get pageWidth => template.pageWidth;
  double get pageHeight => template.pageHeight;
  double get leftMargin => template.marginLeft;
  double get rightMargin => template.marginRight;
  double get contentWidth => pageWidth - leftMargin - rightMargin;

  // Margins and Gaps
  double get sectionGap => template.sectionGap;
  double get tableGap => template.tableGap;
  double get footerGap => template.footerGap;

  // 1. Header Section
  double get headerTopLineY => template.marginTop;
  double get headerHeight => template.headerConfig.headerHeight;
  double get headerBottomLineY => headerTopLineY + headerHeight;
  
  // Header dividers and widths
  double get headerDividerX => leftMargin + (contentWidth * 0.65);
  double get logoX => leftMargin + (contentWidth * 0.43);
  double get logoY => headerTopLineY + 8.0;
  double get logoWidth => 100.0 * template.headerConfig.logoSize;
  double get logoHeight => 45.0 * template.headerConfig.logoSize;

  // Invoice Box
  double get invBoxX => headerDividerX + 12.0;
  double get invBoxY => headerTopLineY + 12.0;
  double get invBoxWidth => contentWidth - (invBoxX - leftMargin);
  double get invBoxHeight => headerHeight - 22.0;
  double get invBoxHeaderHeight => 20.0;

  // 2. Bill To & Service Details Section
  double get billToTopLineY => headerBottomLineY + sectionGap;
  double get billToHeight => 112.0;
  double get billToBottomLineY => billToTopLineY + billToHeight;

  double get billToColumnUnderlineX1 => leftMargin;
  double get billToColumnUnderlineX2 => leftMargin + (contentWidth * 0.48);
  double get billToColumnUnderlineY => billToTopLineY + 18.0;

  double get serviceColumnUnderlineX1 => leftMargin + (contentWidth * 0.50);
  double get serviceColumnUnderlineX2 => pageWidth - rightMargin;
  double get serviceColumnUnderlineY => billToTopLineY + 18.0;

  // 3. Service Items Table
  double get tableStartY => billToBottomLineY + sectionGap;
  double get tableHeaderHeight => 20.0;
  double get tableRowHeight => 20.0;
  double get tableHeight => tableHeaderHeight + itemCount * tableRowHeight;
  double get tableEndY => tableStartY + tableHeight;

  // 4. Totals & Words Block
  double get totalsBoxX => leftMargin + (contentWidth * 0.58);
  double get totalsBoxY => tableEndY + tableGap;
  double get totalsBoxWidth => contentWidth * 0.42;
  double get totalsBoxHeight => 90.0;
  double get totalsRowHeight => 15.0;
  double get totalsBoxDividerX => totalsBoxX + (totalsBoxWidth * 0.60);

  double get wordsBoxX => leftMargin;
  double get wordsBoxY => totalsBoxY + totalsBoxHeight + sectionGap;
  double get wordsBoxWidth => contentWidth;
  double get wordsBoxHeight => 20.0;
  double get wordsBoxEndY => wordsBoxY + wordsBoxHeight;

  // 5. Footer Section
  double get footerTopLineY => wordsBoxEndY + footerGap;
  double get footerHeight => 125.0;
  double get footerBottomLineY => footerTopLineY + footerHeight;

  // Signature
  double get sigBoxX => leftMargin + (contentWidth * 0.72);
  double get sigBoxY => footerTopLineY + 43.0;
  double get sigBoxWidth => contentWidth * 0.22;
  double get sigBoxHeight => 40.0;
  double get sigUnderlineY => footerTopLineY + 87.0;
  double get signatoryTitleY => footerTopLineY + 93.0;
}
