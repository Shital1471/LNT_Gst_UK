import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../company/providers/company_provider.dart';
import '../models/invoice_form_state.dart';
import '../models/invoice_template_schema.dart';
import '../providers/invoice_form_provider.dart';
import 'invoice_preview_screen.dart';
import 'invoice_designer_screen.dart';
import 'template_management_screen.dart';
import '../../../core/utils/num_to_words.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _df = DateFormat('dd/MM/yyyy');
  final Map<String, TextEditingController> _controllers = {};
  final _advancePaidCtrl = TextEditingController();
  final _customGstCtrl = TextEditingController();
  final _balanceDueCtrl = TextEditingController();
  bool _isGstCustom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(invoiceFormProvider);
      _syncControllersWithState(state);
    });
  }

  void _syncControllersWithState(InvoiceFormState state) {
    for (final sec in state.activeTemplate.sections) {
      for (final field in sec.fields) {
        final val = state.fieldValues[field.id];
        final text = _formatValueForText(val, field.valueType);
        
        if (_controllers.containsKey(field.id)) {
          final ctrl = _controllers[field.id]!;
          if (field.valueType == 'number' || field.valueType == 'currency') {
            final double? current = double.tryParse(ctrl.text);
            final double? target = double.tryParse(text);
            if (current != target && ctrl.text != text) {
              ctrl.text = text;
            }
          } else {
            if (ctrl.text != text) {
              ctrl.text = text;
            }
          }
        } else {
          _controllers[field.id] = TextEditingController(text: text);
        }
      }
    }
    
    // Check if signature text controller exists, if not add it
    if (!_controllers.containsKey('signature_text')) {
      _controllers['signature_text'] = TextEditingController(
        text: state.fieldValues['signature_text']?.toString() ?? 'Abhishek Prajapati'
      );
    } else {
      final sigTextVal = state.fieldValues['signature_text']?.toString() ?? 'Abhishek Prajapati';
      if (_controllers['signature_text']!.text != sigTextVal) {
        _controllers['signature_text']!.text = sigTextVal;
      }
    }

    final double? currentAdvance = double.tryParse(_advancePaidCtrl.text);
    if (currentAdvance != state.advancePaid) {
      _advancePaidCtrl.text = state.advancePaid == 0 ? '' : state.advancePaid.toString();
    }

    final double? currentGst = double.tryParse(_customGstCtrl.text);
    if (currentGst != state.gstPercentage) {
      _customGstCtrl.text = state.gstPercentage.toString();
    }

    final double? currentBalance = double.tryParse(_balanceDueCtrl.text);
    if (currentBalance != state.balanceDue) {
      _balanceDueCtrl.text = state.balanceDue == 0 ? '' : state.balanceDue.toString();
    }
  }

  String _formatValueForText(dynamic val, String type) {
    if (val == null) return '';
    if (val is DateTime) {
      return _df.format(val);
    }
    return val.toString();
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    _advancePaidCtrl.dispose();
    _customGstCtrl.dispose();
    _balanceDueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickSignatureImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        ref.read(invoiceFormProvider.notifier).updateFieldValue('signature_image_path', path);
        ref.read(invoiceFormProvider.notifier).updateFieldValue('signature_type', 'upload');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking signature: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, DateTime initial, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _addNewItemDialog() {
    final state = ref.read(invoiceFormProvider);
    final isTourism = state.templateType == 'tourism';

    final tourTrip = state.fieldValues['tour_trip']?.toString() ?? '';
    final tourVehicles = state.fieldValues['no_of_vehicles']?.toString() ?? '1';
    final tourTravelDate = state.fieldValues['travel_date'];
    
    DateTime itemDate = DateTime.now();
    if (tourTravelDate is DateTime) {
      itemDate = tourTravelDate;
    } else if (tourTravelDate != null) {
      itemDate = DateTime.tryParse(tourTravelDate.toString()) ?? DateTime.now();
    }

    final descCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final vehiclesCtrl = TextEditingController();
    final fromToCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    final customCols = state.activeTemplate.tableColumns
        .where((c) => c.isVisible && !const ['s_no', 'description', 'no_of_vehicles', 'date', 'from_to', 'qty', 'rate', 'amount'].contains(c.id))
        .toList();
    final Map<String, TextEditingController> customCtrls = {
      for (final col in customCols) col.id: TextEditingController()
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          void updateAmount() {
            final double qty = double.tryParse(qtyCtrl.text) ?? 0.0;
            final double rate = double.tryParse(rateCtrl.text) ?? 0.0;
            final double vehicles = isTourism ? (double.tryParse(vehiclesCtrl.text) ?? 1.0) : 1.0;
            final double amount = qty * rate * vehicles;
            final String textVal = amount.toStringAsFixed(2);
            if (amountCtrl.text != textVal) {
              amountCtrl.text = textVal;
            }
          }

          void updateRate() {
            final double amount = double.tryParse(amountCtrl.text) ?? 0.0;
            final double qty = double.tryParse(qtyCtrl.text) ?? 0.0;
            final double vehicles = isTourism ? (double.tryParse(vehiclesCtrl.text) ?? 1.0) : 1.0;
            if (qty * vehicles > 0) {
              final double rate = amount / (qty * vehicles);
              final String textVal = rate.toStringAsFixed(2);
              if (rateCtrl.text != textVal) {
                rateCtrl.text = textVal;
              }
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.deepBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.post_add_rounded, color: AppTheme.deepBlue, size: 26),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Line Item',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.deepBlue),
                            ),
                            Text(
                              'Define the service description and pricing details',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Description / Service Name',
                        hintText: 'e.g. Tour Guide Services or Vehicle Hire',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isTourism) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOUR DETAILS',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.deepBlue, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: vehiclesCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'No. of Vehicles',
                                      prefixIcon: const Icon(Icons.directions_car_filled_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (_) => updateAmount(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: itemDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setStateBuilder(() {
                                          itemDate = picked;
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Service Date',
                                        prefixIcon: const Icon(Icons.calendar_month_outlined),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text(_df.format(itemDate), style: const TextStyle(fontSize: 14)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: fromToCtrl,
                              decoration: InputDecoration(
                                labelText: 'From - To (Route)',
                                hintText: 'e.g. Haridwar - Rishikesh - Dehradun',
                                prefixIcon: const Icon(Icons.map_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: isTourism ? 'Qty / Days' : 'Qty',
                              prefixIcon: const Icon(Icons.numbers_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (_) => updateAmount(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Rate (Rs.)',
                              prefixIcon: const Icon(Icons.currency_rupee_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (_) => updateAmount(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Total Price (Rs.)',
                        prefixIcon: const Icon(Icons.calculate_outlined),
                        helperText: 'Entering total price calculates rate automatically',
                        helperStyle: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w500),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) => updateRate(),
                    ),
                    if (customCols.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Custom Columns', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.deepBlue)),
                        ),
                      ),
                      ...customCols.map((col) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: customCtrls[col.id],
                            decoration: InputDecoration(
                              labelText: col.label,
                              prefixIcon: const Icon(Icons.add_box_outlined, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            descCtrl.dispose();
                            rateCtrl.dispose();
                            qtyCtrl.dispose();
                            vehiclesCtrl.dispose();
                            fromToCtrl.dispose();
                            amountCtrl.dispose();
                            for (final ctrl in customCtrls.values) {
                              ctrl.dispose();
                            }
                            Navigator.pop(ctx);
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () {
                            if (descCtrl.text.isNotEmpty && (rateCtrl.text.isNotEmpty || amountCtrl.text.isNotEmpty)) {
                              final Map<String, String> customValues = {
                                for (final col in customCols) col.id: customCtrls[col.id]!.text.trim()
                              };
                              ref.read(invoiceFormProvider.notifier).addItem(
                                    InvoiceFormItem(
                                      description: descCtrl.text,
                                      rate: double.tryParse(rateCtrl.text) ?? 0.0,
                                      quantityDays: double.tryParse(qtyCtrl.text) ?? 1.0,
                                      noOfVehicles: isTourism ? int.tryParse(vehiclesCtrl.text) : null,
                                      date: isTourism ? itemDate : null,
                                      fromTo: isTourism ? fromToCtrl.text : null,
                                      customValues: customValues,
                                    ),
                                  );
                              descCtrl.dispose();
                              rateCtrl.dispose();
                              qtyCtrl.dispose();
                              vehiclesCtrl.dispose();
                              fromToCtrl.dispose();
                              amountCtrl.dispose();
                              for (final ctrl in customCtrls.values) {
                                ctrl.dispose();
                              }
                              Navigator.pop(ctx);
                            }
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _editItemDialog(int index, InvoiceFormItem item) {
    final state = ref.read(invoiceFormProvider);
    final isTourism = state.templateType == 'tourism';

    final descCtrl = TextEditingController(text: item.description);
    final rateCtrl = TextEditingController(text: item.rate.toString());
    final qtyCtrl = TextEditingController(text: item.quantityDays.toString());
    final vehiclesCtrl = TextEditingController(text: item.noOfVehicles?.toString() ?? '1');
    final fromToCtrl = TextEditingController(text: item.fromTo ?? '');
    final amountCtrl = TextEditingController(text: item.amount.toStringAsFixed(2));
    DateTime itemDate = item.date ?? DateTime.now();

    final customCols = state.activeTemplate.tableColumns
        .where((c) => c.isVisible && !const ['s_no', 'description', 'no_of_vehicles', 'date', 'from_to', 'qty', 'rate', 'amount'].contains(c.id))
        .toList();
    final Map<String, TextEditingController> customCtrls = {
      for (final col in customCols) col.id: TextEditingController(text: item.customValues[col.id] ?? '')
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          void updateAmount() {
            final double qty = double.tryParse(qtyCtrl.text) ?? 0.0;
            final double rate = double.tryParse(rateCtrl.text) ?? 0.0;
            final double vehicles = isTourism ? (double.tryParse(vehiclesCtrl.text) ?? 1.0) : 1.0;
            final double amount = qty * rate * vehicles;
            final String textVal = amount.toStringAsFixed(2);
            if (amountCtrl.text != textVal) {
              amountCtrl.text = textVal;
            }
          }

          void updateRate() {
            final double amount = double.tryParse(amountCtrl.text) ?? 0.0;
            final double qty = double.tryParse(qtyCtrl.text) ?? 0.0;
            final double vehicles = isTourism ? (double.tryParse(vehiclesCtrl.text) ?? 1.0) : 1.0;
            if (qty * vehicles > 0) {
              final double rate = amount / (qty * vehicles);
              final String textVal = rate.toStringAsFixed(2);
              if (rateCtrl.text != textVal) {
                rateCtrl.text = textVal;
              }
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.deepBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_note_rounded, color: AppTheme.deepBlue, size: 26),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Line Item',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.deepBlue),
                            ),
                            Text(
                              'Update the service description and pricing details',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Description / Service Name',
                        hintText: 'e.g. Tour Guide Services or Vehicle Hire',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isTourism) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOUR DETAILS',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.deepBlue, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: vehiclesCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'No. of Vehicles',
                                      prefixIcon: const Icon(Icons.directions_car_filled_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (_) => updateAmount(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: itemDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setStateBuilder(() {
                                          itemDate = picked;
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Service Date',
                                        prefixIcon: const Icon(Icons.calendar_month_outlined),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text(_df.format(itemDate), style: const TextStyle(fontSize: 14)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: fromToCtrl,
                              decoration: InputDecoration(
                                labelText: 'From - To (Route)',
                                hintText: 'e.g. Haridwar - Rishikesh - Dehradun',
                                prefixIcon: const Icon(Icons.map_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: isTourism ? 'Qty / Days' : 'Qty',
                              prefixIcon: const Icon(Icons.numbers_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (_) => updateAmount(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Rate (Rs.)',
                              prefixIcon: const Icon(Icons.currency_rupee_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (_) => updateAmount(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Total Price (Rs.)',
                        prefixIcon: const Icon(Icons.calculate_outlined),
                        helperText: 'Entering total price calculates rate automatically',
                        helperStyle: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w500),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) => updateRate(),
                    ),
                    if (customCols.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Custom Columns', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.deepBlue)),
                        ),
                      ),
                      ...customCols.map((col) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: customCtrls[col.id],
                            decoration: InputDecoration(
                              labelText: col.label,
                              prefixIcon: const Icon(Icons.add_box_outlined, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            descCtrl.dispose();
                            rateCtrl.dispose();
                            qtyCtrl.dispose();
                            vehiclesCtrl.dispose();
                            fromToCtrl.dispose();
                            amountCtrl.dispose();
                            for (final ctrl in customCtrls.values) {
                              ctrl.dispose();
                            }
                            Navigator.pop(ctx);
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () {
                            if (descCtrl.text.isNotEmpty && (rateCtrl.text.isNotEmpty || amountCtrl.text.isNotEmpty)) {
                              final Map<String, String> customValues = {
                                for (final col in customCols) col.id: customCtrls[col.id]!.text.trim()
                              };
                              ref.read(invoiceFormProvider.notifier).updateItem(
                                    index,
                                    InvoiceFormItem(
                                      description: descCtrl.text,
                                      rate: double.tryParse(rateCtrl.text) ?? 0.0,
                                      quantityDays: double.tryParse(qtyCtrl.text) ?? 1.0,
                                      noOfVehicles: isTourism ? int.tryParse(vehiclesCtrl.text) : null,
                                      date: isTourism ? itemDate : null,
                                      fromTo: isTourism ? fromToCtrl.text : null,
                                      customValues: customValues,
                                    ),
                                  );
                              descCtrl.dispose();
                              rateCtrl.dispose();
                              qtyCtrl.dispose();
                              vehiclesCtrl.dispose();
                              fromToCtrl.dispose();
                              amountCtrl.dispose();
                              for (final ctrl in customCtrls.values) {
                                ctrl.dispose();
                              }
                              Navigator.pop(ctx);
                            }
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Update Item'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _previewDocument({required bool resetOnReturn, bool isTemporary = false}) async {
    final state = ref.read(invoiceFormProvider);
    if (state.customerName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer Name is required'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line item'), backgroundColor: Colors.orange),
      );
      return;
    }

    final companyVal = ref.read(companyProfileStateProvider);
    final company = companyVal.value;

    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set up company profile first'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      if (isTemporary) {
        final tempInvoice = Invoice(
          id: -1,
          invoiceNumber: state.invoiceNumber,
          invoiceDate: state.invoiceDate,
          dueDate: state.dueDate,
          bookingRef: state.bookingRef.isEmpty ? null : state.bookingRef,
          bookingDate: state.bookingDate,
          customerName: state.customerName,
          customerAddress: state.customerAddress,
          customerGstNumber: state.customerGstNumber.isEmpty ? null : state.customerGstNumber,
          customerContactNumber: state.customerContactNumber.isEmpty ? null : state.customerContactNumber,
          tourTrip: state.tourTrip.isEmpty ? null : state.tourTrip,
          travelDate: state.travelDate,
          noOfDays: state.noOfDays,
          noOfVehicles: state.noOfVehicles,
          coordinatorName: state.coordinatorName.isEmpty ? null : state.coordinatorName,
          subTotal: state.gstCalculations.subTotal,
          cgst: state.gstCalculations.cgst,
          sgst: state.gstCalculations.sgst,
          totalGst: state.gstCalculations.totalGst,
          grandTotal: state.gstCalculations.grandTotal,
          advancePaid: state.advancePaid,
          amountPaidInWords: NumberToWords.convert(state.gstCalculations.grandTotal - state.advancePaid),
          templateType: state.templateType,
          createdDate: DateTime.now(),
          templateSchemaJson: jsonEncode(state.activeTemplate.toJson()),
          fieldValuesJson: ref.read(invoiceFormProvider.notifier).serializeFieldValues(state.fieldValues),
        );

        final List<InvoiceItem> tempItemsList = state.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final dbDescription = item.customValues.isEmpty
              ? item.description
              : jsonEncode({
                  'description': item.description,
                  'customValues': item.customValues,
                });
          return InvoiceItem(
            id: index,
            invoiceId: -1,
            description: dbDescription,
            noOfVehicles: item.noOfVehicles,
            itemDate: item.date,
            fromTo: item.fromTo,
            quantityDays: item.quantityDays,
            rate: item.rate,
            amount: item.amount,
          );
        }).toList();

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoicePreviewScreen(
                invoice: tempInvoice,
                items: tempItemsList,
                company: company,
                isTemporary: true,
              ),
            ),
          );
        }
      } else {
        final invoiceId = await ref.read(invoiceFormProvider.notifier).saveInvoice();

        final db = ref.read(databaseProvider);
        final invoiceHeader = await (db.select(db.invoices)..where((t) => t.id.equals(invoiceId))).getSingle();
        final itemsList = await (db.select(db.invoiceItems)..where((t) => t.invoiceId.equals(invoiceId))).get();

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoicePreviewScreen(
                invoice: invoiceHeader,
                items: itemsList,
                company: company,
                isTemporary: false,
              ),
            ),
          );
          if (resetOnReturn) {
            ref.read(invoiceFormProvider.notifier).initDefaults(template: state.activeTemplate);
            _syncControllersWithState(ref.read(invoiceFormProvider));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating invoice preview: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildBottomActionBar(InvoiceFormState state) {
    final bool isEnabled = state.customerName.trim().isNotEmpty && state.items.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: isEnabled ? () => _previewDocument(resetOnReturn: false, isTemporary: true) : null,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Preview Document'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              side: BorderSide(
                color: isEnabled ? AppTheme.primaryGreen : Colors.grey.shade300,
              ),
              foregroundColor: isEnabled ? AppTheme.primaryGreen : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: isEnabled ? () => _previewDocument(resetOnReturn: true, isTemporary: false) : null,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Preview & Generate Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _saveAction() async {
    final state = ref.read(invoiceFormProvider);
    if (state.customerName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer Name is required to save the invoice'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one line item before saving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await ref.read(invoiceFormProvider.notifier).saveInvoice();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice saved successfully!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  void _showFilledDetailsPreview(BuildContext context, InvoiceFormState state) {
    final List<MapEntry<String, String>> filledFields = [];
    
    void addIfFilled(String label, dynamic val) {
      if (val != null && val.toString().trim().isNotEmpty) {
        filledFields.add(MapEntry(label, val.toString()));
      }
    }

    addIfFilled('Invoice Number', state.invoiceNumber);
    addIfFilled('Invoice Date', _df.format(state.invoiceDate));
    addIfFilled('Due Date', _df.format(state.dueDate));
    addIfFilled('Booking Ref', state.bookingRef);
    if (state.bookingDate != null) {
      addIfFilled('Booking Date', _df.format(state.bookingDate!));
    }
    addIfFilled('Customer Name', state.customerName);
    addIfFilled('Customer Address', state.customerAddress);
    addIfFilled('Customer GSTIN', state.customerGstNumber);
    addIfFilled('Customer Contact', state.customerContactNumber);
    addIfFilled('Tour Trip', state.tourTrip);
    if (state.travelDate != null) {
      addIfFilled('Travel Date', _df.format(state.travelDate!));
    }
    if ((state.noOfDays ?? 0) > 0) addIfFilled('No. of Days', state.noOfDays);
    if ((state.noOfVehicles ?? 0) > 0) addIfFilled('No. of Vehicles', state.noOfVehicles);
    addIfFilled('Coordinator Name', state.coordinatorName);

    state.fieldValues.forEach((key, val) {
      if (val != null && val.toString().trim().isNotEmpty) {
        String label = key.replaceAll('_', ' ').toUpperCase();
        if (key == 'bank_account_name') label = 'Bank Account Name';
        if (key == 'bank_name') label = 'Bank Name';
        if (key == 'bank_account_no') label = 'Bank Account Number';
        if (key == 'bank_ifsc') label = 'Bank IFSC Code';
        if (key == 'bank_branch') label = 'Bank Branch';
        if (key == 'terms_text') label = 'Terms & Conditions';
        if (key == 'signature_text') label = 'Signature Fallback Text';
        if (key == 'signature_type') label = 'Signature Type';
        if (key == 'signature_image_path') label = 'Signature Image Path';
        
        if (const ['company_name', 'company_address', 'company_gst', 'company_phone', 'company_email', 'company_website'].contains(key)) {
          return;
        }
        filledFields.add(MapEntry(label, val.toString()));
      }
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.fact_check, color: AppTheme.deepBlue),
            SizedBox(width: 10),
            Text('Preview Filled Fields', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepBlue)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Review all fields currently filled in this invoice form.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (filledFields.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No details have been entered yet.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(3),
                      },
                      border: TableBorder.all(color: Colors.grey.withOpacity(0.15), width: 1, borderRadius: BorderRadius.circular(8)),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: AppTheme.deepBlue.withOpacity(0.05)),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Text('Field / Property', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.deepBlue)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Text('Entered Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.deepBlue)),
                            ),
                          ],
                        ),
                        ...filledFields.map((entry) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Text(entry.value, style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        )).toList(),
                      ],
                    ),
                  ),
                ),
              if (state.items.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Line Items Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.deepBlue)),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1.5),
                      },
                      border: TableBorder.all(color: Colors.grey.withOpacity(0.15), width: 1, borderRadius: BorderRadius.circular(8)),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: AppTheme.deepBlue.withOpacity(0.05)),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.deepBlue)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.deepBlue)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.deepBlue)),
                            ),
                          ],
                        ),
                        ...state.items.map((item) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text(item.description, style: const TextStyle(fontSize: 11)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text(item.quantityDays.toString(), style: const TextStyle(fontSize: 11)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text('Rs. ${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        )).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceFormProvider);
    final templatesVal = ref.watch(templatesProvider);
    final companyVal = ref.watch(companyProfileStateProvider);
    final company = companyVal.value;

    _syncControllersWithState(state);

    return Scaffold(
      bottomNavigationBar: _buildBottomActionBar(state),
      appBar: AppBar(
        title: const Text('Generate Invoice'),
        actions: [
          OutlinedButton.icon(
              onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InvoiceDesignerScreen()),
                  );
                },
                icon: const Icon(Icons.palette),
                label: const Text('Designer'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TemplateManagementScreen()),
                  );
                },
                icon: const Icon(Icons.tune),
                label: const Text('Templates'),
              ),
              const SizedBox(width: 16),
              templatesVal.when(
                data: (list) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<String>(
                    value: state.activeTemplate.id,
                    underline: const SizedBox(),
                    items: list.map((t) {
                      return DropdownMenuItem(value: t.id, child: Text(t.name, style: const TextStyle(fontSize: 12)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final template = list.firstWhere((t) => t.id == val);
                        ref.read(invoiceFormProvider.notifier).updateTemplate(template);
                        _syncControllersWithState(ref.read(invoiceFormProvider));
                      }
                    },
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => const Icon(Icons.error),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Form',
                onPressed: () {
                  ref.read(invoiceFormProvider.notifier).reset();
                  _syncControllersWithState(ref.read(invoiceFormProvider));
                },
              )
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Company Profile override details (expansion tile)
                      _buildCompanyDetailsOverrideCard(state),
                      const SizedBox(height: 16),

                      // 2. Invoice Details Card
                      _buildInvoiceDetailsCard(state),
                      const SizedBox(height: 16),

                      // 3. Billing details (BILL TO)
                      _buildCustomerDetailsCard(state),
                      const SizedBox(height: 16),

                      // 4. Tour Details (Tourism templates specific)
                      _buildTourDetailsCard(state),
                      const SizedBox(height: 16),

                      // 5. Line items list (items_table section)
                      _buildItemsEditorCard(state),
                      const SizedBox(height: 16),

                      // 6. Bank account details
                      _buildBankDetailsCard(state, company),
                      const SizedBox(height: 16),

                      // 7. Terms & conditions multiline
                      _buildTermsCard(state),
                      const SizedBox(height: 16),

                      // 8. Authorized signature choice
                      _buildSignatureSection(state, company),
                      const SizedBox(height: 16),

                      _buildGstModuleCard(state),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Right Quick Action Panel
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.2))),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('SUMMARY CALCULATIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.deepBlue)),
                    const SizedBox(height: 16),
                    _calcRow('Sub Total', state.gstCalculations.subTotal),
                    _calcRow('CGST @ ${(state.gstPercentage / 2).toStringAsFixed(2)}%', state.gstCalculations.cgst),
                    _calcRow('SGST @ ${(state.gstPercentage / 2).toStringAsFixed(2)}%', state.gstCalculations.sgst),
                    const Divider(),
                    _calcRow('Grand Total', state.gstCalculations.grandTotal, isBold: true),
                    _calcRow('Advance Paid', state.advancePaid, isNegative: true),
                    const Divider(color: AppTheme.primaryGreen),
                    _calcRow('Amount to be Paid', state.balanceDue, isBold: true, color: AppTheme.primaryGreen),
                    const SizedBox(height: 12),
                    Text(
                      'In Words: ${NumberToWords.convert(state.balanceDue)}',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                    const Spacer(),
                    Card(
                      color: AppTheme.primaryGreen.withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Layout presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('Preset: ${state.activeTemplate.layoutPreset.toUpperCase()}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                            Text('Page dimensions: ${state.activeTemplate.pageFormat} (${state.activeTemplate.pageWidth.toStringAsFixed(0)}x${state.activeTemplate.pageHeight.toStringAsFixed(0)} pt)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  // --- Premium Section Card Builders ---

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.deepBlue, size: 22),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: children,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyDetailsOverrideCard(InvoiceFormState state) {
    final companySec = state.activeTemplate.sections.firstWhere((s) => s.id == 'company_details', orElse: () => SectionSchema(id: 'company_details', title: '', orderIndex: 0, fields: []));
    if (!companySec.isVisible) return const SizedBox();

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.business, color: AppTheme.deepBlue),
        title: const Text('COMPANY PROFILE HEADER OVERRIDES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.deepBlue)),
        subtitle: const Text('Change company details printed on this invoice (optional)', style: TextStyle(fontSize: 11, color: Colors.grey)),
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: companySec.fields
                  .where((f) => f.isVisible)
                  .map((f) => _buildDynamicFieldWidget('company_details', f))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailsCard(InvoiceFormState state) {
    final invoiceSec = state.activeTemplate.sections.firstWhere((s) => s.id == 'invoice_info', orElse: () => SectionSchema(id: 'invoice_info', title: '', orderIndex: 2, fields: []));
    if (!invoiceSec.isVisible) return const SizedBox();

    final List<Widget> fields = [];
    
    // Auto-generated Invoice Number
    fields.add(
      SizedBox(
        width: 300,
        child: TextField(
          controller: _controllers['invoice_number'],
          decoration: const InputDecoration(
            labelText: 'Invoice Number',
            prefixIcon: Icon(Icons.tag),
            helperText: 'Auto-generated but editable',
          ),
          onChanged: (val) {
            ref.read(invoiceFormProvider.notifier).updateFieldValue('invoice_number', val);
          },
        ),
      ),
    );

    // Date Fields using custom decorator calendar picking
    final dateVal = state.fieldValues['invoice_date'] ?? DateTime.now();
    final DateTime invoiceDate = dateVal is DateTime ? dateVal : DateTime.tryParse(dateVal.toString()) ?? DateTime.now();
    fields.add(_buildDateField('Invoice Date', 'invoice_date', invoiceDate));

    final dueVal = state.fieldValues['due_date'] ?? DateTime.now().add(const Duration(days: 7));
    final DateTime dueDate = dueVal is DateTime ? dueVal : DateTime.tryParse(dueVal.toString()) ?? DateTime.now();
    fields.add(_buildDateField('Due Date', 'due_date', dueDate));

    // Other invoice fields
    for (final f in invoiceSec.fields) {
      if (f.id == 'invoice_number' || f.id == 'invoice_date' || f.id == 'due_date') continue;
      if (!f.isVisible) continue;
      fields.add(_buildDynamicFieldWidget('invoice_info', f));
    }

    return _buildSectionCard(
      title: 'Invoice Details',
      icon: Icons.receipt_long,
      children: fields,
    );
  }

  Widget _buildCustomerDetailsCard(InvoiceFormState state) {
    final customerSec = state.activeTemplate.sections.firstWhere((s) => s.id == 'customer_details', orElse: () => SectionSchema(id: 'customer_details', title: '', orderIndex: 1, fields: []));
    if (!customerSec.isVisible) return const SizedBox();

    final List<Widget> fields = customerSec.fields
        .where((f) => f.isVisible)
        .map((f) => _buildDynamicFieldWidget('customer_details', f))
        .toList();

    return _buildSectionCard(
      title: 'Bill To (Client Details)',
      icon: Icons.person_outline,
      children: fields,
    );
  }

  Widget _buildTourDetailsCard(InvoiceFormState state) {
    final serviceSec = state.activeTemplate.sections.firstWhere((s) => s.id == 'service_details', orElse: () => SectionSchema(id: 'service_details', title: '', orderIndex: 3, fields: []));
    final isTourism = state.templateType == 'tourism';
    if (!isTourism || !serviceSec.isVisible) return const SizedBox();

    final List<Widget> fields = [];
    
    for (final f in serviceSec.fields) {
      if (!f.isVisible) continue;
      if (f.valueType == 'date') {
        final val = state.fieldValues[f.id] ?? DateTime.now();
        final DateTime dt = val is DateTime ? val : DateTime.tryParse(val.toString()) ?? DateTime.now();
        fields.add(_buildDateField(f.label, f.id, dt));
      } else {
        fields.add(_buildDynamicFieldWidget('service_details', f));
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mode_of_travel, color: AppTheme.deepBlue, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'TOUR DETAILS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.autorenew, size: 12, color: AppTheme.primaryGreen),
                      SizedBox(width: 4),
                      Text(
                        'Reused for line items',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: fields,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailsCard(InvoiceFormState state, CompanyProfile? company) {
    final bankSec = state.activeTemplate.sections.firstWhere((s) => s.id == 'payment_info', orElse: () => SectionSchema(id: 'payment_info', title: '', orderIndex: 6, fields: []));
    if (!bankSec.isVisible) return const SizedBox();

    final List<Widget> fields = bankSec.fields
        .where((f) => f.isVisible)
        .map((f) => _buildDynamicFieldWidget('payment_info', f))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance, color: AppTheme.deepBlue, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'BANK ACCOUNT DETAILS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
                    ),
                  ],
                ),
                if (company != null)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(invoiceFormProvider.notifier).updateFieldValue('bank_name', company.bankName);
                      ref.read(invoiceFormProvider.notifier).updateFieldValue('bank_account_no', company.bankAccountNumber);
                      ref.read(invoiceFormProvider.notifier).updateFieldValue('bank_ifsc', company.bankIfscCode);
                      ref.read(invoiceFormProvider.notifier).updateFieldValue('bank_account_name', company.bankAccountName);
                      ref.read(invoiceFormProvider.notifier).updateFieldValue('bank_branch', 'Dehradun');
                      _syncControllersWithState(ref.read(invoiceFormProvider));
                    },
                    icon: const Icon(Icons.settings_backup_restore),
                    label: const Text('Reset to Company defaults'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: fields,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCard(InvoiceFormState state) {
    final termsSec = state.activeTemplate.sections.firstWhere((s) => s.id == 'terms_conditions', orElse: () => SectionSchema(id: 'terms_conditions', title: '', orderIndex: 7, fields: []));
    if (!termsSec.isVisible) return const SizedBox();

    final termsField = termsSec.fields.firstWhere((f) => f.id == 'terms_text', orElse: () => FieldSchema(id: 'terms_text', label: 'Terms', valueType: 'text'));
    final controller = _controllers['terms_text'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description, color: AppTheme.deepBlue, size: 22),
                SizedBox(width: 10),
                Text(
                  'TERMS & CONDITIONS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLines: 5,
              minLines: 5,
              decoration: InputDecoration(
                labelText: termsField.label,
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 80.0),
                  child: Icon(Icons.text_snippet_outlined),
                ),
              ),
              onChanged: (val) {
                ref.read(invoiceFormProvider.notifier).updateFieldValue('terms_text', val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection(InvoiceFormState state, CompanyProfile? company) {
    final sigType = state.fieldValues['signature_type']?.toString() ?? 'company';
    final sigText = state.fieldValues['signature_text']?.toString() ?? 'Abhishek Prajapati';
    final sigPath = state.fieldValues['signature_image_path']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.border_color, color: AppTheme.deepBlue, size: 22),
                SizedBox(width: 10),
                Text('AUTHORIZED SIGNATURE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Default Company'),
                  selected: sigType == 'company',
                  onSelected: (val) {
                    if (val) ref.read(invoiceFormProvider.notifier).updateFieldValue('signature_type', 'company');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Upload Custom'),
                  selected: sigType == 'upload',
                  onSelected: (val) {
                    if (val) ref.read(invoiceFormProvider.notifier).updateFieldValue('signature_type', 'upload');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Type Name'),
                  selected: sigType == 'text',
                  onSelected: (val) {
                    if (val) ref.read(invoiceFormProvider.notifier).updateFieldValue('signature_type', 'text');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sigType == 'company') ...[
              if (company?.signaturePath != null && File(company!.signaturePath!).existsSync()) ...[
                const Text('Using Company Signature (e.g. LN Tourism):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  height: 60,
                  width: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.file(File(company.signaturePath!), fit: BoxFit.contain),
                ),
              ] else ...[
                const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text('No company signature uploaded. Setup in Company Profile.', style: TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ),
              ],
            ] else if (sigType == 'upload') ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickSignatureImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choose Image'),
                  ),
                  const SizedBox(width: 16),
                  if (sigPath.isNotEmpty && File(sigPath).existsSync()) ...[
                    Container(
                      height: 60,
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Stack(
                        children: [
                          Positioned.fill(child: Image.file(File(sigPath), fit: BoxFit.contain)),
                          Positioned(
                            right: -8,
                            top: -8,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                              onPressed: () {
                                ref.read(invoiceFormProvider.notifier).updateFieldValue('signature_image_path', '');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text('No custom signature image uploaded.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ],
              ),
            ] else if (sigType == 'text') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 350,
                    child: TextField(
                      controller: _controllers['signature_text'],
                      decoration: const InputDecoration(
                        labelText: 'Type Signatory Name',
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                      onChanged: (val) {
                        ref.read(invoiceFormProvider.notifier).updateFieldValue('signature_text', val);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Preview Signature Style:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    height: 60,
                    width: 250,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Text(
                      sigText.isEmpty ? 'Abhishek Prajapati' : sigText,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, String fieldId, DateTime date) {
    return SizedBox(
      width: 300,
      child: InkWell(
        onTap: () => _selectDate(context, date, (d) {
          ref.read(invoiceFormProvider.notifier).updateFieldValue(fieldId, d);
        }),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            _df.format(date),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFieldWidget(String sectionId, FieldSchema field) {
    final controller = _controllers[field.id];
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final width = isDesktop ? 300.0 : 1000.0;

    Widget inputWidget;

    switch (field.valueType) {
      case 'checkbox':
        final isChecked = ref.watch(invoiceFormProvider).fieldValues[field.id] == true;
        inputWidget = SwitchListTile(
          title: Text(field.label, style: const TextStyle(fontSize: 13)),
          value: isChecked,
          onChanged: (val) {
            ref.read(invoiceFormProvider.notifier).updateFieldValue(field.id, val);
          },
        );
        break;

      case 'date':
        final state = ref.watch(invoiceFormProvider);
        final dateVal = state.fieldValues[field.id];
        DateTime date = DateTime.now();
        if (dateVal is DateTime) {
          date = dateVal;
        } else if (dateVal != null) {
          date = DateTime.tryParse(dateVal.toString()) ?? DateTime.now();
        }

        inputWidget = _buildDateField(field.label, field.id, date);
        return SizedBox(child: inputWidget);

      case 'dropdown':
        final state = ref.watch(invoiceFormProvider);
        final currentVal = state.fieldValues[field.id]?.toString() ?? '';
        final options = field.dropdownOptions ?? [];

        inputWidget = DropdownButtonFormField<String>(
          value: options.contains(currentVal) ? currentVal : (options.isNotEmpty ? options.first : null),
          decoration: InputDecoration(labelText: field.label),
          items: options.map((opt) {
            return DropdownMenuItem(value: opt, child: Text(opt));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              ref.read(invoiceFormProvider.notifier).updateFieldValue(field.id, val);
            }
          },
        );
        break;

      case 'number':
        inputWidget = TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: field.label,
            prefixIcon: const Icon(Icons.tag, size: 16),
          ),
          onChanged: (val) {
            ref.read(invoiceFormProvider.notifier).updateFieldValue(field.id, val);
          },
        );
        break;

      case 'currency':
        inputWidget = TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: field.label,
            prefixIcon: const Icon(Icons.currency_rupee, size: 16),
          ),
          onChanged: (val) {
            ref.read(invoiceFormProvider.notifier).updateFieldValue(field.id, val);
          },
        );
        break;

      case 'text':
      default:
        final bool isCustomerNameEmpty = field.id == 'customer_name' &&
            ref.watch(invoiceFormProvider).customerName.trim().isEmpty;
        inputWidget = TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.label,
            prefixIcon: const Icon(Icons.text_fields, size: 16),
            errorText: isCustomerNameEmpty ? 'Customer Name is required' : null,
          ),
          onChanged: (val) {
            ref.read(invoiceFormProvider.notifier).updateFieldValue(field.id, val);
          },
        );
        break;
    }

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: inputWidget,
      ),
    );
  }

  Widget _buildBadgeIcon(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildItemsEditorCard(InvoiceFormState state) {
    final isTourism = state.templateType == 'tourism';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.list_alt, color: AppTheme.deepBlue, size: 22),
                    SizedBox(width: 10),
                    Text('LINE ITEMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _addNewItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (state.items.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 44, color: Colors.amber.shade700),
                      const SizedBox(height: 12),
                      Text(
                        'At Least One Line Item is Required',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please click "Add Row" to append items to your invoice.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        onPressed: _addNewItemDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Line Item Now'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  
                  String itemDesc = item.description;
                  Map<String, String> itemCustomValues = {};
                  try {
                    final decoded = jsonDecode(item.description) as Map<String, dynamic>;
                    if (decoded.containsKey('description')) {
                      itemDesc = decoded['description']?.toString() ?? '';
                      final custom = decoded['customValues'] as Map<String, dynamic>?;
                      if (custom != null) {
                        custom.forEach((k, v) {
                          itemCustomValues[k] = v.toString();
                        });
                      }
                    }
                  } catch (_) {}

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 5,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemDesc,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.deepBlue),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        if (isTourism) ...[
                                          _buildBadgeIcon(Icons.directions_car_outlined, '${item.noOfVehicles ?? 1} Vehicles'),
                                          if (item.date != null)
                                            _buildBadgeIcon(Icons.calendar_today_outlined, _df.format(item.date!)),
                                          if (item.fromTo != null && item.fromTo!.isNotEmpty)
                                            _buildBadgeIcon(Icons.route_outlined, item.fromTo!),
                                        ],
                                        _buildBadgeIcon(Icons.tag, '${item.quantityDays.toStringAsFixed(item.quantityDays % 1 == 0 ? 0 : 1)} ${isTourism ? "Days" : "Qty"}'),
                                        _buildBadgeIcon(Icons.currency_rupee, '@ Rs. ${item.rate.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                    if (itemCustomValues.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        children: itemCustomValues.entries.map((e) {
                                          return Chip(
                                            label: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 10)),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. ${item.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _editItemDialog(index, item),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => ref.read(invoiceFormProvider.notifier).removeItem(index),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGstModuleCard(InvoiceFormState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.percent, color: AppTheme.deepBlue, size: 22),
                SizedBox(width: 10),
                Text('GST & PAYMENTS CALCULATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('GST Mode: '),
                ChoiceChip(
                  label: const Text('Exclusive (Amount + GST)'),
                  selected: !state.isGstInclusive,
                  onSelected: (val) {
                    ref.read(invoiceFormProvider.notifier).updateFields(isGstInclusive: !val);
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Inclusive (GST in Total)'),
                  selected: state.isGstInclusive,
                  onSelected: (val) {
                    ref.read(invoiceFormProvider.notifier).updateFields(isGstInclusive: val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('GST Rate: '),
                const SizedBox(width: 8),
                if (!_isGstCustom) ...[
                  DropdownButton<double>(
                    value: [0.0, 5.0, 12.0, 18.0, 28.0].contains(state.gstPercentage) ? state.gstPercentage : 5.0,
                    items: const [
                      DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                      DropdownMenuItem(value: 5.0, child: Text('5% (Tourism/Cab)')),
                      DropdownMenuItem(value: 12.0, child: Text('12%')),
                      DropdownMenuItem(value: 18.0, child: Text('18%')),
                      DropdownMenuItem(value: 28.0, child: Text('28%')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(invoiceFormProvider.notifier).updateFields(gstPercentage: val);
                      }
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isGstCustom = true;
                      });
                    },
                    child: const Text('Custom Rate'),
                  )
                ] else ...[
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _customGstCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Rate %', contentPadding: EdgeInsets.all(8)),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          ref.read(invoiceFormProvider.notifier).updateFields(gstPercentage: parsed);
                        }
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isGstCustom = false;
                      });
                      ref.read(invoiceFormProvider.notifier).updateFields(gstPercentage: 5.0);
                    },
                    child: const Text('Standard Rates'),
                  )
                ]
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _advancePaidCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Advance Payment Received (Rs.)', prefixIcon: Icon(Icons.payment)),
                    onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(advancePaid: double.tryParse(val) ?? 0.0),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _balanceDueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Remaining Balance Due (Rs.)',
                      prefixIcon: Icon(Icons.money_off),
                      helperText: 'Entering balance due reverse-calculates advance payment',
                    ),
                    onChanged: (val) {
                      final double parsedBalance = double.tryParse(val) ?? 0.0;
                      final double grandTotal = state.gstCalculations.grandTotal;
                      final double calculatedAdvance = grandTotal - parsedBalance;
                      ref.read(invoiceFormProvider.notifier).updateFields(
                        advancePaid: calculatedAdvance > 0 ? calculatedAdvance : 0.0,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(String label, double value, {bool isBold = false, bool isNegative = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          Text(
            '${isNegative ? "-" : ""}Rs. ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: color ?? (isBold ? AppTheme.deepBlue : null),
            ),
          ),
        ],
      ),
    );
  }
}
