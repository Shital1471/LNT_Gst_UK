import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/num_to_words.dart';
import '../models/invoice_form_state.dart';

class InvoiceFormNotifier extends StateNotifier<InvoiceFormState> {
  final AppDatabase _db;

  InvoiceFormNotifier(this._db) : super(InvoiceFormState(
          invoiceNumber: '',
          invoiceDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 7)),
        )) {
    initDefaults();
  }

  Future<void> initDefaults() async {
    final now = DateTime.now();
    
    // Auto-generate invoice number based on LN Tourism template (e.g. LNT2605000)
    // Format: LNT + YY + MM + 3-digit index
    final yearStr = now.year.toString().substring(2);
    final monthStr = now.month.toString().padLeft(2, '0');
    final prefix = 'LNT$yearStr$monthStr';

    // Count existing invoices for this month to determine index
    int count = 0;
    try {
      final list = await _db.select(_db.invoices).get();
      count = list.where((inv) => inv.invoiceNumber.startsWith(prefix)).length;
    } catch (_) {}

    final indexStr = count.toString().padLeft(3, '0');
    final generatedNo = '$prefix$indexStr';

    state = InvoiceFormState(
      invoiceNumber: generatedNo,
      invoiceDate: now,
      dueDate: now.add(const Duration(days: 7)),
      bookingDate: now,
      travelDate: now,
      items: [
        InvoiceFormItem(
          description: 'Car Rental Charges',
          noOfVehicles: 1,
          date: now,
          fromTo: 'Dehradun - Haridwar',
          quantityDays: 1,
          rate: 2500,
        )
      ],
    );
  }

  void updateFields({
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
    double? gstPercentage,
    bool? isGstInclusive,
    double? advancePaid,
    String? templateType,
  }) {
    state = state.copyWith(
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      bookingRef: bookingRef,
      bookingDate: bookingDate,
      customerName: customerName,
      customerAddress: customerAddress,
      customerGstNumber: customerGstNumber,
      customerContactNumber: customerContactNumber,
      tourTrip: tourTrip,
      travelDate: travelDate,
      noOfDays: noOfDays,
      noOfVehicles: noOfVehicles,
      coordinatorName: coordinatorName,
      gstPercentage: gstPercentage,
      isGstInclusive: isGstInclusive,
      advancePaid: advancePaid,
      templateType: templateType,
    );
  }

  void addItem(InvoiceFormItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void removeItem(int index) {
    final list = [...state.items];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(items: list);
    }
  }

  void updateItem(int index, InvoiceFormItem updatedItem) {
    final list = [...state.items];
    if (index >= 0 && index < list.length) {
      list[index] = updatedItem;
      state = state.copyWith(items: list);
    }
  }

  void reset() {
    initDefaults();
  }

  void loadFromInvoice(Invoice invoice, List<InvoiceItem> items) {
    state = InvoiceFormState(
      invoiceNumber: invoice.invoiceNumber,
      invoiceDate: invoice.invoiceDate,
      dueDate: invoice.dueDate,
      bookingRef: invoice.bookingRef ?? '',
      bookingDate: invoice.bookingDate,
      customerName: invoice.customerName,
      customerAddress: invoice.customerAddress,
      customerGstNumber: invoice.customerGstNumber ?? '',
      customerContactNumber: invoice.customerContactNumber ?? '',
      tourTrip: invoice.tourTrip ?? '',
      travelDate: invoice.travelDate,
      noOfDays: invoice.noOfDays,
      noOfVehicles: invoice.noOfVehicles,
      coordinatorName: invoice.coordinatorName ?? '',
      items: items.map((i) => InvoiceFormItem(
        description: i.description,
        noOfVehicles: i.noOfVehicles,
        date: i.itemDate,
        fromTo: i.fromTo,
        quantityDays: i.quantityDays,
        rate: i.rate,
      )).toList(),
      gstPercentage: (invoice.cgst + invoice.sgst) / invoice.subTotal * 100, // Derived
      isGstInclusive: invoice.grandTotal == invoice.subTotal, // Approximation
      advancePaid: invoice.advancePaid,
      templateType: invoice.templateType,
    );
  }

  Future<int> saveInvoice() async {
    final calcs = state.gstCalculations;
    final inWords = NumberToWords.convert(calcs.grandTotal - state.advancePaid);

    return await _db.transaction(() async {
      // 1. Check if invoice number already exists (for editing) and delete old records
      final existing = await (_db.select(_db.invoices)
            ..where((t) => t.invoiceNumber.equals(state.invoiceNumber)))
          .getSingleOrNull();

      if (existing != null) {
        await (_db.delete(_db.invoices)..where((t) => t.id.equals(existing.id))).go();
      }

      // 2. Insert invoice header
      final invoiceId = await _db.into(_db.invoices).insert(
        InvoicesCompanion.insert(
          invoiceNumber: state.invoiceNumber,
          invoiceDate: state.invoiceDate,
          dueDate: state.dueDate,
          bookingRef: Value(state.bookingRef.isEmpty ? null : state.bookingRef),
          bookingDate: Value(state.bookingDate),
          customerName: state.customerName,
          customerAddress: state.customerAddress,
          customerGstNumber: Value(state.customerGstNumber.isEmpty ? null : state.customerGstNumber),
          customerContactNumber: Value(state.customerContactNumber.isEmpty ? null : state.customerContactNumber),
          tourTrip: Value(state.tourTrip.isEmpty ? null : state.tourTrip),
          travelDate: Value(state.travelDate),
          noOfDays: Value(state.noOfDays),
          noOfVehicles: Value(state.noOfVehicles),
          coordinatorName: Value(state.coordinatorName.isEmpty ? null : state.coordinatorName),
          subTotal: calcs.subTotal,
          cgst: calcs.cgst,
          sgst: calcs.sgst,
          totalGst: calcs.totalGst,
          grandTotal: calcs.grandTotal,
          advancePaid: Value(state.advancePaid),
          amountPaidInWords: inWords,
          templateType: Value(state.templateType),
          createdDate: DateTime.now(),
        ),
      );

      // 3. Insert line items
      for (final item in state.items) {
        await _db.into(_db.invoiceItems).insert(
          InvoiceItemsCompanion.insert(
            invoiceId: invoiceId,
            description: item.description,
            noOfVehicles: Value(item.noOfVehicles),
            itemDate: Value(item.date),
            fromTo: Value(item.fromTo),
            quantityDays: item.quantityDays,
            rate: item.rate,
            amount: item.amount,
          ),
        );
      }

      return invoiceId;
    });
  }
}

final invoiceFormProvider = StateNotifierProvider<InvoiceFormNotifier, InvoiceFormState>((ref) {
  final db = ref.watch(databaseProvider);
  return InvoiceFormNotifier(db);
});
