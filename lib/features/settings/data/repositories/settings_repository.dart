import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodtrack/core/constants/app_constants.dart';

class SettingsRepository {
  SettingsRepository._internal();
  static final SettingsRepository _instance = SettingsRepository._internal();
  factory SettingsRepository() => _instance;
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.notificationsPrefsKey) ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.notificationsPrefsKey, enabled);
  }

  Future<String> getThemeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_name') ?? 'Classic';
  }

  Future<void> setThemeName(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_name', themeName);
  }
}
