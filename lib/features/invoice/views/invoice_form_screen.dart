import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
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
          if (_controllers[field.id]!.text != text) {
            _controllers[field.id]!.text = text;
          }
        } else {
          _controllers[field.id] = TextEditingController(text: text);
        }
      }
    }
    
    _advancePaidCtrl.text = state.advancePaid == 0 ? '' : state.advancePaid.toString();
    _customGstCtrl.text = state.gstPercentage.toString();
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
    super.dispose();
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

    final descCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final vehiclesCtrl = TextEditingController(text: '1');
    final fromToCtrl = TextEditingController();
    DateTime itemDate = DateTime.now();

    final customCols = state.activeTemplate.tableColumns
        .where((c) => c.isVisible && !const ['s_no', 'description', 'no_of_vehicles', 'date', 'from_to', 'qty', 'rate', 'amount'].contains(c.id))
        .toList();
    final Map<String, TextEditingController> customCtrls = {
      for (final col in customCols) col.id: TextEditingController()
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: const Text('Add Line Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description / Service Name'),
                ),
                const SizedBox(height: 12),
                if (isTourism) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: vehiclesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'No. of Vehicles'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
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
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_df.format(itemDate)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fromToCtrl,
                    decoration: const InputDecoration(labelText: 'From - To (Route)'),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: isTourism ? 'Qty / Days' : 'Qty'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Rate (Rs.)'),
                      ),
                    ),
                  ],
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
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                descCtrl.dispose();
                rateCtrl.dispose();
                qtyCtrl.dispose();
                vehiclesCtrl.dispose();
                fromToCtrl.dispose();
                for (final ctrl in customCtrls.values) {
                  ctrl.dispose();
                }
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (descCtrl.text.isNotEmpty && rateCtrl.text.isNotEmpty) {
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
                  for (final ctrl in customCtrls.values) {
                    ctrl.dispose();
                  }
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            )
          ],
        ),
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
        builder: (context, setStateBuilder) => AlertDialog(
          title: const Text('Edit Line Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description / Service Name'),
                ),
                const SizedBox(height: 12),
                if (isTourism) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: vehiclesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'No. of Vehicles'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
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
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_df.format(itemDate)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fromToCtrl,
                    decoration: const InputDecoration(labelText: 'From - To (Route)'),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: isTourism ? 'Qty / Days' : 'Qty'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Rate (Rs.)'),
                      ),
                    ),
                  ],
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
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                descCtrl.dispose();
                rateCtrl.dispose();
                qtyCtrl.dispose();
                vehiclesCtrl.dispose();
                fromToCtrl.dispose();
                for (final ctrl in customCtrls.values) {
                  ctrl.dispose();
                }
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (descCtrl.text.isNotEmpty && rateCtrl.text.isNotEmpty) {
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
                  for (final ctrl in customCtrls.values) {
                    ctrl.dispose();
                  }
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Update'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _previewAndSave() async {
    final state = ref.read(invoiceFormProvider);
    if (state.customerName.isEmpty) {
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

    final invoiceId = await ref.read(invoiceFormProvider.notifier).saveInvoice();

    final db = ref.read(databaseProvider);
    final invoiceHeader = await (db.select(db.invoices)..where((t) => t.id.equals(invoiceId))).getSingle();
    final itemsList = await (db.select(db.invoiceItems)..where((t) => t.invoiceId.equals(invoiceId))).get();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoicePreviewScreen(
            invoice: invoiceHeader,
            items: itemsList,
            company: company,
          ),
        ),
      ).then((_) {
        ref.read(invoiceFormProvider.notifier).initDefaults(template: state.activeTemplate);
        _syncControllersWithState(ref.read(invoiceFormProvider));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceFormProvider);
    final templatesVal = ref.watch(templatesProvider);

    _syncControllersWithState(state);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          ref.read(invoiceFormProvider.notifier).saveInvoice();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice saved successfully!'), backgroundColor: AppTheme.primaryGreen),
          );
        },
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): _previewAndSave,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Generate Invoice'),
            actions: [
              // Visual designer button
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
              // Dynamic Templates List Dropdown
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
              // Main Scrollable Editor Form
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...(state.activeTemplate.sections
                              .where((s) => s.isVisible && s.id != 'items_table' && s.id != 'tax_summary')
                              .toList()
                            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)))
                          .map((sec) => _buildDynamicSectionCard(sec))
                          .toList(),
                      
                      const SizedBox(height: 16),

                      // Items list editor Card (items_table section)
                      _buildItemsEditorCard(state),
                      
                      const SizedBox(height: 16),

                      // Calculation & GST setup modules
                      _buildGstModuleCard(state),

                      const SizedBox(height: 32),

                      ElevatedButton.icon(
                        onPressed: _previewAndSave,
                        icon: const Icon(Icons.visibility),
                        label: const Text('Preview & Generate Document'),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Quick Action Panel / Calculation summaries
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
        ),
      ),
    );
  }

  // --- Dynamic Section Card Widget Builders ---

  Widget _buildDynamicSectionCard(SectionSchema sec) {
    final visibleFields = sec.fields.where((f) => f.isVisible).toList();
    if (visibleFields.isEmpty) return const SizedBox();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sec.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: visibleFields.map((f) => _buildDynamicFieldWidget(sec.id, f)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicFieldWidget(String sectionId, FieldSchema field) {
    // Generate text editing controller dynamically
    final controller = _controllers[field.id];

    // Determine field layout width
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final width = isDesktop ? 300.0 : 1000.0; // Responsive width

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

        inputWidget = OutlinedButton.icon(
          onPressed: () => _selectDate(context, date, (d) {
            ref.read(invoiceFormProvider.notifier).updateFieldValue(field.id, d);
          }),
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text('${field.label}: ${_df.format(date)}'),
        );
        break;

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
        inputWidget = TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.label,
            prefixIcon: const Icon(Icons.text_fields, size: 16),
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
                const Text('LINE ITEMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue)),
                ElevatedButton.icon(
                  onPressed: _addNewItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No items added yet. Click Add Row to add line items.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.items.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return ListTile(
                    title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      isTourism
                          ? '${item.noOfVehicles ?? 1} Vehicles x ${item.quantityDays} Days @ Rs. ${item.rate}'
                          : '${item.quantityDays} Qty @ Rs. ${item.rate}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rs. ${item.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editItemDialog(index, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => ref.read(invoiceFormProvider.notifier).removeItem(index),
                        ),
                      ],
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
            const Text('GST CALCULATION MODULE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue)),
            const SizedBox(height: 16),
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
            TextField(
              controller: _advancePaidCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Advance Payment Received (Rs.)', prefixIcon: Icon(Icons.payment)),
              onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(advancePaid: double.tryParse(val) ?? 0.0),
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
