import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moodtrack/core/constants/app_constants.dart';

class WaterRepository {
  WaterRepository._internal();
  static final WaterRepository _instance = WaterRepository._internal();
  factory WaterRepository() => _instance;
  Future<List<String>> getDrinkHistoryStrings() async {
    log('Preferences: Getting drink history', name: 'Preferences');
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(AppConstants.drinkHistoryPrefsKey) ?? [];
    log('Preferences: Retrieved ${history.length} drink entries', name: 'Preferences');
    return history;
  }

  Future<void> saveDrinkHistoryStrings(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.drinkHistoryPrefsKey, history);
  }

  Future<void> addDrink(String entryJson) async {
    log('Preferences: Adding drink entry', name: 'Preferences');
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(AppConstants.drinkHistoryPrefsKey) ?? [];
    history.add(entryJson);
    await prefs.setStringList(AppConstants.drinkHistoryPrefsKey, history);
    log('Preferences: Drink entry added successfully', name: 'Preferences');
  }

  Future<void> deleteDrink(int originalIndex) async {
    log('Preferences: Deleting drink at index $originalIndex', name: 'Preferences');
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(AppConstants.drinkHistoryPrefsKey) ?? [];
    if (originalIndex >= 0 && originalIndex < history.length) {
      history.removeAt(originalIndex);
      await prefs.setStringList(AppConstants.drinkHistoryPrefsKey, history);
      log('Preferences: Drink deleted successfully', name: 'Preferences');
    } else {
      log('Preferences: Index $originalIndex out of bounds for drink deletion', name: 'Preferences');
    }
  }

  Future<String> getHydrationUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('hydration_unit') ?? 'ml';
  }

  Future<void> setHydrationUnit(String unit) async {
    log('Preferences: Setting hydration unit to $unit', name: 'Preferences');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hydration_unit', unit);
  }
}
