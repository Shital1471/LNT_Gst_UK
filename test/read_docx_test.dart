import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:gst_invoice/features/invoice/services/docx_generator.dart';

void main() {
  test('Check paragraph spacing in generated DOCX', () {
    final file = File(r'C:\Users\Asus\Documents\invoices\LNT2606009.docx');
    if (!file.existsSync()) { print('File does not exist'); return; }
    final bytes = Uint8List.fromList(file.readAsBytesSync());
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final entry in archive) {
      if (entry.name == 'word/document.xml') {
        final content = String.fromCharCodes(entry.content);
        // Check for line/paragraph spacing settings
        final spacingMatches = RegExp(r'<w:spacing[^/]*/?>').allMatches(content);
        print('Spacing elements found: ${spacingMatches.length}');
        for (final m in spacingMatches.take(5)) {
          print('  ${m.group(0)}');
        }
        // Check for after/before paragraph spacing
        print('\nLooking for w:after and w:before in spacing:');
        final afterMatches = RegExp(r'w:after="(\d+)"').allMatches(content);
        for (final m in afterMatches.take(5)) {
          print('  w:after="${m.group(1)}"');
        }
        // Check document defaults
        print('\nPage section settings:');
        final sectPrMatch = RegExp(r'<w:sectPr>.*?</w:sectPr>', dotAll: true).firstMatch(content);
        if (sectPrMatch != null) print(sectPrMatch.group(0));
      }
    }
  });
}
