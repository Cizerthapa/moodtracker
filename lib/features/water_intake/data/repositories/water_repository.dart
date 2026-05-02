import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/core/error/result.dart';

class WaterRepository {
  WaterRepository();
  Future<Result<List<String>>> getDrinkHistoryStrings() async {
    log('Preferences: Getting drink history', name: 'Preferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(AppConstants.drinkHistoryPrefsKey) ?? [];
      log('Preferences: Retrieved ${history.length} drink entries', name: 'Preferences');
      return Success(history);
    } catch (e) {
      log('Preferences: Error getting drink history: $e', name: 'Preferences');
      return Failure('Failed to load hydration history', error: e);
    }
  }

  Future<Result<void>> saveDrinkHistoryStrings(List<String> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(AppConstants.drinkHistoryPrefsKey, history);
      return const Success(null);
    } catch (e) {
      log('Preferences: Error saving history: $e', name: 'Preferences');
      return Failure('Failed to save hydration data', error: e);
    }
  }

  Future<Result<void>> addDrink(String entryJson) async {
    log('Preferences: Adding drink entry', name: 'Preferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(AppConstants.drinkHistoryPrefsKey) ?? [];
      history.add(entryJson);
      await prefs.setStringList(AppConstants.drinkHistoryPrefsKey, history);
      log('Preferences: Drink entry added successfully', name: 'Preferences');
      return const Success(null);
    } catch (e) {
      log('Preferences: Error adding drink: $e', name: 'Preferences');
      return Failure('Failed to add drink entry', error: e);
    }
  }

  Future<Result<void>> deleteDrink(int originalIndex) async {
    log('Preferences: Deleting drink at index $originalIndex', name: 'Preferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(AppConstants.drinkHistoryPrefsKey) ?? [];
      if (originalIndex >= 0 && originalIndex < history.length) {
        history.removeAt(originalIndex);
        await prefs.setStringList(AppConstants.drinkHistoryPrefsKey, history);
        log('Preferences: Drink deleted successfully', name: 'Preferences');
        return const Success(null);
      } else {
        log('Preferences: Index $originalIndex out of bounds', name: 'Preferences');
        return const Failure('Entry not found');
      }
    } catch (e) {
      log('Preferences: Error deleting drink: $e', name: 'Preferences');
      return Failure('Failed to delete drink entry', error: e);
    }
  }

  Future<Result<String>> getHydrationUnit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Success(prefs.getString('hydration_unit') ?? 'ml');
    } catch (e) {
      log('Preferences: Error getting hydration unit: $e', name: 'Preferences');
      return Failure('Failed to load hydration unit', error: e);
    }
  }

  Future<Result<void>> setHydrationUnit(String unit) async {
    log('Preferences: Setting hydration unit to $unit', name: 'Preferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hydration_unit', unit);
      return const Success(null);
    } catch (e) {
      log('Preferences: Error setting hydration unit: $e', name: 'Preferences');
      return Failure('Failed to save hydration unit', error: e);
    }
  }
}
