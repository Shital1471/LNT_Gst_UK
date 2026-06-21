import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/settings_provider.dart';
import '../../company/providers/company_provider.dart';

class CompanySetupScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  const CompanySetupScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends ConsumerState<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  
  final _bankAccountNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankIfscController = TextEditingController();

  String? _logoPath;
  String? _signaturePath;
  double _defaultGst = 5.0;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(companyProfileStateProvider.notifier).loadProfile().then((_) {
          final profileVal = ref.read(companyProfileStateProvider);
          profileVal.whenData((profile) {
            if (profile != null) {
              _nameController.text = profile.name;
              _addressController.text = profile.address;
              _gstController.text = profile.gstNumber;
              _contactController.text = profile.contactNumber;
              _emailController.text = profile.email;
              _bankAccountNameController.text = profile.bankAccountName;
              _bankNameController.text = profile.bankName;
              _bankAccountNumberController.text = profile.bankAccountNumber;
              _bankIfscController.text = profile.bankIfscCode;
              setState(() {
                _logoPath = profile.logoPath;
                _signaturePath = profile.signaturePath;
                _defaultGst = profile.defaultGstPercentage;
              });
            }
          });
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _bankAccountNameController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankIfscController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _logoPath = result.files.single.path;
      });
    }
  }

  Future<void> _pickSignature() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _signaturePath = result.files.single.path;
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(companyProfileStateProvider.notifier).saveProfile(
            name: _nameController.text,
            address: _addressController.text,
            gstNumber: _gstController.text,
            contactNumber: _contactController.text,
            email: _emailController.text,
            bankAccountName: _bankAccountNameController.text,
            bankName: _bankNameController.text,
            bankAccountNumber: _bankAccountNumberController.text,
            bankIfscCode: _bankIfscController.text,
            logoPath: _logoPath,
            signaturePath: _signaturePath,
            defaultGstPercentage: _defaultGst,
          );

      ref.read(settingsProvider.notifier).completeOnboarding();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company profile saved successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        if (widget.isEditing) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modify Company Profile' : 'Setup Company Profile'),
        automaticallyImplyLeading: widget.isEditing,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.isEditing) ...[
                  Text(
                    'Welcome to GST Invoice Generator',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepBlue,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Let\'s configure your business details to get started. This info will appear on all generated invoices.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
                
                // STEP 1: Basic Business Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Business Info',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.deepBlue),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Company Name *',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Company name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Company Address *',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Address is required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _gstController,
                                decoration: const InputDecoration(
                                  labelText: 'GSTIN *',
                                  prefixIcon: Icon(Icons.percent),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'GSTIN is required';
                                  if (val.length != 15) return 'GSTIN must be 15 chars';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<double>(
                                value: _defaultGst,
                                decoration: const InputDecoration(
                                  labelText: 'Default GST %',
                                  prefixIcon: Icon(Icons.percent),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 0.0, child: Text('0%')),
                                  DropdownMenuItem(value: 5.0, child: Text('5%')),
                                  DropdownMenuItem(value: 12.0, child: Text('12%')),
                                  DropdownMenuItem(value: 18.0, child: Text('18%')),
                                  DropdownMenuItem(value: 28.0, child: Text('28%')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _defaultGst = val;
                                    });
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _contactController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Number *',
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Contact is required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address *',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Email is required' : null,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // STEP 2: Bank Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bank Details (For Payments)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.deepBlue),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bankAccountNameController,
                          decoration: const InputDecoration(
                            labelText: 'Account Holder Name *',
                            prefixIcon: Icon(Icons.account_box),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Account name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bankNameController,
                          decoration: const InputDecoration(
                            labelText: 'Bank Name *',
                            prefixIcon: Icon(Icons.account_balance),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Bank name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _bankAccountNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Account Number *',
                                  prefixIcon: Icon(Icons.numbers),
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Account number is required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _bankIfscController,
                                decoration: const InputDecoration(
                                  labelText: 'IFSC Code *',
                                  prefixIcon: Icon(Icons.code),
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'IFSC is required' : null,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // STEP 3: Images & Branding Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Branding & Signatures',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.deepBlue),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Logo Upload
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('Company Logo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _pickLogo,
                                    child: Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2A2E2A) : const Color(0xFFF1F5F1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                                      ),
                                      alignment: Alignment.center,
                                      child: _logoPath != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(File(_logoPath!), height: 80, fit: BoxFit.contain),
                                            )
                                          : const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add_photo_alternate, size: 36, color: AppTheme.primaryGreen),
                                                Text('Upload Image', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Signature Upload
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('Authorized Signature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _pickSignature,
                                    child: Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2A2E2A) : const Color(0xFFF1F5F1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                                      ),
                                      alignment: Alignment.center,
                                      child: _signaturePath != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(File(_signaturePath!), height: 80, fit: BoxFit.contain),
                                            )
                                          : const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.draw, size: 36, color: AppTheme.primaryGreen),
                                                Text('Upload Signature', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.isEditing ? 'Save Changes' : 'Complete Setup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
