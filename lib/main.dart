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

    if (isLargeScreen) {
      // Desktop Standard NavigationRail Layout
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onTabChange,
              labelType: NavigationRailLabelType.all,
              backgroundColor: isDark ? const Color(0xFF151C2C) : Colors.white,
              selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
              selectedLabelTextStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500, fontSize: 11),
              unselectedIconTheme: IconThemeData(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              unselectedLabelTextStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w300, fontSize: 11),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    _buildLogo(company, theme.colorScheme),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 72,
                      child: Text(
                        company?.name ?? 'GST Invoice',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IconButton(
                      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 18),
                      color: theme.colorScheme.primary,
                      onPressed: () {
                        ref.read(settingsProvider.notifier).toggleTheme(!isDark);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.edit_note_outlined), selectedIcon: Icon(Icons.edit_note), label: Text('Create')),
                NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('History')),
                NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Reports')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: screens[currentIndex],
            ),
          ],
        ),
      );
    } else {
      // Mobile / Tablet Bottom Bar Layout + Standard Material Drawer
      return Scaffold(
        key: layoutScaffoldKey,
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151C2C) : const Color(0xFFF8FAFC),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'v1.0.0 • Standard',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 20),
                title: Text(isDark ? 'Dark Theme' : 'Light Theme', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).toggleTheme(val);
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _buildDrawerTile(context, Icons.dashboard_outlined, 'Dashboard', 0, currentIndex, onTabChange),
                    _buildDrawerTile(context, Icons.edit_note_outlined, 'Create Invoice', 1, currentIndex, onTabChange),
                    _buildDrawerTile(context, Icons.history_outlined, 'History', 2, currentIndex, onTabChange),
                    _buildDrawerTile(context, Icons.analytics_outlined, 'Reports', 3, currentIndex, onTabChange),
                    _buildDrawerTile(context, Icons.settings_outlined, 'Settings', 4, currentIndex, onTabChange),
                  ],
                ),
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
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), activeIcon: Icon(Icons.edit_note), label: 'Create'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      );
    }
  }

  Widget _buildDrawerTile(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    int currentIndex,
    ValueChanged<int> onTabChange,
  ) {
    final isSelected = currentIndex == index;
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onTap: () {
        onTabChange(index);
        Navigator.pop(context); // Close Drawer
      },
    );
  }
}
