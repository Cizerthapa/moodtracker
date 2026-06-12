import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/core/error/result.dart';

class SettingsRepository {
  final FlutterSecureStorage _secureStorage;
  SettingsRepository(this._secureStorage);
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
      final secureVal = await _secureStorage.read(key: AppConstants.biometricPrefsKey);
      if (secureVal != null) {
        return Success(secureVal == 'true');
      }

      // Migration from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefsVal = prefs.getBool(AppConstants.biometricPrefsKey);
      
      if (prefsVal != null) {
        // Migrate
        await _secureStorage.write(key: AppConstants.biometricPrefsKey, value: prefsVal.toString());
        await prefs.remove(AppConstants.biometricPrefsKey);
        return Success(prefsVal);
      }
      
      return const Success(false);
    } catch (e) {
      log('Preferences: Error getting biometric setting: $e', name: 'Preferences');
      return Failure('Failed to load biometric settings', error: e);
    }
  }

  Future<Result<void>> setBiometricEnabled(bool enabled) async {
    log('Preferences: Setting biometric enabled: $enabled', name: 'Preferences');
    try {
      await _secureStorage.write(key: AppConstants.biometricPrefsKey, value: enabled.toString());
      return const Success(null);
    } catch (e) {
      log('Preferences: Error setting biometric: $e', name: 'Preferences');
      return Failure('Failed to save biometric settings', error: e);
    }
  }
}
