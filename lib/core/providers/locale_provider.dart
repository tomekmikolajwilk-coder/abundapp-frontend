import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'preferences_provider.dart';

/// Ręczny override języka z ustawień. null = język systemowy telefonu (auto-detekcja).
/// Trzymany w SharedPreferences, żeby przeżył restart.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Locale? build() {
    final code = ref.read(sharedPreferencesProvider).getString(_key);
    return (code == null || code.isEmpty) ? null : Locale(code);
  }

  /// code = 'en'|'pl'|'de'|'fr'|'es' → wymuś język; null → wróć do systemowego.
  void set(String? code) {
    final prefs = ref.read(sharedPreferencesProvider);
    if (code == null) {
      prefs.remove(_key);
      state = null;
    } else {
      prefs.setString(_key, code);
      state = Locale(code);
    }
  }
}
