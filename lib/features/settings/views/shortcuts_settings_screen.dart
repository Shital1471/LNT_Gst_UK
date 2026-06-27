import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/shortcuts_provider.dart';

class ShortcutsSettingsScreen extends ConsumerWidget {
  const ShortcutsSettingsScreen({super.key});

  void _recordShortcut(BuildContext context, WidgetRef ref, String id, AppShortcut shortcut) {
    showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ShortcutRecorderDialog(shortcutName: shortcut.name),
    ).then((result) {
      if (!context.mounted) return;
      if (result != null) {
        final key = result['key'] as LogicalKeyboardKey;
        final control = result['control'] as bool;
        final shift = result['shift'] as bool;
        final alt = result['alt'] as bool;

        final shortcuts = ref.read(shortcutsProvider);
        String? conflictingAction;
        
        shortcuts.forEach((actionId, existing) {
          if (actionId != id &&
              existing.key.keyId == key.keyId &&
              existing.control == control &&
              existing.shift == shift &&
              existing.alt == alt) {
            conflictingAction = existing.name;
          }
        });

        if (conflictingAction != null) {
          final List<String> keyParts = [];
          if (control) keyParts.add('Ctrl');
          if (alt) keyParts.add('Alt');
          if (shift) keyParts.add('Shift');
          keyParts.add(AppShortcut.cleanKeyLabel(key.keyLabel));
          final combo = keyParts.join(' + ');

          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Shortcut Conflict'),
                ],
              ),
              content: Text(
                'The shortcut "$combo" is already assigned to "$conflictingAction". Please choose a different key combination.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        ref.read(shortcutsProvider.notifier).updateShortcut(
              id,
              key,
              key.keyLabel,
              control: control,
              shift: shift,
              alt: alt,
            );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated shortcut for "${shortcut.name}"'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcuts = ref.watch(shortcutsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Keyboard Shortcuts Settings',
          style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.keyboard_outlined, color: theme.colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customize Application Shortcuts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Set custom keyboard mappings for navigation and action triggers',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // List of shortcuts
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shortcuts.length,
                    separatorBuilder: (c, i) => Divider(color: theme.dividerColor.withOpacity(0.08), height: 1),
                    itemBuilder: (context, index) {
                      final key = shortcuts.keys.elementAt(index);
                      final shortcut = shortcuts[key]!;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        title: Text(
                          shortcut.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            shortcut.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0xFF131B2E)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                shortcut.displayString,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary, size: 20),
                              tooltip: 'Customize key',
                              onPressed: () => _recordShortcut(context, ref, key, shortcut),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Reset Shortcuts'),
                            content: const Text('Are you sure you want to reset all keyboard shortcuts to their factory defaults?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () {
                                  ref.read(shortcutsProvider.notifier).resetToDefaults();
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Shortcuts reset to defaults'),
                                      backgroundColor: theme.colorScheme.primary,
                                    ),
                                  );
                                },
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to Defaults'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutRecorderDialog extends StatefulWidget {
  final String shortcutName;
  const _ShortcutRecorderDialog({required this.shortcutName});

  @override
  State<_ShortcutRecorderDialog> createState() => _ShortcutRecorderDialogState();
}

class _ShortcutRecorderDialogState extends State<_ShortcutRecorderDialog> {
  final FocusNode _focusNode = FocusNode();
  bool _isCtrlPressed = false;
  bool _isShiftPressed = false;
  bool _isAltPressed = false;
  LogicalKeyboardKey? _primaryKey;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _currentKeysString() {
    final List<String> parts = [];
    if (_isCtrlPressed) parts.add('Ctrl');
    if (_isAltPressed) parts.add('Alt');
    if (_isShiftPressed) parts.add('Shift');
    if (_primaryKey != null) {
      parts.add(AppShortcut.cleanKeyLabel(_primaryKey!.keyLabel));
    } else {
      parts.add('...');
    }
    return parts.join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final rawKey = event.logicalKey;
            
            // Track modifier states
            final bool ctrl = HardwareKeyboard.instance.isControlPressed;
            final bool shift = HardwareKeyboard.instance.isShiftPressed;
            final bool alt = HardwareKeyboard.instance.isAltPressed;

            setState(() {
              _isCtrlPressed = ctrl;
              _isShiftPressed = shift;
              _isAltPressed = alt;
            });

            // If the pressed key is a modifier key itself, do not count as primary
            if (rawKey == LogicalKeyboardKey.controlLeft ||
                rawKey == LogicalKeyboardKey.controlRight ||
                rawKey == LogicalKeyboardKey.shiftLeft ||
                rawKey == LogicalKeyboardKey.shiftRight ||
                rawKey == LogicalKeyboardKey.altLeft ||
                rawKey == LogicalKeyboardKey.altRight ||
                rawKey == LogicalKeyboardKey.metaLeft ||
                rawKey == LogicalKeyboardKey.metaRight) {
              return KeyEventResult.handled;
            }

            setState(() {
              _primaryKey = rawKey;
            });

            // Delay pop slightly so the user sees the recorded key combo
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                Navigator.pop(context, {
                  'key': rawKey,
                  'control': ctrl,
                  'shift': shift,
                  'alt': alt,
                });
              }
            });
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_hide_outlined, size: 54, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Record Shortcut: ${widget.shortcutName}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Press the new key combination on your keyboard now. Hold Ctrl, Shift, or Alt as needed.',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1.5),
                ),
                child: Text(
                  _currentKeysString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
