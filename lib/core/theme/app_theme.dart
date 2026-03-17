import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moodtrack/core/theme/mood_palette.dart';

class AppTheme {
  static ThemeData getTheme(MoodPalette palette) {
    return ThemeData(
      brightness: palette.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: palette.cream,
      primaryColor: palette.roseDeep,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.roseDeep,
        primary: palette.roseDeep,
        secondary: palette.roseDust,
        surface: palette.ivoryCard,
        brightness: palette.isDark ? Brightness.dark : Brightness.light,
      ),
      fontFamily: 'Georgia',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: palette.warmBrown),
        titleTextStyle: TextStyle(
          color: palette.warmBrown,
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Georgia',
        ),
      ),
      useMaterial3: true,
    );
  }

  // Keeping darkTheme for backward compatibility if needed, but it should now be dynamic
  static ThemeData get darkTheme => getTheme(MoodPalette.midnight);
}
