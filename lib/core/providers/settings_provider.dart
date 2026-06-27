import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized');
});

class SettingsState {
  final ThemeMode themeMode;
  final bool onboardingCompleted;

  SettingsState({
    required this.themeMode,
    required this.onboardingCompleted,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? onboardingCompleted,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs)
      : super(SettingsState(
          themeMode: ThemeMode.values[_prefs.getInt('theme_mode') ?? 0],
          onboardingCompleted: _prefs.getBool('onboarding_completed') ?? false,
        ));

  void toggleTheme(bool isDark) {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    _prefs.setInt('theme_mode', mode.index);
    state = state.copyWith(themeMode: mode);
  }

  void completeOnboarding() {
    _prefs.setBool('onboarding_completed', true);
    state = state.copyWith(onboardingCompleted: true);
  }

  void resetOnboarding() {
    _prefs.setBool('onboarding_completed', false);
    state = state.copyWith(onboardingCompleted: false);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
