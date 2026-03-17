import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moodtrack/features/memories/presentation/pages/memories_screen.dart';
import 'package:moodtrack/features/water_intake/presentation/pages/water_intake_screen.dart';
import 'package:moodtrack/features/notes/presentation/pages/notes_screen.dart';
import 'package:moodtrack/features/settings/presentation/pages/settings_screen.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/core/constants/app_constants.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 40.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warmBrown,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          AppStrings.appSlogan,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontStyle: FontStyle.italic,
                            fontSize: 15.sp,
                            color: AppColors.softBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
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
                        border: Border.all(color: AppColors.champagne),
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                        color: AppColors.warmBrown,
                        size: 24.r,
                      ),
                    ),
                  ),
                ],
              ),
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
                    ),
                    SizedBox(height: 20.h),
                    _buildFeatureCard(
                      context,
                      title: AppStrings.hydrationTitle,
                      subtitle: AppStrings.hydrationSubtitle,
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF6DAA7A), // earth green
                      destination: const WaterIntakeScreen(),
                    ),
                    SizedBox(height: 20.h),
                    _buildFeatureCard(
                      context,
                      title: AppStrings.journalTitle,
                      subtitle: AppStrings.journalSubtitle,
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFFD4A832), // warm gold
                      destination: const NotesScreen(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => destination,
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: AppConstants.defaultTransitionDurationMs),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ivoryCard,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.warmBrown.withValues(alpha: 0.04),
              blurRadius: 20.r,
              offset: Offset(0, 8.h),
            ),
          ],
          border: Border.all(color: AppColors.champagne, width: 1),
        ),
        padding: EdgeInsets.all(24.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Icon(icon, color: color, size: 28.r),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      fontSize: 13.sp,
                      color: AppColors.softBrown.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.roseDeep.withValues(alpha: 0.4),
              size: 22.r,
            ),
          ],
        ),
      ),
    );
  }
}
