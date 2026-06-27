import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/shortcuts_provider.dart';
import 'core/utils/navigation.dart';
import 'core/utils/num_to_words.dart';
import 'core/database/app_database.dart';
import 'features/onboarding/views/company_setup_screen.dart';
import 'features/dashboard/views/dashboard_screen.dart';
import 'features/invoice/providers/invoice_form_provider.dart';
import 'features/invoice/views/invoice_form_screen.dart';
import 'features/invoice/views/invoice_history_screen.dart';
import 'features/invoice/views/invoice_preview_screen.dart';
import 'features/invoice/views/invoice_designer_screen.dart';
import 'features/invoice/views/template_management_screen.dart';
import 'features/company/providers/company_provider.dart';
import 'features/reports/views/reports_screen.dart';
import 'features/settings/views/settings_screen.dart';

final tabIndexProvider = StateProvider<int>((ref) => 0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const GstInvoiceApp(),
    ),
  );
}

class GstInvoiceApp extends ConsumerWidget {
  const GstInvoiceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final shortcuts = ref.watch(shortcutsProvider);

    // Build dynamic shortcuts mappings
    final Map<ShortcutActivator, VoidCallback> bindings = {};

    shortcuts.forEach((actionId, shortcut) {
      final activator = SingleActivator(
        shortcut.key,
        control: shortcut.control,
        shift: shortcut.shift,
        alt: shortcut.alt,
      );

      bindings[activator] = () {
        final currentContext = navigatorKey.currentContext;
        if (currentContext == null) return;

        switch (actionId) {
          case 'createNewInvoice':
            ref.read(invoiceFormProvider.notifier).reset();
            ref.read(tabIndexProvider.notifier).state = 1;
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(
                content: Text('New Invoice Form Initialized'),
                backgroundColor: AppTheme.primaryGreen,
                duration: Duration(seconds: 2),
              ),
            );
            break;

          case 'saveDraft':
            _triggerSaveDraft(ref, currentContext);
            break;

          case 'previewDocument':
            _triggerPreview(ref, currentContext, isTemporary: true);
            break;

          case 'previewGenerate':
            _triggerPreview(ref, currentContext, isTemporary: false);
            break;

          case 'designer':
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => const InvoiceDesignerScreen()),
            );
            break;

          case 'templates':
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => const TemplateManagementScreen()),
            );
            break;

          case 'reports':
            ref.read(tabIndexProvider.notifier).state = 3;
            break;

          case 'dashboard':
            ref.read(tabIndexProvider.notifier).state = 0;
            break;

          case 'history':
            ref.read(tabIndexProvider.notifier).state = 2;
            break;

          case 'companySetup':
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => const CompanySetupScreen(isEditing: true)),
            );
            break;

          case 'themeToggle':
            ref.read(settingsProvider.notifier).toggleTheme(settings.themeMode != ThemeMode.dark);
            break;

          case 'focusTemplateSelector':
            _showTemplateSelectorDialog(ref, currentContext);
            break;

          case 'goBack':
            if (navigatorKey.currentState?.canPop() == true) {
              navigatorKey.currentState?.pop();
            }
            break;
        }
      };
    });

    return CallbackShortcuts(
      bindings: bindings,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'GST Invoice Generator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.themeMode,
        home: settings.onboardingCompleted
            ? const AppLayout()
            : const CompanySetupScreen(),
      ),
    );
  }

  Future<void> _triggerSaveDraft(WidgetRef ref, BuildContext context) async {
    final state = ref.read(invoiceFormProvider);

    if (state.customerName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer Name is required to save draft'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one line item before saving draft'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await ref.read(invoiceFormProvider.notifier).saveInvoice();
      final currentContext = navigatorKey.currentContext;
      if (currentContext != null) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Invoice draft saved successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      final currentContext = navigatorKey.currentContext;
      if (currentContext != null) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Failed to save draft: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _triggerPreview(WidgetRef ref, BuildContext context, {required bool isTemporary}) async {
    final state = ref.read(invoiceFormProvider);

    if (state.customerName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer Name is required to preview'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one line item before previewing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final companyVal = ref.read(companyProfileStateProvider);
    final company = companyVal.value;

    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set up company profile first'),
          backgroundColor: Colors.orange,
        ),
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

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => InvoicePreviewScreen(
              invoice: tempInvoice,
              items: tempItemsList,
              company: company,
              isTemporary: true,
            ),
          ),
        );
      } else {
        final invoiceId = await ref.read(invoiceFormProvider.notifier).saveInvoice();
        final db = ref.read(databaseProvider);
        final invoiceHeader = await (db.select(db.invoices)..where((t) => t.id.equals(invoiceId))).getSingle();
        final itemsList = await (db.select(db.invoiceItems)..where((t) => t.invoiceId.equals(invoiceId))).get();

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => InvoicePreviewScreen(
              invoice: invoiceHeader,
              items: itemsList,
              company: company,
              isTemporary: false,
            ),
          ),
        ).then((_) {
          ref.read(invoiceFormProvider.notifier).initDefaults(template: state.activeTemplate);
        });
      }
    } catch (e) {
      final currentContext = navigatorKey.currentContext;
      if (currentContext != null) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error loading preview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTemplateSelectorDialog(WidgetRef ref, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(invoiceFormProvider);
          final templatesVal = ref.watch(templatesProvider);
          
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.palette_outlined, color: AppTheme.primaryGreen),
                SizedBox(width: 10),
                Text('Select Template Preset', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: templatesVal.when(
              data: (list) => SizedBox(
                width: 320,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final t = list[index];
                    final isSelected = state.activeTemplate.id == t.id;
                    return ListTile(
                      selected: isSelected,
                      selectedColor: AppTheme.primaryGreen,
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? AppTheme.primaryGreen : Colors.grey,
                      ),
                      title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(t.description, style: const TextStyle(fontSize: 11)),
                      onTap: () {
                        ref.read(invoiceFormProvider.notifier).updateTemplate(t);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched layout template to: ${t.name}'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Icon(Icons.error),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildLogo(CompanyProfile? company, ColorScheme colorScheme) {
  if (company != null && company.logoPath != null && company.logoPath!.isNotEmpty) {
    final file = File(company.logoPath!);
    if (file.existsSync()) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.file(
            file,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: colorScheme.primary.withOpacity(0.1),
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.business_center_rounded,
      color: colorScheme.primary,
      size: 18,
    ),
  );
}

class AppLayout extends ConsumerWidget {
  const AppLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(tabIndexProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final companyAsync = ref.watch(companyProfileStateProvider);
    final company = companyAsync.value;

    void onTabChange(int index) {
      ref.read(tabIndexProvider.notifier).state = index;
    }

    final screens = [
      DashboardScreen(onTabChange: onTabChange),
      const InvoiceFormScreen(),
      InvoiceHistoryScreen(onTabChange: onTabChange),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    final isLargeScreen = MediaQuery.of(context).size.width >= 950;
    
    final saffronColor = isDark ? AppTheme.saffronDark : AppTheme.saffronLight;
    final sidebarBg = isDark ? AppTheme.panelRaisedDark : AppTheme.panelRaisedLight;
    final voidBg = isDark ? AppTheme.voidDark : AppTheme.voidLight;
    final hairlineColor = isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight;
    final paperColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final mistColor = isDark ? AppTheme.mistDark : AppTheme.mistLight;

    if (isLargeScreen) {
      // Desktop Custom Sidebar Layout
      return Scaffold(
        backgroundColor: voidBg,
        body: Row(
          children: [
            // Custom Sidebar
            Container(
              width: 260,
              height: double.infinity,
              decoration: BoxDecoration(
                color: sidebarBg,
                border: Border(
                  right: BorderSide(color: hairlineColor, width: 1.0),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Workspace Title & Avatar
                  _buildSidebarWorkspaceHeader(company, theme),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      children: [
                        _buildSidebarSectionTitle('Workspace', theme),
                        _buildSidebarItem(
                          context: context,
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          label: 'Dashboard',
                          index: 0,
                          currentIndex: currentIndex,
                          onTap: onTabChange,
                        ),
                        _buildSidebarItem(
                          context: context,
                          icon: Icons.add_circle_outline_rounded,
                          activeIcon: Icons.add_circle,
                          label: 'Create invoice',
                          index: 1,
                          currentIndex: currentIndex,
                          onTap: onTabChange,
                        ),
                        _buildSidebarItem(
                          context: context,
                          icon: Icons.history_outlined,
                          activeIcon: Icons.history,
                          label: 'History',
                          index: 2,
                          currentIndex: currentIndex,
                          onTap: onTabChange,
                        ),
                        
                        _buildSidebarSectionTitle('Insights', theme),
                        _buildSidebarItem(
                          context: context,
                          icon: Icons.analytics_outlined,
                          activeIcon: Icons.analytics,
                          label: 'Reports',
                          index: 3,
                          currentIndex: currentIndex,
                          onTap: onTabChange,
                        ),
                        
                        _buildSidebarSectionTitle('Account', theme),
                        _buildSidebarItem(
                          context: context,
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings,
                          label: 'Settings',
                          index: 4,
                          currentIndex: currentIndex,
                          onTap: onTabChange,
                        ),
                      ],
                    ),
                  ),
                  
                  // Theme Toggle at bottom
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSidebarThemeSwitcher(context, isDark, ref),
                  ),
                ],
              ),
            ),
            
            // Content Screen
            Expanded(
              child: screens[currentIndex],
            ),
          ],
        ),
      );
    } else {
      // Mobile / Tablet Bottom Bar Layout + Custom Sidebar Drawer
      return Scaffold(
        key: layoutScaffoldKey,
        backgroundColor: voidBg,
        drawer: Drawer(
          backgroundColor: sidebarBg,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151C2C) : const Color(0xFFF8FAFC),
                  border: Border(bottom: BorderSide(color: hairlineColor)),
                ),
                child: Row(
                  children: [
                    _buildLogo(company, theme.colorScheme),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            company?.name ?? 'GST Invoice Pro',
                            style: AppTheme.uiFont(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: paperColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'v1.0.0 • Standard',
                            style: AppTheme.uiFont(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: mistColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    _buildSidebarSectionTitle('Workspace', theme),
                    _buildSidebarItem(
                      context: context,
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      label: 'Dashboard',
                      index: 0,
                      currentIndex: currentIndex,
                      onTap: (idx) {
                        onTabChange(idx);
                        Navigator.pop(context); // Close drawer
                      },
                    ),
                    _buildSidebarItem(
                      context: context,
                      icon: Icons.add_circle_outline_rounded,
                      activeIcon: Icons.add_circle,
                      label: 'Create invoice',
                      index: 1,
                      currentIndex: currentIndex,
                      onTap: (idx) {
                        onTabChange(idx);
                        Navigator.pop(context);
                      },
                    ),
                    _buildSidebarItem(
                      context: context,
                      icon: Icons.history_outlined,
                      activeIcon: Icons.history,
                      label: 'History',
                      index: 2,
                      currentIndex: currentIndex,
                      onTap: (idx) {
                        onTabChange(idx);
                        Navigator.pop(context);
                      },
                    ),
                    _buildSidebarSectionTitle('Insights', theme),
                    _buildSidebarItem(
                      context: context,
                      icon: Icons.analytics_outlined,
                      activeIcon: Icons.analytics,
                      label: 'Reports',
                      index: 3,
                      currentIndex: currentIndex,
                      onTap: (idx) {
                        onTabChange(idx);
                        Navigator.pop(context);
                      },
                    ),
                    _buildSidebarSectionTitle('Account', theme),
                    _buildSidebarItem(
                      context: context,
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      label: 'Settings',
                      index: 4,
                      currentIndex: currentIndex,
                      onTap: (idx) {
                        onTabChange(idx);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSidebarThemeSwitcher(context, isDark, ref),
              ),
            ],
          ),
        ),
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTabChange,
          type: BottomNavigationBarType.fixed,
          backgroundColor: sidebarBg,
          selectedItemColor: saffronColor,
          unselectedItemColor: mistColor,
          selectedLabelStyle: AppTheme.uiFont(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTheme.uiFont(fontSize: 11, fontWeight: FontWeight.w400),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), activeIcon: Icon(Icons.add_circle), label: 'Create'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      );
    }
  }

  Widget _buildSidebarWorkspaceHeader(CompanyProfile? company, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final paperColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final mistColor = isDark ? AppTheme.mistDark : AppTheme.mistLight;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildLogo(company, theme.colorScheme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  company?.name ?? 'Khata Workspace',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.uiFont(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: paperColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'GST Workspace',
                  style: AppTheme.uiFont(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: mistColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionTitle(String title, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final mistDimColor = isDark ? AppTheme.mistDimDark : AppTheme.mistDimLight;
    
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 18.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: AppTheme.uiFont(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: mistDimColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    final isSelected = index == currentIndex;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final saffronColor = isDark ? AppTheme.saffronDark : AppTheme.saffronLight;
    final saffronDimColor = isDark ? AppTheme.saffronDimDark : AppTheme.saffronDimLight;
    final paperColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final mistColor = isDark ? AppTheme.mistDark : AppTheme.mistLight;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? saffronDimColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Left 3px accent tab
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? saffronColor : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 9),
              Icon(
                isSelected ? activeIcon : icon,
                size: 18,
                color: isSelected ? saffronColor : mistColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.uiFont(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? saffronColor : paperColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarThemeSwitcher(BuildContext context, bool isDark, WidgetRef ref) {
    final saffronColor = isDark ? AppTheme.saffronDark : AppTheme.saffronLight;
    final paperColor = isDark ? AppTheme.paperDark : AppTheme.paperLight;
    final panelColor = isDark ? AppTheme.panelDark : AppTheme.panelLight;
    final hairlineColor = isDark ? AppTheme.hairlineDark : AppTheme.hairlineLight;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: hairlineColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 18,
                color: saffronColor,
              ),
              const SizedBox(width: 10),
              Text(
                isDark ? 'Dark mode' : 'Light mode',
                style: AppTheme.uiFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: paperColor,
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isDark,
              activeColor: saffronColor,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).toggleTheme(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
