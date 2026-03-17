import 'package:flutter/material.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
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
              padding: const EdgeInsets.fromLTRB(28, 24, 24, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.ivoryCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.champagne),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.warmBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    AppStrings.settingsTitle,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 34,
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
                color: AppColors.roseDust.withOpacity(0.3),
                thickness: 1,
              ),
            ),

            // ── Content ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(28),
                children: [
                  _buildSettingTile(
                    title: AppStrings.enableNotifications,
                    subtitle: AppStrings.notificationsSubtitle,
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      activeColor: AppColors.roseDeep,
                      onChanged: _toggleNotifications,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSettingTile(
                    title: AppStrings.testNotification,
                    subtitle: AppStrings.testNotificationSubtitle,
                    trailing: const Icon(
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
                  const SizedBox(height: 20),
                  _buildSettingTile(
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    trailing: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.roseDeep,
                    ),
                    onTap: () async {
                      await AuthRepository().signOut();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out successfully')),
                        );
                        // Navigation is handled by AuthWrapper
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                children: [
                  Text(
                    AppStrings.madeWithLoveBy,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      color: AppColors.softBrown.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppStrings.authorName,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                      fontSize: 18,
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

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.ivoryCard,
          borderRadius: BorderRadius.circular(20),
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
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 12,
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
