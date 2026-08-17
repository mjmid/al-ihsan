import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/hive_helper.dart';

/// ============================================================
/// App Settings Model
/// ============================================================
/// Holds the current theme mode and locale for the app.
/// Persisted to Hive settings box.

class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale =
        const Locale('bn'), // Default: Bengali (most common for this app)
  });

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

/// ============================================================
/// AppSettingsNotifier — Riverpod StateNotifier
/// ============================================================
/// Manages theme and language settings.
/// Reads initial values from Hive on startup.
/// Persists every change back to Hive automatically.

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  /// Loads persisted settings from Hive on notifier creation.
  void _loadSettings() {
    final savedTheme = HiveHelper.getSetting<String>(kThemeModeKey, 'system');
    final savedLanguage = HiveHelper.getSetting<String>(kLanguageKey, 'bn');

    state = AppSettings(
      themeMode: _parseThemeMode(savedTheme),
      locale: Locale(savedLanguage),
    );
  }

  /// Converts stored string back to ThemeMode enum.
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Converts ThemeMode enum to storable string.
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  // ── Public Setters ────────────────────────────────────────────────────────

  /// Sets the theme mode and persists it to Hive.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await HiveHelper.setSetting(kThemeModeKey, _themeModeToString(mode));
  }

  /// Sets the app language and persists it to Hive.
  Future<void> setLanguage(String languageCode) async {
    state = state.copyWith(locale: Locale(languageCode));
    await HiveHelper.setSetting(kLanguageKey, languageCode);
  }
}

/// ============================================================
/// Providers
/// ============================================================

/// The main settings provider — used in MaktabaApp and settings screen.
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);
