import 'package:flutter/material.dart';
import 'package:moodtrack/core/theme/mood_palette.dart';

class AppColors {
  AppColors._(); // Private constructor

  static MoodPalette _active = MoodPalette.classic;

  static void update(MoodPalette palette) {
    _active = palette;
  }

  // ─── Dynamic Palette ────────────────────────────────────────────────
  static Color get cream => _active.cream;
  static Color get roseDust => _active.roseDust;
  static Color get roseDeep => _active.roseDeep;
  static Color get warmBrown => _active.warmBrown;
  static Color get softBrown => _active.softBrown;
  static Color get champagne => _active.champagne;
  static Color get ivoryCard => _active.ivoryCard;
  static bool get isDark => _active.isDark;

  // Static/Fixed colors (if any are needed)
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;

  // ─── Tracker Colors ──────────────────────────────────────────────────
  static const Color cycleColor = Color(0xFF9B7EC8);
  static const Color userColor = Color(0xFFE8789A);
  static const Color partnerColor = Color(0xFF7ABBE8);
}
