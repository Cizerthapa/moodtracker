import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/features/entry/presentation/pages/entry_screen.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();

    Timer(const Duration(seconds: AppConstants.splashDelaySeconds), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const EntryScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(
              milliseconds: AppConstants.fadeTransitionDurationMs,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Animated Icon ──────────────────────────────────────
            Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.roseDeep.withValues(alpha: 0.15),
                        AppColors.roseDust.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.roseDeep.withValues(alpha: 0.15),
                        blurRadius: 40.r,
                        spreadRadius: 5.r,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: AppColors.roseDeep,
                    size: 64.r,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 600.ms),

            SizedBox(height: 32.h),

            // ── Welcome Text ────────────────────────────────────────
            Text(
                  AppLocalizations.of(context)!.welcomeBack,
                  style: GoogleFonts.outfit(
                    fontStyle: FontStyle.italic,
                    fontSize: 20.sp,
                    color: AppColors.softBrown,
                    fontWeight: FontWeight.w400,
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 600.ms),

            SizedBox(height: 8.h),

            // ── Name ──────────────────────────────────────────────
            Text(
                  AppLocalizations.of(context)!.userName,
                  style: GoogleFonts.outfit(
                    fontSize: 38.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warmBrown,
                    letterSpacing: -0.5,
                  ),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0, delay: 500.ms, duration: 600.ms),

            SizedBox(height: 20.h),

            // ── Subtitle ────────────────────────────────────────────
            Text(
                  AppLocalizations.of(context)!.trackMoodToday,
                  style: GoogleFonts.outfit(
                    fontStyle: FontStyle.italic,
                    fontSize: 14.sp,
                    color: AppColors.softBrown.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w300,
                  ),
                )
                .animate()
                .fadeIn(delay: 700.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0, delay: 700.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
