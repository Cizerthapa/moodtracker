import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    await _repository.setNotificationsEnabled(value);
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      await _notificationService.scheduleDailyNotifications();
      await _notificationService.startPeriodicNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.notificationsOn),
          ),
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
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.ivoryCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.champagne),
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
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 34.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Divider(
                color: AppColors.roseDust.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),

            // ── Content ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(28.r),
                children: [
                  // ── Theme Selection ──────────────────────────────
                  Text(
                    'Application Theme',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildThemeSelector(),
                  SizedBox(height: 32.h),

                  Text(
                    'Preferences',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildSettingTile(
                    title: AppStrings.enableNotifications,
                    subtitle: AppStrings.notificationsSubtitle,
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                    activeTrackColor: AppColors.roseDeep,
                    onChanged: _toggleNotifications,
                  ),
                  ),
                  SizedBox(height: 20.h),
                  _buildSettingTile(
                    title: AppStrings.testNotification,
                    subtitle: AppStrings.testNotificationSubtitle,
                    trailing: Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.roseDeep,
                    ),
                    onTap: () async {
                      await _notificationService.showInstantNotification(
                        AppStrings.testNotificationTitle,
                        AppStrings.testNotificationBody,
                      );
                    },
                  ),
                  SizedBox(height: 20.h),
                  _buildSettingTile(
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    trailing: Icon(
                      Icons.logout_rounded,
                      color: AppColors.roseDeep,
                    ),
                    onTap: () async {
                      await AuthRepository().signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out successfully')),
                        );
                      }
                    },
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
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      color: AppColors.softBrown.withValues(alpha: 0.6),
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AppStrings.authorName,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                      fontSize: 18.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return SizedBox(
          height: 100.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MoodPalette.all.length,
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              final palette = MoodPalette.all[index];
              final isSelected = themeManager.palette.name == palette.name;

              return GestureDetector(
                onTap: () => themeManager.setTheme(palette),
                child: Column(
                  children: [
                    Container(
                      width: 64.r,
                      height: 64.r,
                      decoration: BoxDecoration(
                        color: palette.cream,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? palette.roseDeep : AppColors.champagne,
                          width: isSelected ? 3.r : 1.r,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: palette.roseDeep.withValues(alpha: 0.3),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Container(
                          width: 32.r,
                          height: 32.r,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [palette.roseDeep, palette.roseDust],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      palette.name,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.roseDeep : AppColors.softBrown,
                      ),
                    ),
                  ],
                ),
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
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.ivoryCard,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.champagne),
        ),
        child: Row(
          children: [
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
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 12.sp,
                      color: AppColors.softBrown,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
