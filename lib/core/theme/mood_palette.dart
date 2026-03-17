import 'package:flutter/material.dart';

class MoodPalette {
  final String name;
  final Color cream;
  final Color roseDust;
  final Color roseDeep;
  final Color warmBrown;
  final Color softBrown;
  final Color champagne;
  final Color ivoryCard;
  final bool isDark;

  const MoodPalette({
    required this.name,
    required this.cream,
    required this.roseDust,
    required this.roseDeep,
    required this.warmBrown,
    required this.softBrown,
    required this.champagne,
    required this.ivoryCard,
    this.isDark = false,
  });

  static const classic = MoodPalette(
    name: 'Classic',
    cream: Color(0xFFFDF6EE),
    roseDust: Color(0xFFE8A598),
    roseDeep: Color(0xFFC4635A),
    warmBrown: Color(0xFF5C3D2E),
    softBrown: Color(0xFF8C6050),
    champagne: Color(0xFFF0DDD0),
    ivoryCard: Color(0xFFFAF0E8),
  );

  static const midnight = MoodPalette(
    name: 'Midnight',
    cream: Color(0xFF1C1210),
    roseDust: Color(0xFFC4756A),
    roseDeep: Color(0xFFD97A70),
    warmBrown: Color(0xFFE8C4B0),
    softBrown: Color(0xFFC49080),
    champagne: Color(0xFF33201C),
    ivoryCard: Color(0xFF261916),
    isDark: true,
  );

  static const forest = MoodPalette(
    name: 'Forest',
    cream: Color(0xFFF2F4F2),
    roseDust: Color(0xFFA8B4A5),
    roseDeep: Color(0xFF4A5D4E),
    warmBrown: Color(0xFF2D362E),
    softBrown: Color(0xFF708271),
    champagne: Color(0xFFE0E6DF),
    ivoryCard: Color(0xFFF8FAF8),
  );

  static const lavender = MoodPalette(
    name: 'Lavender',
    cream: Color(0xFFF8F7FF),
    roseDust: Color(0xFFB1A7CC),
    roseDeep: Color(0xFF7A6B9E),
    warmBrown: Color(0xFF3D364D),
    softBrown: Color(0xFF6B628A),
    champagne: Color(0xFFE8E5F3),
    ivoryCard: Color(0xFFFDFCFE),
  );

  static MoodPalette fromName(String name) {
    switch (name) {
      case 'Midnight':
        return midnight;
      case 'Forest':
        return forest;
      case 'Lavender':
        return lavender;
      case 'Classic':
      default:
        return classic;
    }
  }

  static List<MoodPalette> get all => [classic, midnight, forest, lavender];
}
