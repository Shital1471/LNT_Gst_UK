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
    final result = await FilePicker.pickFiles(
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
    final result = await FilePicker.pickFiles(
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 600;

    // Responsive wrappers for text fields
    Widget buildResponsiveRow(Widget child1, Widget child2) {
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child1),
            const SizedBox(width: 16),
            Expanded(child: child2),
          ],
        );
      } else {
        return Column(
          children: [
            child1,
            const SizedBox(height: 16),
            child2,
          ],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Modify Business Profile' : 'Setup Business Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        automaticallyImplyLeading: widget.isEditing,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.isEditing) ...[
                      Text(
                        'Welcome to GST Invoice',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Configure your official business credentials to get started. These details will be automatically formatted onto generated invoices.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),
                    ],

                    // STEP 1: Basic Business Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.business_center_rounded,
                                      color: theme.colorScheme.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Business Credentials',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Legal Company Name *',
                                prefixIcon: Icon(Icons.business_rounded),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Company name is required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Official Registered Address *',
                                prefixIcon: Icon(Icons.location_on_rounded),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Address is required' : null,
                            ),
                            const SizedBox(height: 16),
                            buildResponsiveRow(
                              TextFormField(
                                controller: _gstController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'GSTIN (Tax ID) *',
                                  prefixIcon: Icon(Icons.pin_rounded),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'GSTIN is required';
                                  }
                                  if (val.trim().length != 15) {
                                    return 'GSTIN must be exactly 15 characters';
                                  }
                                  return null;
                                },
                              ),
                              DropdownButtonFormField<double>(
                                value: _defaultGst,
                                decoration: const InputDecoration(
                                  labelText: 'Default Tax Rate',
                                  prefixIcon: Icon(Icons.percent_rounded),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 0.0, child: Text('GST 0%')),
                                  DropdownMenuItem(value: 5.0, child: Text('GST 5%')),
                                  DropdownMenuItem(value: 12.0, child: Text('GST 12%')),
                                  DropdownMenuItem(value: 18.0, child: Text('GST 18%')),
                                  DropdownMenuItem(value: 28.0, child: Text('GST 28%')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _defaultGst = val;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            buildResponsiveRow(
                              TextFormField(
                                controller: _contactController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Primary Contact Number *',
                                  prefixIcon: Icon(Icons.phone_rounded),
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty ? 'Contact is required' : null,
                              ),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Official Email Address *',
                                  prefixIcon: Icon(Icons.email_rounded),
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty ? 'Email is required' : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // STEP 2: Bank Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.account_balance_rounded,
                                      color: theme.colorScheme.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Remittance & Bank Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _bankAccountNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Account Holder / Beneficiary Name *',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty
                                  ? 'Account name is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bankNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Financial Institution (Bank Name) *',
                                prefixIcon: Icon(Icons.account_balance_outlined),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Bank name is required' : null,
                            ),
                            const SizedBox(height: 16),
                            buildResponsiveRow(
                              TextFormField(
                                controller: _bankAccountNumberController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Account Routing Number *',
                                  prefixIcon: Icon(Icons.numbers_rounded),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty
                                    ? 'Account number is required'
                                    : null,
                              ),
                              TextFormField(
                                controller: _bankIfscController,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'IFSC Code *',
                                  prefixIcon: Icon(Icons.qr_code_rounded),
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty ? 'IFSC code is required' : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // STEP 3: Images & Branding Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.palette_rounded,
                                      color: theme.colorScheme.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Branding & Signatures',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            buildResponsiveRow(
                              // Logo Upload
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Company Logo Accent',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: _pickLogo,
                                    child: Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: _logoPath != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.file(File(_logoPath!), height: 90, fit: BoxFit.contain),
                                            )
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add_photo_alternate_rounded,
                                                    size: 32, color: theme.colorScheme.primary),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Click to select file',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              // Signature Upload
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Authorized Signatory',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: _pickSignature,
                                    child: Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: _signaturePath != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.file(File(_signaturePath!), height: 90, fit: BoxFit.contain),
                                            )
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.draw_rounded,
                                                    size: 32, color: theme.colorScheme.primary),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Click to select file',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                                ),
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

                    const SizedBox(height: 36),

                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: Text(
                        widget.isEditing ? 'Update Profile Settings' : 'Initialize Application',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

