import '../../../core/utils/gst_calculator.dart';
import 'invoice_template_schema.dart';

class InvoiceFormItem {
  final String description;
  final int? noOfVehicles; // Tourism specific (optional)
  final DateTime? date; // Tourism specific (optional)
  final String? fromTo; // Tourism specific (optional)
  final double quantityDays; // Days in tourism, quantity in standard
  final double rate;
  final Map<String, String> customValues;

  InvoiceFormItem({
    required this.description,
    this.noOfVehicles,
    this.date,
    this.fromTo,
    required this.quantityDays,
    required this.rate,
    this.customValues = const {},
  });

  double get amount {
    final vehicles = noOfVehicles ?? 1;
    return vehicles * quantityDays * rate;
  }

  InvoiceFormItem copyWith({
    String? description,
    int? noOfVehicles,
    DateTime? date,
    String? fromTo,
    double? quantityDays,
    double? rate,
    Map<String, String>? customValues,
  }) {
    return InvoiceFormItem(
      description: description ?? this.description,
      noOfVehicles: noOfVehicles ?? this.noOfVehicles,
      date: date ?? this.date,
      fromTo: fromTo ?? this.fromTo,
      quantityDays: quantityDays ?? this.quantityDays,
      rate: rate ?? this.rate,
      customValues: customValues ?? this.customValues,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'noOfVehicles': noOfVehicles,
      'date': date?.toIso8601String(),
      'fromTo': fromTo,
      'quantityDays': quantityDays,
      'rate': rate,
      'customValues': customValues,
    };
  }

  factory InvoiceFormItem.fromJson(Map<String, dynamic> json) {
    final rawCustom = json['customValues'] as Map<String, dynamic>?;
    final Map<String, String> customVals = {};
    if (rawCustom != null) {
      rawCustom.forEach((k, v) {
        customVals[k] = v.toString();
      });
    }

    return InvoiceFormItem(
      description: json['description'] as String,
      noOfVehicles: json['noOfVehicles'] as int?,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      fromTo: json['fromTo'] as String?,
      quantityDays: (json['quantityDays'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      customValues: customVals,
    );
  }
}

class InvoiceFormState {
  final InvoiceTemplateSchema activeTemplate;
  final Map<String, dynamic> fieldValues;
  final List<InvoiceFormItem> items;
  final double gstPercentage;
  final bool isGstInclusive;
  final double advancePaid;

  InvoiceFormState({
    required this.activeTemplate,
    required this.fieldValues,
    this.items = const [],
    this.gstPercentage = 5.0,
    this.isGstInclusive = false,
    this.advancePaid = 0.0,
  });

  // Getters for compatibility with existing widgets
  String get invoiceNumber => fieldValues['invoice_number']?.toString() ?? '';
  DateTime get invoiceDate {
    final val = fieldValues['invoice_date'];
    if (val is DateTime) return val;
    if (val != null) {
      final parsed = DateTime.tryParse(val.toString());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
  
  DateTime get dueDate {
    final val = fieldValues['due_date'];
    if (val is DateTime) return val;
    if (val != null) {
      final parsed = DateTime.tryParse(val.toString());
      if (parsed != null) return parsed;
    }
    return DateTime.now().add(const Duration(days: 7));
  }

  String get bookingRef => fieldValues['booking_ref']?.toString() ?? '';
  DateTime? get bookingDate {
    final val = fieldValues['booking_date'];
    if (val is DateTime) return val;
    if (val != null) return DateTime.tryParse(val.toString());
    return null;
  }

  String get customerName => fieldValues['customer_name']?.toString() ?? '';
  String get customerAddress => fieldValues['customer_address']?.toString() ?? '';
  String get customerGstNumber => fieldValues['customer_gst']?.toString() ?? '';
  String get customerContactNumber => fieldValues['customer_phone']?.toString() ?? '';
  
  // Tourism specific fields
  String get tourTrip => fieldValues['tour_trip']?.toString() ?? '';
  DateTime? get travelDate {
    final val = fieldValues['travel_date'];
    if (val is DateTime) return val;
    if (val != null) return DateTime.tryParse(val.toString());
    return null;
  }
  int? get noOfDays {
    final val = fieldValues['no_of_days'];
    if (val is int) return val;
    if (val != null) return int.tryParse(val.toString());
    return null;
  }
  int? get noOfVehicles {
    final val = fieldValues['no_of_vehicles'];
    if (val is int) return val;
    if (val != null) return int.tryParse(val.toString());
    return null;
  }
  String get coordinatorName => fieldValues['coordinator_name']?.toString() ?? '';
  String get templateType => activeTemplate.id;

  double get rawSubTotal {
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }

  GstCalculationResult get gstCalculations {
    return GstCalculationResult.calculate(
      baseAmount: rawSubTotal,
      gstPercentage: gstPercentage,
      isInclusive: isGstInclusive,
    );
  }

  double get balanceDue {
    return gstCalculations.grandTotal - advancePaid;
  }

  InvoiceFormState copyWith({
    InvoiceTemplateSchema? activeTemplate,
    Map<String, dynamic>? fieldValues,
    List<InvoiceFormItem>? items,
    double? gstPercentage,
    bool? isGstInclusive,
    double? advancePaid,
  }) {
    return InvoiceFormState(
      activeTemplate: activeTemplate ?? this.activeTemplate,
      fieldValues: fieldValues ?? this.fieldValues,
      items: items ?? this.items,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      isGstInclusive: isGstInclusive ?? this.isGstInclusive,
      advancePaid: advancePaid ?? this.advancePaid,
    );
  }
}
