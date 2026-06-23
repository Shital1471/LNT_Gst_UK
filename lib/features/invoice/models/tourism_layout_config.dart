class TourismLayoutConfig {
  static const double pageWidth = 595.27;
  static const double pageHeight = 841.89;
  static const double leftMargin = 22.0;
  static const double rightMargin = 22.0;
  static const double contentWidth = 551.27; // pageWidth - 2 * 22.0

  // 1. Header Section
  static const double headerTopLineY = 30.0;
  static const double headerBottomLineY = 140.0;
  static const double headerDividerX = 380.0;

  static const double logoX = 260.0;
  static const double logoY = 38.0;
  static const double logoWidth = 100.0;
  static const double logoHeight = 45.0;

  // Invoice Box
  static const double invBoxX = 392.0;
  static const double invBoxY = 42.0;
  static const double invBoxWidth = 181.0;
  static const double invBoxHeight = 88.0;
  static const double invBoxHeaderHeight = 20.0;

  // 2. Bill To & Service Details Section
  static const double billToTopLineY = 150.0;
  static const double billToBottomLineY = 262.0;

  static const double billToColumnUnderlineX1 = 22.0;
  static const double billToColumnUnderlineX2 = 285.0;
  static const double billToColumnUnderlineY = 168.0;

  static const double serviceColumnUnderlineX1 = 300.0;
  static const double serviceColumnUnderlineX2 = 573.27;
  static const double serviceColumnUnderlineY = 168.0;

  // 3. Service Items Table
  static const double tableStartY = 275.0;
  static const double tableRowHeight = 20.0;
  static const List<double> tableColumnWidths = [
    25.0,   // S No.
    135.0,  // Description of Service
    55.0,   // No. of Vehicles
    65.0,   // Date
    110.0,  // From-To
    41.27,  // Qty/Days
    55.0,   // Rate
    65.0,   // Amt
  ];

  static const List<String> tableColumnLabels = [
    "S No.",
    "Description of Service",
    "No. of Vehicles",
    "Date",
    "From-To",
    "Qty/Days",
    "Rate (Rs.)",
    "Amt (Rs.)"
  ];

  // 4. Totals & Words Block
  static const double totalsBoxX = 343.27;
  static const double totalsBoxY = 425.0;
  static const double totalsBoxWidth = 230.0;
  static const double totalsBoxHeight = 90.0;
  static const double totalsRowHeight = 15.0;
  static const double totalsBoxDividerX = 482.0;

  static const double wordsBoxX = 22.0;
  static const double wordsBoxY = 525.0;
  static const double wordsBoxWidth = 551.27;
  static const double wordsBoxHeight = 20.0;

  // 5. Footer Section
  static const double footerTopLineY = 555.0;
  static const double footerBottomLineY = 680.0;
  static const double footerDivider1X = 210.0;
  static const double footerDivider2X = 380.0;

  // Signature
  static const double sigBoxX = 420.0;
  static const double sigBoxY = 598.0;
  static const double sigBoxWidth = 120.0;
  static const double sigBoxHeight = 40.0;
  static const double sigUnderlineY = 642.0;
}
