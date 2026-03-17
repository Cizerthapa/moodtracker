import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor

  // ─── Palette (Cream & Rose) ────────────────────────────────────────────────
  static const cream = Color(0xFFFDF6EE);
  static const roseDust = Color(0xFFE8A598);
  static const roseDeep = Color(0xFFC4635A);
  static const warmBrown = Color(0xFF5C3D2E);
  static const softBrown = Color(0xFF8C6050);
  static const champagne = Color(0xFFF0DDD0);
  static const ivoryCard = Color(0xFFFAF0E8);

  // Dark theme
  static const darkBg = Color(0xFF1C1210); // replaces _cream — deep warm black
  static const darkCard = Color(0xFF261916); // replaces _ivoryCard — dark card surface
  static const darkSurface = Color(0xFF33201C); // replaces _champagne — elevated surface

  static const roseDustDark = Color(0xFFC4756A); // roseDust shifted warmer, slightly darker
  static const roseDeepDark = Color(0xFFD97A70); // roseDeep lightened for legibility on dark bg

  static const softBrownDark = Color(0xFFC49080); // softBrown lightened to work as text/icon
  static const warmBrownDark = Color(0xFFE8C4B0); // warmBrown inverted to near-champagne for headings
}
