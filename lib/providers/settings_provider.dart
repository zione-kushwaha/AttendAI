import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajiri/core/database/database_service.dart';

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final DatabaseService _db = DatabaseService();

  SettingsNotifier()
    : super({
        'isDarkMode': false,
        'pinEnabled': false,
        'pin': '',
        'language': 'en',
      }) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from the database
    final settings = _db.settingsBox.toMap();

    if (settings.isNotEmpty) {
      state = {...state, ...settings};
    } else {
      // Save default settings if none exist
      await saveSettings(state);
    }
  }

  // Save settings to database
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _db.settingsBox.putAll(settings);
    state = settings;
  }

  // Update a single setting
  Future<void> updateSetting(String key, dynamic value) async {
    await _db.settingsBox.put(key, value);
    state = {...state, key: value};
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    final isDarkMode = !state['isDarkMode'];
    await updateSetting('isDarkMode', isDarkMode);
  }

  // Set PIN protection
  Future<void> setPinProtection({required bool enabled, String? pin}) async {
    await updateSetting('pinEnabled', enabled);
    if (pin != null) {
      await updateSetting('pin', pin);
    }
  }

  // Change language
  Future<void> setLanguage(String languageCode) async {
    await updateSetting('language', languageCode);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
      return SettingsNotifier();
    });
