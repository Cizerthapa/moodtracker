import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

// ─── Palette (Cream & Rose) ────────────────────────────────────────────────
const _cream = Color(0xFFFDF6EE);
const _roseDust = Color(0xFFE8A598);
const _roseDeep = Color(0xFFC4635A);
const _warmBrown = Color(0xFF5C3D2E);
const _softBrown = Color(0xFF8C6050);
const _champagne = Color(0xFFF0DDD0);
const _ivoryCard = Color(0xFFFAF0E8);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = value;
    });
    await prefs.setBool('notifications_enabled', value);

    if (value) {
      await _notificationService.scheduleDailyNotifications();
      _notificationService.startPeriodicNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications turned on! (30s interval for 15m)')),
      );
    } else {
      await _notificationService.cancelAll();
      _notificationService.stopPeriodicNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications turned off.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
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
                        color: _ivoryCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: _champagne),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _warmBrown),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: _warmBrown,
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Divider(color: _roseDust.withOpacity(0.3), thickness: 1),
            ),

            // ── Content ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(28),
                children: [
                  _buildSettingTile(
                    title: 'Enable Notifications',
                    subtitle: 'Daily morning, night & periodic alerts',
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      activeColor: _roseDeep,
                      onChanged: _toggleNotifications,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSettingTile(
                    title: 'Test Notification',
                    subtitle: 'Send an instant notification',
                    trailing: Icon(Icons.notifications_active_rounded, color: _roseDeep),
                    onTap: () async {
                      await _notificationService.showInstantNotification(
                        'Test Success! 🎉',
                        'This is a notification from MoodTrack.',
                      );
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
                    'made with love by',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      color: _softBrown.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cizer Thapa',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.bold,
                      color: _warmBrown,
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
          color: _ivoryCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _champagne),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _warmBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 12,
                      color: _softBrown,
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
