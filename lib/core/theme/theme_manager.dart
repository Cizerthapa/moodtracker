import 'package:flutter/material.dart';
import 'package:moodtrack/core/theme/mood_palette.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/features/settings/data/repositories/settings_repository.dart';

class ThemeManager extends ChangeNotifier {
  final SettingsRepository _repository = SettingsRepository();
  MoodPalette _currentPalette = MoodPalette.classic;

  ThemeManager() {
    _loadTheme();
  }

  MoodPalette get palette => _currentPalette;

  Future<void> _loadTheme() async {
    final themeName = await _repository.getThemeName();
    _currentPalette = MoodPalette.fromName(themeName);
    AppColors.update(_currentPalette);
    notifyListeners();
  }

  Future<void> setTheme(MoodPalette palette) async {
    _currentPalette = palette;
    AppColors.update(_currentPalette);
    await _repository.setThemeName(palette.name);
    notifyListeners();
  }
}
