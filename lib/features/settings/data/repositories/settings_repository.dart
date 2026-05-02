import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/core/error/result.dart';

class SettingsRepository {
  SettingsRepository();
  Future<Result<bool>> getNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Success(prefs.getBool(AppConstants.notificationsPrefsKey) ?? false);
    } catch (e) {
      log('Preferences: Error getting notifications setting: $e', name: 'Preferences');
      return Failure('Failed to load notification settings', error: e);
    }
  }

  Future<Result<void>> setNotificationsEnabled(bool enabled) async {
    log('Preferences: Setting notifications enabled: $enabled', name: 'Preferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.notificationsPrefsKey, enabled);
      return const Success(null);
    } catch (e) {
      log('Preferences: Error setting notifications: $e', name: 'Preferences');
      return Failure('Failed to save notification settings', error: e);
    }
  }

  Future<Result<String>> getThemeName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Success(prefs.getString('theme_name') ?? 'Classic');
    } catch (e) {
      log('Preferences: Error getting theme: $e', name: 'Preferences');
      return Failure('Failed to load theme setting', error: e);
    }
  }

  Future<Result<void>> setThemeName(String themeName) async {
    log('Preferences: Setting theme: $themeName', name: 'Preferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_name', themeName);
      return const Success(null);
    } catch (e) {
      log('Preferences: Error setting theme: $e', name: 'Preferences');
      return Failure('Failed to save theme setting', error: e);
    }
  }

  Future<Result<bool>> getBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Success(prefs.getBool(AppConstants.biometricPrefsKey) ?? false);
    } catch (e) {
      log('Preferences: Error getting biometric setting: $e', name: 'Preferences');
      return Failure('Failed to load biometric settings', error: e);
    }
  }

  Future<Result<void>> setBiometricEnabled(bool enabled) async {
    log('Preferences: Setting biometric enabled: $enabled', name: 'Preferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.biometricPrefsKey, enabled);
      return const Success(null);
    } catch (e) {
      log('Preferences: Error setting biometric: $e', name: 'Preferences');
      return Failure('Failed to save biometric settings', error: e);
    }
  }
}
