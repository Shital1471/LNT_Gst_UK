import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gst_invoice/core/database/app_database.dart';
import 'package:gst_invoice/features/invoice/models/invoice_template_schema.dart';
import 'package:gst_invoice/features/invoice/views/tourism_preview_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = <MethodCall>[];
  void Function(FlutterErrorDetails)? originalOnError;

  setUp(() {
    log.clear();
    originalOnError = FlutterError.onError;

    // Intercept url_launcher platform channel calls
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'canLaunch') {
          return true;
        }
        if (methodCall.method == 'launch') {
          return true;
        }
        return null;
      },
    );
  });

  tearDown(() {
    FlutterError.onError = originalOnError;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      null,
    );
  });

  void ignoreOverflowErrors() {
    FlutterError.onError = (FlutterErrorDetails details) {
      final exceptionStr = details.exception.toString();
      final summaryStr = details.summary.toString();
      if (exceptionStr.contains('overflowed by') || summaryStr.contains('overflowed by')) {
        // Ignore overflow warnings caused by wide fallback fonts in test environments
        return;
      }
      originalOnError?.call(details);
    };
  }

  testWidgets('TourismInvoicePreviewWidget renders clickable link aesthetics and launches urls',
      (WidgetTester tester) async {
    ignoreOverflowErrors();
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const company = CompanyProfile(
      id: 1,
      name: 'LN TOURISM',
      address: '123 Street Name',
      contactNumber: '+91 88588 73018',
      email: 'abhishek@lntourism.com',
      gstNumber: '09AAACL1234F1Z2',
      bankAccountName: 'LN TOURISM',
      bankName: 'ICICI Bank',
      bankAccountNumber: '1234567890',
      bankIfscCode: 'ICIC0001234',
      defaultGstPercentage: 5.0,
    );

    final invoice = Invoice(
      id: 1,
      invoiceNumber: 'INV-2026-001',
      invoiceDate: DateTime(2026, 6, 25),
      dueDate: DateTime(2026, 7, 25),
      customerName: 'John Doe',
      customerAddress: '456 Client Avenue',
      subTotal: 1000.0,
      cgst: 25.0,
      sgst: 25.0,
      totalGst: 50.0,
      grandTotal: 1050.0,
      advancePaid: 200.0,
      amountPaidInWords: 'Eight Hundred Fifty Rupees Only',
      createdDate: DateTime(2026, 6, 25),
      templateType: 'tourism',
    );

    final template = InvoiceTemplateSchema.getTourismDefault();

    final fieldValues = {
      'company_name': 'LN TOURISM',
      'company_phone': '+91 88588 73018',
      'company_email': 'abhishek@lntourism.com',
      'company_website': 'www.lntourism.com',
      'customer_phone': '+91 99999 99999',
    };

    // Build widget in non-designer mode (isDesigner = false)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TourismInvoicePreviewWidget(
              company: company,
              invoice: invoice,
              items: const [],
              fieldValues: fieldValues,
              template: template,
              scale: 1.0,
              isDesigner: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify phone, email, and website texts exist in the widget tree
    final phoneFinder = find.text('+91 88588 73018');
    final emailFinder = find.text('abhishek@lntourism.com');
    final websiteFinder = find.text('www.lntourism.com');
    final custPhoneFinder = find.text('+91 99999 99999');

    expect(phoneFinder, findsOneWidget);
    expect(emailFinder, findsOneWidget);
    expect(websiteFinder, findsOneWidget);
    expect(custPhoneFinder, findsOneWidget);

    // Verify text style has standard link aesthetics (blue color & underline decoration)
    final Text phoneTextWidget = tester.widget<Text>(phoneFinder);
    expect(phoneTextWidget.style?.color, Colors.blue.shade700);
    expect(phoneTextWidget.style?.decoration, TextDecoration.underline);

    final Text emailTextWidget = tester.widget<Text>(emailFinder);
    expect(emailTextWidget.style?.color, Colors.blue.shade700);
    expect(emailTextWidget.style?.decoration, TextDecoration.underline);

    final Text websiteTextWidget = tester.widget<Text>(websiteFinder);
    expect(websiteTextWidget.style?.color, Colors.blue.shade700);
    expect(websiteTextWidget.style?.decoration, TextDecoration.underline);

    final Text custPhoneTextWidget = tester.widget<Text>(custPhoneFinder);
    expect(custPhoneTextWidget.style?.color, Colors.blue.shade700);
    expect(custPhoneTextWidget.style?.decoration, TextDecoration.underline);

    // Click company phone
    await tester.tap(phoneFinder);
    await tester.pumpAndSettle();

    // Click company email
    await tester.tap(emailFinder);
    await tester.pumpAndSettle();

    // Click company website
    await tester.tap(websiteFinder);
    await tester.pumpAndSettle();

    // Click customer phone
    await tester.tap(custPhoneFinder);
    await tester.pumpAndSettle();

    // Assert launcher calls
    expect(log.any((call) => call.method == 'launch' && call.arguments['url'] == 'tel:+918858873018'), true);
    expect(log.any((call) => call.method == 'launch' && call.arguments['url'] == 'mailto:abhishek@lntourism.com'), true);
    expect(log.any((call) => call.method == 'launch' && call.arguments['url'] == 'https://www.lntourism.com'), true);
    expect(log.any((call) => call.method == 'launch' && call.arguments['url'] == 'tel:+919999999999'), true);
  });

  testWidgets('TourismInvoicePreviewWidget does NOT render link aesthetics when isDesigner = true',
      (WidgetTester tester) async {
    ignoreOverflowErrors();
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const company = CompanyProfile(
      id: 1,
      name: 'LN TOURISM',
      address: '123 Street Name',
      contactNumber: '+91 88588 73018',
      email: 'abhishek@lntourism.com',
      gstNumber: '09AAACL1234F1Z2',
      bankAccountName: 'LN TOURISM',
      bankName: 'ICICI Bank',
      bankAccountNumber: '1234567890',
      bankIfscCode: 'ICIC0001234',
      defaultGstPercentage: 5.0,
    );

    final invoice = Invoice(
      id: 1,
      invoiceNumber: 'INV-2026-001',
      invoiceDate: DateTime(2026, 6, 25),
      dueDate: DateTime(2026, 7, 25),
      customerName: 'John Doe',
      customerAddress: '456 Client Avenue',
      subTotal: 1000.0,
      cgst: 25.0,
      sgst: 25.0,
      totalGst: 50.0,
      grandTotal: 1050.0,
      advancePaid: 200.0,
      amountPaidInWords: 'Eight Hundred Fifty Rupees Only',
      createdDate: DateTime(2026, 6, 25),
      templateType: 'tourism',
    );

    final template = InvoiceTemplateSchema.getTourismDefault();

    final fieldValues = {
      'company_name': 'LN TOURISM',
      'company_phone': '+91 88588 73018',
      'company_email': 'abhishek@lntourism.com',
      'company_website': 'www.lntourism.com',
      'customer_phone': '+91 99999 99999',
    };

    // Build widget in designer mode (isDesigner = true)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TourismInvoicePreviewWidget(
              company: company,
              invoice: invoice,
              items: const [],
              fieldValues: fieldValues,
              template: template,
              scale: 1.0,
              isDesigner: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final phoneFinder = find.text('+91 88588 73018');
    expect(phoneFinder, findsOneWidget);

    final Text phoneTextWidget = tester.widget<Text>(phoneFinder);
    // Colors should not be link blue and not underlined
    expect(phoneTextWidget.style?.color, isNot(Colors.blue.shade700));
    expect(phoneTextWidget.style?.decoration, isNot(TextDecoration.underline));

    // Tap should not log any launcher calls
    await tester.tap(phoneFinder);
    await tester.pumpAndSettle();

    expect(log.isEmpty, true);
  });
}
