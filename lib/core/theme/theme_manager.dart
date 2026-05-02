import 'package:flutter/material.dart';
import 'package:moodtrack/core/theme/mood_palette.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/features/settings/data/repositories/settings_repository.dart';
import 'package:moodtrack/core/di/service_locator.dart';


import 'package:moodtrack/core/error/result.dart';


class ThemeManager extends ChangeNotifier {
  final SettingsRepository _repository = sl<SettingsRepository>();
  MoodPalette _currentPalette = MoodPalette.classic;

  ThemeManager() {
    _loadTheme();
  }

  MoodPalette get palette => _currentPalette;

  Future<void> _loadTheme() async {
    final result = await _repository.getThemeName();
    if (result is Success<String>) {
      _currentPalette = MoodPalette.fromName(result.data);
      AppColors.update(_currentPalette);
      notifyListeners();
    }
  }

  Future<void> setTheme(MoodPalette palette) async {
    _currentPalette = palette;
    AppColors.update(_currentPalette);
    await _repository.setThemeName(palette.name);
    notifyListeners();
  }
}
