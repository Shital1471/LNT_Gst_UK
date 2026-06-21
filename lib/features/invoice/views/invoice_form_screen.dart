import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/database_provider.dart';
import '../../company/providers/company_provider.dart';
import '../models/invoice_form_state.dart';
import '../providers/invoice_form_provider.dart';
import 'invoice_preview_screen.dart';
import '../../../core/utils/num_to_words.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _df = DateFormat('dd/MM/yyyy');
  
  final _customerNameCtrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();
  final _customerGstCtrl = TextEditingController();
  final _customerContactCtrl = TextEditingController();

  final _tourTripCtrl = TextEditingController();
  final _noOfDaysCtrl = TextEditingController();
  final _noOfVehiclesCtrl = TextEditingController();
  final _coordinatorCtrl = TextEditingController();
  final _invoiceNoCtrl = TextEditingController();
  final _advancePaidCtrl = TextEditingController();
  final _bookingRefCtrl = TextEditingController();

  bool _isGstCustom = false;
  final _customGstCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Register listeners to sync text controllers with provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(invoiceFormProvider);
      _syncControllersWithState(state);
    });
  }

  void _syncControllersWithState(InvoiceFormState state) {
    _customerNameCtrl.text = state.customerName;
    _customerAddressCtrl.text = state.customerAddress;
    _customerGstCtrl.text = state.customerGstNumber;
    _customerContactCtrl.text = state.customerContactNumber;
    
    _tourTripCtrl.text = state.tourTrip;
    _noOfDaysCtrl.text = state.noOfDays?.toString() ?? '';
    _noOfVehiclesCtrl.text = state.noOfVehicles?.toString() ?? '';
    _coordinatorCtrl.text = state.coordinatorName;
    _invoiceNoCtrl.text = state.invoiceNumber;
    _bookingRefCtrl.text = state.bookingRef;
    _advancePaidCtrl.text = state.advancePaid == 0 ? '' : state.advancePaid.toString();
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerAddressCtrl.dispose();
    _customerGstCtrl.dispose();
    _customerContactCtrl.dispose();
    _tourTripCtrl.dispose();
    _noOfDaysCtrl.dispose();
    _noOfVehiclesCtrl.dispose();
    _coordinatorCtrl.dispose();
    _invoiceNoCtrl.dispose();
    _bookingRefCtrl.dispose();
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
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: isTourism ? 'Qty / Days' : 'Qty'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Rate (Rs.)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (descCtrl.text.isNotEmpty && rateCtrl.text.isNotEmpty) {
                  ref.read(invoiceFormProvider.notifier).addItem(
                        InvoiceFormItem(
                          description: descCtrl.text,
                          rate: double.tryParse(rateCtrl.text) ?? 0.0,
                          quantityDays: double.tryParse(qtyCtrl.text) ?? 1.0,
                          noOfVehicles: isTourism ? int.tryParse(vehiclesCtrl.text) : null,
                          date: isTourism ? itemDate : null,
                          fromTo: isTourism ? fromToCtrl.text : null,
                        ),
                      );
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
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: isTourism ? 'Qty / Days' : 'Qty'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Rate (Rs.)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (descCtrl.text.isNotEmpty && rateCtrl.text.isNotEmpty) {
                  ref.read(invoiceFormProvider.notifier).updateItem(
                        index,
                        InvoiceFormItem(
                          description: descCtrl.text,
                          rate: double.tryParse(rateCtrl.text) ?? 0.0,
                          quantityDays: double.tryParse(qtyCtrl.text) ?? 1.0,
                          noOfVehicles: isTourism ? int.tryParse(vehiclesCtrl.text) : null,
                          date: isTourism ? itemDate : null,
                          fromTo: isTourism ? fromToCtrl.text : null,
                        ),
                      );
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
    // Perform validation
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

    // Load company profile
    final companyVal = ref.read(companyProfileStateProvider);
    final company = companyVal.value;

    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set up company profile first'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Save active state database record
    final invoiceId = await ref.read(invoiceFormProvider.notifier).saveInvoice();

    // Query full details from database to ensure consistency
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
        // Increment next invoice number upon returning
        ref.read(invoiceFormProvider.notifier).initDefaults();
        _syncControllersWithState(ref.read(invoiceFormProvider));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceFormProvider);
    final isTourism = state.templateType == 'tourism';

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
              // Template Selector Toggle
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, size: 16, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: state.templateType,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'tourism', child: Text('Tourism Layout', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'standard', child: Text('Standard Layout', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(invoiceFormProvider.notifier).updateFields(templateType: val);
                        }
                      },
                    ),
                  ],
                ),
              ),
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ROW 1: Customer Billing & Invoice Metadata
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Billing Card
                    Expanded(
                      flex: 3,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('BILL TO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _customerNameCtrl,
                                decoration: const InputDecoration(labelText: 'Customer/Company Name *', prefixIcon: Icon(Icons.person)),
                                onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(customerName: val),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _customerAddressCtrl,
                                decoration: const InputDecoration(labelText: 'Billing Address *', prefixIcon: Icon(Icons.location_city)),
                                onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(customerAddress: val),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _customerGstCtrl,
                                      decoration: const InputDecoration(labelText: 'Customer GSTIN', prefixIcon: Icon(Icons.receipt)),
                                      onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(customerGstNumber: val),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _customerContactCtrl,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(labelText: 'Contact No.', prefixIcon: Icon(Icons.phone)),
                                      onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(customerContactNumber: val),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Metadata Card
                    Expanded(
                      flex: 2,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('INVOICE META', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _invoiceNoCtrl,
                                decoration: const InputDecoration(labelText: 'Invoice Number *', prefixIcon: Icon(Icons.tag)),
                                onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(invoiceNumber: val),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _selectDate(context, state.invoiceDate, (d) {
                                        ref.read(invoiceFormProvider.notifier).updateFields(invoiceDate: d);
                                      }),
                                      icon: const Icon(Icons.calendar_today, size: 16),
                                      label: Text('Date: ${_df.format(state.invoiceDate)}'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _selectDate(context, state.dueDate, (d) {
                                        ref.read(invoiceFormProvider.notifier).updateFields(dueDate: d);
                                      }),
                                      icon: const Icon(Icons.event, size: 16),
                                      label: Text('Due: ${_df.format(state.dueDate)}'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _bookingRefCtrl,
                                decoration: const InputDecoration(labelText: 'Booking Reference', prefixIcon: Icon(Icons.bookmark)),
                                onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(bookingRef: val),
                              ),
                              if (state.bookingDate != null) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _selectDate(context, state.bookingDate!, (d) {
                                    ref.read(invoiceFormProvider.notifier).updateFields(bookingDate: d);
                                  }),
                                  icon: const Icon(Icons.date_range, size: 16),
                                  label: Text('Booking Date: ${_df.format(state.bookingDate!)}'),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                
                const SizedBox(height: 16),

                // ROW 2: Service Booking details (Tourism only)
                if (isTourism) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOURISM SERVICE DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _tourTripCtrl,
                                  decoration: const InputDecoration(labelText: 'Tour / Trip Details (Description)'),
                                  onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(tourTrip: val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectDate(context, state.travelDate ?? DateTime.now(), (d) {
                                    ref.read(invoiceFormProvider.notifier).updateFields(travelDate: d);
                                  }),
                                  icon: const Icon(Icons.flight_takeoff, size: 16),
                                  label: Text(state.travelDate != null ? 'Travel: ${_df.format(state.travelDate!)}' : 'Travel Date'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _noOfDaysCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'No. of Days'),
                                  onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(noOfDays: int.tryParse(val)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _noOfVehiclesCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'No. of Vehicles'),
                                  onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(noOfVehicles: int.tryParse(val)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _coordinatorCtrl,
                                  decoration: const InputDecoration(labelText: 'Co-ordinator Name'),
                                  onChanged: (val) => ref.read(invoiceFormProvider.notifier).updateFields(coordinatorName: val),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ROW 3: Line Items Editor Card
                Card(
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
                ),
                
                const SizedBox(height: 16),

                // ROW 4: GST Configuration & Summary block
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: GST Settings
                        Expanded(
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
                                      value: state.gstPercentage,
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
                        const SizedBox(width: 24),
                        
                        // Right: Calculations Summary panel
                        Container(
                          width: 280,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('SUMMARY CALCULATIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.deepBlue)),
                              const SizedBox(height: 12),
                              _calcRow('Sub Total', state.gstCalculations.subTotal),
                              _calcRow('CGST @ ${(state.gstPercentage / 2).toStringAsFixed(2)}%', state.gstCalculations.cgst),
                              _calcRow('SGST @ ${(state.gstPercentage / 2).toStringAsFixed(2)}%', state.gstCalculations.sgst),
                              const Divider(),
                              _calcRow('Grand Total', state.gstCalculations.grandTotal, isBold: true),
                              _calcRow('Advance Paid', state.advancePaid, isNegative: true),
                              const Divider(color: AppTheme.primaryGreen),
                              _calcRow('Amount to be Paid', state.balanceDue, isBold: true, color: AppTheme.primaryGreen),
                              const SizedBox(height: 8),
                              Text(
                                'In Words: ${NumberToWords.convert(state.balanceDue)}',
                                style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                
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
