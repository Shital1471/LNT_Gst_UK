import 'package:flutter_test/flutter_test.dart';
import 'package:gst_invoice/core/utils/gst_calculator.dart';
import 'package:gst_invoice/core/utils/num_to_words.dart';

void main() {
  group('GST Calculator Tests', () {
    test('Exclusive GST (Amount Without GST) Calculation', () {
      // Base Amount = 1000, GST = 5%
      final result = GstCalculationResult.calculate(
        baseAmount: 1000,
        gstPercentage: 5.0,
        isInclusive: false,
      );

      expect(result.subTotal, 1000.0);
      expect(result.cgst, 25.0);
      expect(result.sgst, 25.0);
      expect(result.totalGst, 50.0);
      expect(result.grandTotal, 1050.0);
    });

    test('Inclusive GST (Amount Including GST) Calculation', () {
      // Grand Total = 1050, GST = 5%
      final result = GstCalculationResult.calculate(
        baseAmount: 1050,
        gstPercentage: 5.0,
        isInclusive: true,
      );

      expect(result.grandTotal, 1050.0);
      expect(result.subTotal, 1000.0);
      expect(result.cgst, 25.0);
      expect(result.sgst, 25.0);
      expect(result.totalGst, 50.0);
    });
  });

  group('Number to Words Converter Tests', () {
    test('Converts flat integer rupee amount', () {
      final words = NumberToWords.convert(5000.0);
      expect(words, "Five Thousand Rupees Only");
    });

    test('Converts double rupee and paise amount', () {
      final words = NumberToWords.convert(1250.50);
      expect(words, "One Thousand Two Hundred Fifty Rupees and Fifty Paise Only");
    });

    test('Converts zero correctly', () {
      final words = NumberToWords.convert(0.0);
      expect(words, "Zero Rupees Only");
    });
  });
}
