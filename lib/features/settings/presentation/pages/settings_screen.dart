import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/theme/mood_palette.dart';
import 'package:moodtrack/core/theme/theme_manager.dart';
import 'package:moodtrack/core/services/notification_service.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/features/settings/data/repositories/settings_repository.dart';
import 'package:moodtrack/features/auth/data/repositories/auth_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepository _repository = SettingsRepository();
  bool _notificationsEnabled = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _repository.getNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    HapticFeedback.selectionClick();
    await _repository.setNotificationsEnabled(value);
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      await _notificationService.scheduleDailyNotifications();
      await _notificationService.startPeriodicNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.notificationsOn)),
        );
      }
    } else {
      await _notificationService.cancelAll();
      await _notificationService.stopPeriodicNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.notificationsOff)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(28.w, 24.h, 24.w, 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.ivoryCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.champagne),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.warmBrown.withValues(alpha: 0.06),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18.sp,
                        color: AppColors.warmBrown,
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Text(
                    AppStrings.settingsTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warmBrown,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.15, end: 0, duration: 400.ms),

            // ── Divider ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: Divider(
                color: AppColors.roseDust.withValues(alpha: 0.25),
                thickness: 1,
              ),
            ),

            // ── Content ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(28.r),
                children: [
                  // ── Theme Section ──────────────────────────────
                  Text(
                    'Application Theme',
                    style: GoogleFonts.outfit(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warmBrown,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  SizedBox(height: 16.h),
                  _buildThemeSelector(),
                  SizedBox(height: 36.h),

                  // ── Preferences Section ────────────────────────
                  Text(
                    'Preferences',
                    style: GoogleFonts.outfit(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warmBrown,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  SizedBox(height: 16.h),
                  _buildSettingTile(
                    title: AppStrings.enableNotifications,
                    subtitle: AppStrings.notificationsSubtitle,
                    icon: Icons.notifications_rounded,
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      activeTrackColor: AppColors.roseDeep,
                      onChanged: _toggleNotifications,
                    ),
                    index: 0,
                  ),
                  SizedBox(height: 14.h),
                  _buildSettingTile(
                    title: AppStrings.testNotification,
                    subtitle: AppStrings.testNotificationSubtitle,
                    icon: Icons.notifications_active_rounded,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.roseDust,
                      size: 22.r,
                    ),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await _notificationService.showInstantNotification(
                        AppStrings.testNotificationTitle,
                        AppStrings.testNotificationBody,
                      );
                    },
                    index: 1,
                  ),
                  SizedBox(height: 14.h),
                  _buildSettingTile(
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    icon: Icons.logout_rounded,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.roseDust,
                      size: 22.r,
                    ),
                    onTap: () async {
                      HapticFeedback.heavyImpact();
                      await AuthRepository().signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Logged out successfully')),
                        );
                      }
                    },
                    index: 2,
                  ),
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(bottom: 32.0.h),
              child: Column(
                children: [
                  Text(
                    AppStrings.madeWithLoveBy,
                    style: GoogleFonts.outfit(
                      fontStyle: FontStyle.italic,
                      color: AppColors.softBrown.withValues(alpha: 0.5),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AppStrings.authorName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: AppColors.warmBrown,
                      fontSize: 18.sp,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return SizedBox(
          height: 110.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MoodPalette.all.length,
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              final palette = MoodPalette.all[index];
              final isSelected = themeManager.palette.name == palette.name;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  themeManager.setTheme(palette);
                },
                child: AnimatedContainer(
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: 300.ms,
                        width: 66.r,
                        height: 66.r,
                        decoration: BoxDecoration(
                          color: palette.cream,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? palette.roseDeep
                                : AppColors.champagne,
                            width: isSelected ? 3.r : 1.r,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: palette.roseDeep
                                        .withValues(alpha: 0.35),
                                    blurRadius: 16.r,
                                    offset: Offset(0, 6.h),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: AppColors.warmBrown
                                        .withValues(alpha: 0.04),
                                    blurRadius: 4.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Container(
                            width: 34.r,
                            height: 34.r,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  palette.roseDeep,
                                  palette.roseDust,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? Icon(Icons.check_rounded,
                                    color: Colors.white, size: 18.r)
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        palette.name,
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.roseDeep
                              : AppColors.softBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 150 + (index * 100)),
                    duration: 400.ms,
                  )
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    delay: Duration(milliseconds: 150 + (index * 100)),
                    duration: 400.ms,
                  );
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    VoidCallback? onTap,
    required int index,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.ivoryCard,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.champagne),
          boxShadow: [
            BoxShadow(
              color: AppColors.warmBrown.withValues(alpha: 0.04),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.roseDeep.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: AppColors.roseDeep,
                size: 22.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      color: AppColors.softBrown.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 300 + (index * 120)),
          duration: 400.ms,
        )
        .slideX(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: 300 + (index * 120)),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
