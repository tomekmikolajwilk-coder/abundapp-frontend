import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Wstrzykiwany w main.dart z gotową instancją SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in main'),
);

// Klucze
const _keyChartType = 'chart_type';

// Notifier który czyta/zapisuje preferencje
class PreferencesNotifier extends Notifier<Map<String, dynamic>> {
  late SharedPreferences _prefs;

  @override
  Map<String, dynamic> build() {
    _prefs = ref.read(sharedPreferencesProvider);
    return {
      _keyChartType: _prefs.getString(_keyChartType) ?? 'bar',
    };
  }

  void setChartType(String value) {
    _prefs.setString(_keyChartType, value);
    state = {...state, _keyChartType: value};
  }

  String get chartType => state[_keyChartType] as String;
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, Map<String, dynamic>>(
  PreferencesNotifier.new,
);
