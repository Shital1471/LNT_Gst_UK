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

      final result = await FilePicker.platform.saveFile(
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
      final result = await FilePicker.platform.pickFiles(
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
    
    final companyAsyncVal = ref.watch(companyProfileStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Theme settings
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepBlue)),
                  leading: const Icon(Icons.tune, color: AppTheme.primaryGreen),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Dark Theme'),
                  subtitle: const Text('Enable dark mode for the entire application'),
                  secondary: const Icon(Icons.dark_mode),
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
                  title: const Text('Business Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepBlue)),
                  leading: const Icon(Icons.business, color: AppTheme.primaryGreen),
                ),
                const Divider(height: 1),
                companyAsyncVal.when(
                  data: (profile) => ListTile(
                    title: Text(profile?.name ?? 'No company configured'),
                    subtitle: Text(profile?.gstNumber ?? ''),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CompanySetupScreen(isEditing: true),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
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
                  title: const Text('Invoice Customizer', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepBlue)),
                  leading: const Icon(Icons.dashboard_customize, color: AppTheme.primaryGreen),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Visual Layout Designer'),
                  subtitle: const Text('Visually drag-and-drop elements and customize styles'),
                  leading: const Icon(Icons.palette, color: Colors.purple),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InvoiceDesignerScreen()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  title: const Text('Manage Templates'),
                  subtitle: const Text('Import, export, duplicate, and configure invoice layout templates'),
                  leading: const Icon(Icons.tune, color: Colors.blue),
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
                  title: const Text('Database & Backups', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepBlue)),
                  leading: const Icon(Icons.storage, color: AppTheme.primaryGreen),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Backup Database'),
                  subtitle: const Text('Save a copy of your invoices locally'),
                  leading: const Icon(Icons.backup),
                  onTap: () => _backupDatabase(context, ref),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  title: const Text('Restore Database'),
                  subtitle: const Text('Restore settings and invoices from a backup file'),
                  leading: const Icon(Icons.restore),
                  onTap: () => _restoreDatabase(context, ref),
                ),
              ],
            ),
          ),
          
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Keyboard Shortcuts (Desktop)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepBlue)),
                    const SizedBox(height: 8),
                    _shortcutRow('Ctrl + N', 'Create New Invoice'),
                    _shortcutRow('Ctrl + S', 'Save Invoice Draft'),
                    _shortcutRow('Ctrl + P', 'Print / View Preview'),
                    _shortcutRow('Esc', 'Go Back / Exit Dialogs'),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _shortcutRow(String keys, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(description, style: const TextStyle(fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              keys,
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
