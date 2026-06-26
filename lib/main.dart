import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/database_provider.dart';
import 'core/utils/navigation.dart';
import 'features/onboarding/views/company_setup_screen.dart';
import 'features/dashboard/views/dashboard_screen.dart';
import 'features/invoice/providers/invoice_form_provider.dart';
import 'features/invoice/views/invoice_form_screen.dart';
import 'features/invoice/views/invoice_history_screen.dart';
import 'features/invoice/views/invoice_preview_screen.dart';
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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          ref.read(invoiceFormProvider.notifier).reset();
          ref.read(tabIndexProvider.notifier).state = 1;
          final context = navigatorKey.currentContext;
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New Invoice Form Initialized'),
                backgroundColor: AppTheme.primaryGreen,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () async {
          final state = ref.read(invoiceFormProvider);
          final context = navigatorKey.currentContext;
          if (context == null) return;

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
        },
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () async {
          final state = ref.read(invoiceFormProvider);
          final context = navigatorKey.currentContext;
          if (context == null) return;

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
                ),
              ),
            );
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
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (navigatorKey.currentState?.canPop() == true) {
            navigatorKey.currentState?.pop();
          }
        },
      },
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
}

class AppLayout extends ConsumerWidget {
  const AppLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(tabIndexProvider);

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

    final isLargeScreen = MediaQuery.of(context).size.width >= 800;

    if (isLargeScreen) {
      // Desktop Premium Sidebar Layout
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onTabChange,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppTheme.primaryGreen),
              selectedLabelTextStyle: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
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
      // Mobile / Tablet Bottom Bar Layout
      return Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTabChange,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryGreen,
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
}
