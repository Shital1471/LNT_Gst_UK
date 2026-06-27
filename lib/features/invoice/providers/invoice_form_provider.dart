import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/num_to_words.dart';
import '../models/invoice_form_state.dart';
import '../models/invoice_template_schema.dart';

class InvoiceFormNotifier extends StateNotifier<InvoiceFormState> {
  final AppDatabase _db;

  InvoiceFormNotifier(this._db)
      : super(InvoiceFormState(
          activeTemplate: InvoiceTemplateSchema.getTourismDefault(),
          fieldValues: {},
        )) {
    initDefaults();
  }

  Future<void> initDefaults({InvoiceTemplateSchema? template}) async {
    final now = DateTime.now();
    
    // Auto-generate invoice number based on prefix (e.g. LNT2605000)
    final yearStr = now.year.toString().substring(2);
    final monthStr = now.month.toString().padLeft(2, '0');
    final prefix = 'LNT$yearStr$monthStr';

    int count = 0;
    try {
      final list = await _db.select(_db.invoices).get();
      count = list.where((inv) => inv.invoiceNumber.startsWith(prefix)).length;
    } catch (_) {}

    final indexStr = count.toString().padLeft(3, '0');
    final generatedNo = '$prefix$indexStr';

    String bankNameVal = 'State Bank of India';
    String bankAccountNoVal = '45103469416';
    String bankIfscVal = 'SBIN0017056';
    String bankAccountNameVal = 'LN Tourism Private Limited';

    try {
      final company = await (_db.select(_db.companyProfiles)..limit(1)).getSingleOrNull();
      if (company != null) {
        bankNameVal = company.bankName;
        bankAccountNoVal = company.bankAccountNumber;
        bankIfscVal = company.bankIfscCode;
        bankAccountNameVal = company.bankAccountName;
      }
    } catch (_) {}

    final activeT = template ?? InvoiceTemplateSchema.getTourismDefault();
    final defaultValues = <String, dynamic>{
      'invoice_number': generatedNo,
      'invoice_date': now,
      'due_date': now.add(const Duration(days: 7)),
      'booking_date': now,
      'travel_date': now,
      'customer_name': '',
      'customer_address': '',
      'customer_gst': '',
      'customer_phone': '',
      'booking_ref': '',
      'tour_trip': '',
      'no_of_days': 1,
      'no_of_vehicles': 1,
      'coordinator_name': '',
      'bank_name': bankNameVal,
      'bank_account_no': bankAccountNoVal,
      'bank_ifsc': bankIfscVal,
      'bank_account_name': bankAccountNameVal,
      'bank_branch': 'Dehradun',
      'signature_type': 'company',
      'signature_text': 'Abhishek Prajapati',
      'signature_image_path': '',
    };

    // Fill in default values from fields schema
    for (final sec in activeT.sections) {
      for (final field in sec.fields) {
        if (field.defaultValue != null) {
          defaultValues[field.id] = field.defaultValue;
        }
      }
    }

    state = InvoiceFormState(
      activeTemplate: activeT,
      fieldValues: defaultValues,
      items: [],
    );
  }

