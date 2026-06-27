import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../company/providers/company_provider.dart';
import '../../onboarding/views/company_setup_screen.dart';
import '../../invoice/views/invoice_designer_screen.dart';
import '../../invoice/views/template_management_screen.dart';
import 'shortcuts_settings_screen.dart';
import '../../../core/utils/navigation.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _backupDatabase(BuildContext context, WidgetRef ref) async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'gst_invoice.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('Database file not found. Create an invoice first.');
      }

      final result = await FilePicker.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName: 'gst_invoice_backup.db',
      );

      if (result != null) {
        await dbFile.copy(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Database backup saved to: $result'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreDatabase(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select Backup Database (.db)',
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        final dbFolder = await getApplicationDocumentsDirectory();
        final destinationPath = p.join(dbFolder.path, 'gst_invoice.db');

        // Close db connection first to release file lock
        final db = ref.read(databaseProvider);
        await db.close();

        // Copy backup over active db
        await File(sourcePath).copy(destinationPath);

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Database Restored'),
              content: const Text(
                'The database was successfully restored. The application will close to complete the process. Please reopen the application.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    exit(0);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    
    final companyAsyncVal = ref.watch(companyProfileStateProvider);

    final isWide = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
        ),
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => layoutScaffoldKey.currentState?.openDrawer(),
              ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Theme settings
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'Preferences',
                        style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                      ),
                      leading: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                    ),
                    Divider(color: theme.dividerColor.withOpacity(0.08), height: 1),
                    SwitchListTile(
                      title: const Text('Dark Theme Mode'),
                      subtitle: const Text('Enable dark mode for the entire application'),
                      secondary: Icon(Icons.dark_mode_rounded, color: theme.colorScheme.secondary),
                      value: isDark,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).toggleTheme(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Business Details profile modifier
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'Business Details',
                        style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                      ),
                      leading: Icon(Icons.business_center_rounded, color: theme.colorScheme.primary),
                    ),
                    Divider(color: theme.dividerColor.withOpacity(0.08), height: 1),
                    companyAsyncVal.when(
                      data: (profile) => ListTile(
                        title: Text(
                          profile?.name ?? 'No company configured',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(profile?.gstNumber ?? ''),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CompanySetupScreen(isEditing: true),
                            ),
                          );
                        },
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => ListTile(title: Text('Error loading profile: $err')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Invoice Designer and templates management
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'Invoice Customizer',
                        style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                      ),
                      leading: Icon(Icons.dashboard_customize_rounded, color: theme.colorScheme.primary),
                    ),
                    Divider(color: theme.dividerColor.withOpacity(0.08), height: 1),
                    ListTile(
                      title: const Text('Visual Layout Designer'),
                      subtitle: const Text('Visually configure invoice templates, spacing, and styles'),
                      leading: Icon(Icons.palette_outlined, color: theme.colorScheme.secondary),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InvoiceDesignerScreen()),
                        );
                      },
                    ),
                    Divider(color: theme.dividerColor.withOpacity(0.08), height: 1, indent: 56),
                    ListTile(
                      title: const Text('Manage Templates'),
                      subtitle: const Text('Import, export, duplicate, and configure layout presets'),
                      leading: Icon(Icons.tune_rounded, color: theme.colorScheme.secondary),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TemplateManagementScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Database maintenance
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'Database & Backups',
                        style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                      ),
                      leading: Icon(Icons.storage_rounded, color: theme.colorScheme.primary),
                    ),
                    Divider(color: theme.dividerColor.withOpacity(0.08), height: 1),
                    ListTile(
                      title: const Text('Backup Database'),
                      subtitle: const Text('Save a copy of your database locally'),
                      leading: Icon(Icons.backup_table_rounded, color: theme.colorScheme.secondary),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () => _backupDatabase(context, ref),
                    ),
                    Divider(color: theme.dividerColor.withOpacity(0.08), height: 1, indent: 56),
                    ListTile(
                      title: const Text('Restore Database'),
                      subtitle: const Text('Restore settings and invoices from a local backup file'),
                      leading: Icon(Icons.settings_backup_restore_rounded, color: theme.colorScheme.secondary),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () => _restoreDatabase(context, ref),
                    ),
                  ],
                ),
              ),
              
              if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.keyboard_rounded, color: theme.colorScheme.primary),
                    title: const Text(
                      'Keyboard Shortcuts Settings',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('View and customize application keyboard shortcuts'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShortcutsSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
