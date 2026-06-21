class GstCalculationResult {
  final double subTotal;
  final double cgst;
  final double sgst;
  final double totalGst;
  final double grandTotal;

  GstCalculationResult({
    required this.subTotal,
    required this.cgst,
    required this.sgst,
    required this.totalGst,
    required this.grandTotal,
  });

  factory GstCalculationResult.calculate({
    required double baseAmount,
    required double gstPercentage,
    required bool isInclusive,
  }) {
    double subTotal;
    double totalGst;
    double grandTotal;

    if (isInclusive) {
      grandTotal = baseAmount;
      subTotal = grandTotal / (1 + (gstPercentage / 100));
      totalGst = grandTotal - subTotal;
    } else {
      subTotal = baseAmount;
      totalGst = subTotal * (gstPercentage / 100);
      grandTotal = subTotal + totalGst;
    }

    // Split GST equally into CGST and SGST
    double cgst = totalGst / 2;
    double sgst = totalGst / 2;

    return GstCalculationResult(
      subTotal: _roundToTwoDecimals(subTotal),
      cgst: _roundToTwoDecimals(cgst),
      sgst: _roundToTwoDecimals(sgst),
      totalGst: _roundToTwoDecimals(totalGst),
      grandTotal: _roundToTwoDecimals(grandTotal),
    );
  }

  static double _roundToTwoDecimals(double value) {
    return (value * 100).roundToDouble() / 100.0;
  }

  @override
  String toString() {
    return 'GstCalculationResult(subTotal: $subTotal, cgst: $cgst, sgst: $sgst, totalGst: $totalGst, grandTotal: $grandTotal)';
  }
}
