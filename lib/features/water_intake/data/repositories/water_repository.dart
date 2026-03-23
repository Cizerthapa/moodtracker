import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodtrack/core/constants/app_constants.dart';

class WaterRepository {
  WaterRepository._internal();
  static final WaterRepository _instance = WaterRepository._internal();
  factory WaterRepository() => _instance;
  Future<List<String>> getDrinkHistoryStrings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(AppConstants.drinkHistoryPrefsKey) ?? [];
  }

  Future<void> saveDrinkHistoryStrings(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.drinkHistoryPrefsKey, history);
  }

  Future<void> addDrink(String entryJson) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(AppConstants.drinkHistoryPrefsKey) ?? [];
    history.add(entryJson);
    await prefs.setStringList(AppConstants.drinkHistoryPrefsKey, history);
  }

  Future<void> deleteDrink(int originalIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(AppConstants.drinkHistoryPrefsKey) ?? [];
    if (originalIndex >= 0 && originalIndex < history.length) {
      history.removeAt(originalIndex);
      await prefs.setStringList(AppConstants.drinkHistoryPrefsKey, history);
    }
  }

  Future<String> getHydrationUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('hydration_unit') ?? 'ml';
  }

  Future<void> setHydrationUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hydration_unit', unit);
  }
}
