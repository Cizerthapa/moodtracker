import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:moodtrack/features/memories/presentation/pages/memories_screen.dart';
import 'package:moodtrack/features/water_intake/presentation/pages/water_intake_screen.dart';
import 'package:moodtrack/features/journal/presentation/pages/journal_screen.dart';
import 'package:moodtrack/features/settings/presentation/pages/settings_screen.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/theme/theme_manager.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/core/constants/app_constants.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) => Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.0.w, vertical: 32.0.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.appName,
                          style: GoogleFonts.outfit(
                            fontSize: 40.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warmBrown,
                            height: 1.1,
                            letterSpacing: -1.2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          AppStrings.appSlogan,
                          style: GoogleFonts.outfit(
                            fontStyle: FontStyle.italic,
                            fontSize: 15.sp,
                            color: AppColors.softBrown,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.ivoryCard,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.champagne,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warmBrown.withValues(alpha: 0.06),
                            blurRadius: 12.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                        color: AppColors.warmBrown,
                        size: 24.r,
                      ),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.2, end: 0, duration: 600.ms),

              SizedBox(height: 48.h),

              // ── Feature Cards ───────────────────────────────────────
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFeatureCard(
                      context,
                      title: AppStrings.ourStoryTitle,
                      subtitle: AppStrings.ourStorySubtitle,
                      icon: Icons.favorite_rounded,
                      color: AppColors.roseDeep,
                      destination: const MemoriesScreen(),
                      index: 0,
                    ),
                    SizedBox(height: 20.h),
                    _buildFeatureCard(
                      context,
                      title: AppStrings.hydrationTitle,
                      subtitle: AppStrings.hydrationSubtitle,
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF6DAA7A),
                      destination: const WaterIntakeScreen(),
                      index: 1,
                    ),
                    SizedBox(height: 20.h),
                    _buildFeatureCard(
                      context,
                      title: AppStrings.journalTitle,
                      subtitle: AppStrings.journalSubtitle,
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFFD4A832),
                      destination: const JournalScreen(),
                      index: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => destination,
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(
                milliseconds: AppConstants.defaultTransitionDurationMs),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.ivoryCard,
              color.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 24.r,
              offset: Offset(0, 8.h),
            ),
            BoxShadow(
              color: AppColors.warmBrown.withValues(alpha: 0.03),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(24.r),
        child: Row(
          children: [
            // ── Icon Container with gradient ──────────────────────
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 28.r),
            ),
            SizedBox(width: 20.w),

            // ── Text ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontStyle: FontStyle.italic,
                      fontSize: 13.sp,
                      color: AppColors.softBrown.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            // ── Arrow ────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: color.withValues(alpha: 0.6),
                size: 18.r,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 200 + (index * 150)),
          duration: 500.ms,
        )
        .slideX(
          begin: 0.15,
          end: 0,
          delay: Duration(milliseconds: 200 + (index * 150)),
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
