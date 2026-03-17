import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/core/theme/mood_palette.dart';

class AppTheme {
  static ThemeData getTheme(MoodPalette palette) {
    final baseTextTheme = GoogleFonts.outfitTextTheme();

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
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 40.sp,
          fontWeight: FontWeight.w800,
          color: palette.warmBrown,
          letterSpacing: -1.2,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 34.sp,
          fontWeight: FontWeight.w700,
          color: palette.warmBrown,
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24.sp,
          fontWeight: FontWeight.w700,
          color: palette.warmBrown,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: palette.warmBrown,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: palette.warmBrown,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16.sp,
          color: palette.softBrown,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14.sp,
          color: palette.softBrown,
        ),
        bodySmall: GoogleFonts.outfit(
          fontSize: 12.sp,
          color: palette.softBrown,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: palette.warmBrown),
        titleTextStyle: GoogleFonts.outfit(
          color: palette.warmBrown,
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.roseDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.ivoryCard,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: palette.champagne),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: palette.champagne),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: palette.roseDeep, width: 1.5),
        ),
        labelStyle: GoogleFonts.outfit(color: palette.softBrown),
        hintStyle: GoogleFonts.outfit(
          color: palette.softBrown.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme => getTheme(MoodPalette.midnight);
}