  void updateFieldValue(String fieldId, dynamic value) {
    final newValues = Map<String, dynamic>.from(state.fieldValues);
    newValues[fieldId] = value;
    state = state.copyWith(fieldValues: newValues);
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
  }) {
    final newValues = Map<String, dynamic>.from(state.fieldValues);
    if (invoiceNumber != null) newValues['invoice_number'] = invoiceNumber;
    if (invoiceDate != null) newValues['invoice_date'] = invoiceDate;
    if (dueDate != null) newValues['due_date'] = dueDate;
    if (bookingRef != null) newValues['booking_ref'] = bookingRef;
    if (bookingDate != null) newValues['booking_date'] = bookingDate;
    if (customerName != null) newValues['customer_name'] = customerName;
    if (customerAddress != null) newValues['customer_address'] = customerAddress;
    if (customerGstNumber != null) newValues['customer_gst'] = customerGstNumber;
    if (customerContactNumber != null) newValues['customer_phone'] = customerContactNumber;
    if (tourTrip != null) newValues['tour_trip'] = tourTrip;
    if (travelDate != null) newValues['travel_date'] = travelDate;
    if (noOfDays != null) newValues['no_of_days'] = noOfDays;
    if (noOfVehicles != null) newValues['no_of_vehicles'] = noOfVehicles;
    if (coordinatorName != null) newValues['coordinator_name'] = coordinatorName;

    state = state.copyWith(
      fieldValues: newValues,
      gstPercentage: gstPercentage ?? state.gstPercentage,
      isGstInclusive: isGstInclusive ?? state.isGstInclusive,
      advancePaid: advancePaid ?? state.advancePaid,
    );
  }

  void updateTemplate(InvoiceTemplateSchema template) {
    final newValues = Map<String, dynamic>.from(state.fieldValues);
    
    // Set default values for any fields in the new template if not already present or if currently empty
    for (final sec in template.sections) {
      for (final field in sec.fields) {
        final val = newValues[field.id];
        if ((val == null || val.toString().isEmpty) && field.defaultValue != null) {
          newValues[field.id] = field.defaultValue;
        }
      }
    }
    
    state = state.copyWith(activeTemplate: template, fieldValues: newValues);

    // Write to the SQLite database in the background to persist modifications
    _db.transaction(() async {
      final existing = await (_db.select(_db.invoiceTemplates)
            ..where((row) => row.name.equals(template.name)))
          .getSingleOrNull();

      if (existing != null) {
        await (_db.update(_db.invoiceTemplates)..where((row) => row.id.equals(existing.id))).write(
          InvoiceTemplatesCompanion(
            schemaJson: Value(jsonEncode(template.toJson())),
          ),
        );
      } else {
        await _db.into(_db.invoiceTemplates).insert(
          InvoiceTemplatesCompanion.insert(
            name: template.name,
            description: Value(template.description),
            schemaJson: jsonEncode(template.toJson()),
            createdDate: DateTime.now(),
          ),
        );
      }
    });
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
    initDefaults(template: state.activeTemplate);
  }

  String serializeFieldValues(Map<String, dynamic> values) {
    final Map<String, dynamic> converted = {};
    values.forEach((key, val) {
      if (val is DateTime) {
        converted[key] = val.toIso8601String();
      } else {
        converted[key] = val;
      }
    });
    return jsonEncode(converted);
  }

  Map<String, dynamic> deserializeFieldValues(String jsonStr) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded;
    } catch (_) {
      return {};
    }
  }

  void loadFromInvoice(Invoice invoice, List<InvoiceItem> items) {
    InvoiceTemplateSchema activeT;
    if (invoice.templateSchemaJson != null && invoice.templateSchemaJson!.isNotEmpty) {
      activeT = InvoiceTemplateSchema.fromJson(jsonDecode(invoice.templateSchemaJson!));
    } else {
      activeT = InvoiceTemplateSchema.getPreset(invoice.templateType);
    }

    Map<String, dynamic> values = {};
    if (invoice.fieldValuesJson != null && invoice.fieldValuesJson!.isNotEmpty) {
      values = deserializeFieldValues(invoice.fieldValuesJson!);
    } else {
      // Fallback
      values = {
        'invoice_number': invoice.invoiceNumber,
        'invoice_date': invoice.invoiceDate,
        'due_date': invoice.dueDate,
        'booking_ref': invoice.bookingRef ?? '',
        'booking_date': invoice.bookingDate,
        'customer_name': invoice.customerName,
        'customer_address': invoice.customerAddress,
        'customer_gst': invoice.customerGstNumber ?? '',
        'customer_phone': invoice.customerContactNumber ?? '',
        'tour_trip': invoice.tourTrip ?? '',
        'travel_date': invoice.travelDate,
        'no_of_days': invoice.noOfDays,
        'no_of_vehicles': invoice.noOfVehicles,
        'coordinator_name': invoice.coordinatorName ?? '',
      };
    }

    state = InvoiceFormState(
      activeTemplate: activeT,
      fieldValues: values,
      items: items.map((i) {
        String desc = i.description;
        Map<String, String> customVals = {};
        try {
          final decoded = jsonDecode(i.description) as Map<String, dynamic>;
          if (decoded.containsKey('description')) {
            desc = decoded['description']?.toString() ?? '';
            final custom = decoded['customValues'] as Map<String, dynamic>?;
            if (custom != null) {
              custom.forEach((k, v) {
                customVals[k] = v.toString();
              });
            }
          }
        } catch (_) {}

        return InvoiceFormItem(
          description: desc,
          noOfVehicles: i.noOfVehicles,
          date: i.itemDate,
          fromTo: i.fromTo,
          quantityDays: i.quantityDays,
          rate: i.rate,
          customValues: customVals,
        );
      }).toList(),
      gstPercentage: (invoice.cgst + invoice.sgst) / (invoice.subTotal == 0 ? 1 : invoice.subTotal) * 100,
      isGstInclusive: invoice.grandTotal == invoice.subTotal,
      advancePaid: invoice.advancePaid,
    );
  }

  Future<int> saveInvoice() async {
    final calcs = state.gstCalculations;
    final inWords = NumberToWords.convert(calcs.grandTotal - state.advancePaid);

    return await _db.transaction(() async {
      final existing = await (_db.select(_db.invoices)
            ..where((t) => t.invoiceNumber.equals(state.invoiceNumber)))
          .getSingleOrNull();

      if (existing != null) {
        await (_db.delete(_db.invoices)..where((t) => t.id.equals(existing.id))).go();
      }

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
          templateSchemaJson: Value(jsonEncode(state.activeTemplate.toJson())),
          fieldValuesJson: Value(serializeFieldValues(state.fieldValues)),
        ),
      );

      for (final item in state.items) {
        final dbDescription = item.customValues.isEmpty
            ? item.description
            : jsonEncode({
                'description': item.description,
                'customValues': item.customValues,
              });

        await _db.into(_db.invoiceItems).insert(
          InvoiceItemsCompanion.insert(
            invoiceId: invoiceId,
            description: dbDescription,
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

final templatesProvider = FutureProvider<List<InvoiceTemplateSchema>>((ref) async {
  final db = ref.watch(databaseProvider);
  final defaults = [
    InvoiceTemplateSchema.getTourismDefault(),
    InvoiceTemplateSchema.getStandardDefault(),
    InvoiceTemplateSchema.getServiceDefault(),
    InvoiceTemplateSchema.getTransportDefault(),
  ];

  for (final t in defaults) {
    final existing = await (db.select(db.invoiceTemplates)
          ..where((row) => row.name.equals(t.name)))
        .getSingleOrNull();

    if (existing == null) {
      await db.into(db.invoiceTemplates).insert(
        InvoiceTemplatesCompanion.insert(
          name: t.name,
          description: Value(t.description),
          schemaJson: jsonEncode(t.toJson()),
          createdDate: DateTime.now(),
        ),
      );
    } else {
      // Overwrite/update templates to keep schemas in sync with code definitions
      await (db.update(db.invoiceTemplates)..where((row) => row.id.equals(existing.id))).write(
        InvoiceTemplatesCompanion(
          schemaJson: Value(jsonEncode(t.toJson())),
        ),
      );
    }
  }

  final rows = await db.select(db.invoiceTemplates).get();
  return rows.map((r) => InvoiceTemplateSchema.fromJson(jsonDecode(r.schemaJson))).toList();
});
