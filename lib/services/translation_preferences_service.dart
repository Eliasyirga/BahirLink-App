import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationPreferencesService {
  static const String _amharicEnabledKey = 'amharicTranslationEnabled';

  static final ValueNotifier<bool> isAmharicEnabled = ValueNotifier<bool>(false);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    isAmharicEnabled.value = prefs.getBool(_amharicEnabledKey) ?? false;
  }

  static Future<void> setAmharicEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amharicEnabledKey, enabled);
    isAmharicEnabled.value = enabled;
  }
}
