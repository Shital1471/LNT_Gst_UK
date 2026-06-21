import '../../../core/utils/gst_calculator.dart';

class InvoiceFormItem {
  final String description;
  final int? noOfVehicles; // Tourism specific (optional)
  final DateTime? date; // Tourism specific (optional)
  final String? fromTo; // Tourism specific (optional)
  final double quantityDays; // Days in tourism, quantity in standard
  final double rate;

  InvoiceFormItem({
    required this.description,
    this.noOfVehicles,
    this.date,
    this.fromTo,
    required this.quantityDays,
    required this.rate,
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
  }) {
    return InvoiceFormItem(
      description: description ?? this.description,
      noOfVehicles: noOfVehicles ?? this.noOfVehicles,
      date: date ?? this.date,
      fromTo: fromTo ?? this.fromTo,
      quantityDays: quantityDays ?? this.quantityDays,
      rate: rate ?? this.rate,
    );
  }
}

class InvoiceFormState {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String bookingRef;
  final DateTime? bookingDate;
  final String customerName;
  final String customerAddress;
  final String customerGstNumber;
  final String customerContactNumber;
  
  // Tourism specific fields
  final String tourTrip;
  final DateTime? travelDate;
  final int? noOfDays;
  final int? noOfVehicles;
  final String coordinatorName;
  
  // Items
  final List<InvoiceFormItem> items;
  
  // Tax / Payment Settings
  final double gstPercentage;
  final bool isGstInclusive;
  final double advancePaid;
  final String templateType; // 'tourism' or 'standard'

  InvoiceFormState({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    this.bookingRef = '',
    this.bookingDate,
    this.customerName = '',
    this.customerAddress = '',
    this.customerGstNumber = '',
    this.customerContactNumber = '',
    this.tourTrip = '',
    this.travelDate,
    this.noOfDays,
    this.noOfVehicles,
    this.coordinatorName = '',
    this.items = const [],
    this.gstPercentage = 5.0,
    this.isGstInclusive = false,
    this.advancePaid = 0.0,
    this.templateType = 'tourism',
  });

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
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? bookingRef,
    DateTime? bookingDate,
    String? customerName,
    String? customerAddress,
    String? customerGstNumber,
    String? customerContactNumber,
    String? tourTrip,
    DateTime? travelDate,
    int? noOfDays,
    int? noOfVehicles,
    String? coordinatorName,
    List<InvoiceFormItem>? items,
    double? gstPercentage,
    bool? isGstInclusive,
    double? advancePaid,
    String? templateType,
  }) {
    return InvoiceFormState(
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      bookingRef: bookingRef ?? this.bookingRef,
      bookingDate: bookingDate ?? this.bookingDate,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerGstNumber: customerGstNumber ?? this.customerGstNumber,
      customerContactNumber: customerContactNumber ?? this.customerContactNumber,
      tourTrip: tourTrip ?? this.tourTrip,
      travelDate: travelDate ?? this.travelDate,
      noOfDays: noOfDays ?? this.noOfDays,
      noOfVehicles: noOfVehicles ?? this.noOfVehicles,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      items: items ?? this.items,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      isGstInclusive: isGstInclusive ?? this.isGstInclusive,
      advancePaid: advancePaid ?? this.advancePaid,
      templateType: templateType ?? this.templateType,
    );
  }
}
