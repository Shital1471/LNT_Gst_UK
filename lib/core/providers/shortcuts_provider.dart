import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';

class AppShortcut {
  final String id;
  final String name;
  final String description;
  final LogicalKeyboardKey key;
  final String keyLabel;
  final bool control;
  final bool shift;
  final bool alt;

  AppShortcut({
    required this.id,
    required this.name,
    required this.description,
    required this.key,
    required this.keyLabel,
    this.control = false,
    this.shift = false,
    this.alt = false,
  });

  AppShortcut copyWith({
    LogicalKeyboardKey? key,
    String? keyLabel,
    bool? control,
    bool? shift,
    bool? alt,
  }) {
    return AppShortcut(
      id: id,
      name: name,
      description: description,
      key: key ?? this.key,
      keyLabel: keyLabel ?? this.keyLabel,
      control: control ?? this.control,
      shift: shift ?? this.shift,
      alt: alt ?? this.alt,
    );
  }

  String get displayString {
    final List<String> parts = [];
    if (control) parts.add('Ctrl');
    if (alt) parts.add('Alt');
    if (shift) parts.add('Shift');
    parts.add(cleanKeyLabel(keyLabel));
    return parts.join(' + ');
  }

  static String cleanKeyLabel(String label) {
    if (label.isEmpty) return 'Unknown';
    if (label.startsWith('Key ')) return label.substring(4);
    if (label.startsWith('Digit ')) return label.substring(6);
    return label;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'keyId': key.keyId,
      'keyLabel': keyLabel,
      'control': control,
      'shift': shift,
      'alt': alt,
    };
  }

  factory AppShortcut.fromJson(Map<String, dynamic> json) {
    final keyId = json['keyId'] as int;
    final keyLabel = json['keyLabel'] as String? ?? '';
    return AppShortcut(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      key: LogicalKeyboardKey(keyId),
      keyLabel: keyLabel,
      control: json['control'] as bool? ?? false,
      shift: json['shift'] as bool? ?? false,
      alt: json['alt'] as bool? ?? false,
    );
  }
}

class ShortcutsNotifier extends StateNotifier<Map<String, AppShortcut>> {
  final SharedPreferences _prefs;

  ShortcutsNotifier(this._prefs) : super({}) {
    _loadShortcuts();
  }

  static Map<String, AppShortcut> getDefaults() {
    return {
      'createNewInvoice': AppShortcut(id: 'createNewInvoice', name: 'Create New Invoice', description: 'Reset form and switch to creation screen', key: LogicalKeyboardKey.keyN, keyLabel: 'N', control: true),
      'saveDraft': AppShortcut(id: 'saveDraft', name: 'Save Draft', description: 'Save current invoice as a draft', key: LogicalKeyboardKey.keyS, keyLabel: 'S', control: true),
      'previewDocument': AppShortcut(id: 'previewDocument', name: 'Preview Document', description: 'Compile layout and open preview in draft mode (no save)', key: LogicalKeyboardKey.keyP, keyLabel: 'P', control: true),
      'previewGenerate': AppShortcut(id: 'previewGenerate', name: 'Preview & Generate', description: 'Finalize invoice, show preview, and reset form', key: LogicalKeyboardKey.keyG, keyLabel: 'G', control: true),
      'designer': AppShortcut(id: 'designer', name: 'Open Designer', description: 'Navigate to invoice designer', key: LogicalKeyboardKey.keyD, keyLabel: 'D', control: true),
      'templates': AppShortcut(id: 'templates', name: 'Open Templates', description: 'Navigate to template setup', key: LogicalKeyboardKey.keyT, keyLabel: 'T', control: true),
      'reports': AppShortcut(id: 'reports', name: 'Open Reports', description: 'Switch active view to reports', key: LogicalKeyboardKey.keyR, keyLabel: 'R', control: true),
      'dashboard': AppShortcut(id: 'dashboard', name: 'Open Dashboard', description: 'Switch active view to dashboard', key: LogicalKeyboardKey.keyH, keyLabel: 'H', control: true, shift: true),
      'history': AppShortcut(id: 'history', name: 'Open History', description: 'Switch active view to invoice history', key: LogicalKeyboardKey.keyH, keyLabel: 'H', control: true),
      'companySetup': AppShortcut(id: 'companySetup', name: 'Open Business Profile', description: 'Navigate to business profile settings', key: LogicalKeyboardKey.keyB, keyLabel: 'B', control: true),
      'themeToggle': AppShortcut(id: 'themeToggle', name: 'Toggle Theme', description: 'Toggle between dark and light modes', key: LogicalKeyboardKey.keyT, keyLabel: 'T', control: true, shift: true),
      'focusTemplateSelector': AppShortcut(id: 'focusTemplateSelector', name: 'Change Template', description: 'Open quick template selector overlay', key: LogicalKeyboardKey.keyL, keyLabel: 'L', control: true),
      'goBack': AppShortcut(id: 'goBack', name: 'Go Back / Exit', description: 'Dismiss current dialog or return to previous screen', key: LogicalKeyboardKey.escape, keyLabel: 'Escape'),
    };
  }

  void _loadShortcuts() {
    final String? data = _prefs.getString('keyboard_shortcuts');
    if (data == null) {
      state = getDefaults();
      return;
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(data);
      final Map<String, AppShortcut> loaded = {};
      final defaults = getDefaults();
      
      defaults.forEach((key, defVal) {
        if (decoded.containsKey(key)) {
          loaded[key] = AppShortcut.fromJson(decoded[key]);
        } else {
          loaded[key] = defVal;
        }
      });
      state = loaded;
    } catch (_) {
      state = getDefaults();
    }
  }

  Future<void> updateShortcut(String id, LogicalKeyboardKey key, String keyLabel, {bool control = false, bool shift = false, bool alt = false}) async {
    if (!state.containsKey(id)) return;
    
    final updated = Map<String, AppShortcut>.from(state);
    updated[id] = updated[id]!.copyWith(
      key: key,
      keyLabel: keyLabel,
      control: control,
      shift: shift,
      alt: alt,
    );
    state = updated;
    await _saveShortcuts();
  }

  Future<void> resetToDefaults() async {
    state = getDefaults();
    await _prefs.remove('keyboard_shortcuts');
  }

  Future<void> _saveShortcuts() async {
    final Map<String, dynamic> rawMap = {};
    state.forEach((key, value) {
      rawMap[key] = value.toJson();
    });
    await _prefs.setString('keyboard_shortcuts', jsonEncode(rawMap));
  }
}

final shortcutsProvider = StateNotifierProvider<ShortcutsNotifier, Map<String, AppShortcut>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ShortcutsNotifier(prefs);
});
