import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/theme/mood_palette.dart';
import 'package:moodtrack/core/theme/theme_manager.dart';
import 'package:moodtrack/core/services/notification_service.dart';
import 'package:moodtrack/features/settings/data/repositories/settings_repository.dart';
import 'package:moodtrack/features/auth/data/repositories/auth_repository.dart';
import 'package:moodtrack/features/journal/data/repositories/journal_repository.dart';
import 'package:moodtrack/core/managers/locale_manager.dart';
import 'package:moodtrack/features/auth/presentation/pages/login_screen.dart';
import 'package:moodtrack/features/auth/data/repositories/user_repository.dart';
import 'package:moodtrack/features/memories/presentation/pages/together_since_screen.dart';
import 'package:moodtrack/features/admin/presentation/pages/admin_panel_screen.dart';
import 'package:moodtrack/features/admin/data/repositories/admin_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepository _repository = SettingsRepository();
  final JournalRepository _journalRepository = JournalRepository();
  bool _notificationsEnabled = false;
  bool _journalEncryptionEnabled = false;
  bool _biometricEnabled = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _repository.getNotificationsEnabled();
    final encEnabled = await _journalRepository.getEncryptionEnabled();
    final bioEnabled = await _repository.getBiometricEnabled();
    setState(() {
      _notificationsEnabled = enabled;
      _journalEncryptionEnabled = encEnabled;
      _biometricEnabled = bioEnabled;
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.notificationsOn),
          ),
        );
      }
    } else {
      await _notificationService.cancelAll();
      await _notificationService.stopPeriodicNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.notificationsOff),
          ),
        );
      }
    }
  }

  void _showLinkPartnerDialog() {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.ivoryCard,
        title: Text(
          "Link Partner",
          style: GoogleFonts.outfit(
            color: AppColors.warmBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: "Partner's Email",
            filled: true,
            fillColor: AppColors.cream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.champagne),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: AppColors.softBrown)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                final success = await UserRepository().linkPartnerByEmail(
                  email,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? "Linked successfully!"
                            : "Failed to link. Check email.",
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roseDeep,
            ),
            child: const Text("Link", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                                color: AppColors.warmBrown.withValues(
                                  alpha: 0.06,
                                ),
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
                        AppLocalizations.of(context)!.settingsTitle,
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
                    title: AppLocalizations.of(context)!.enableNotifications,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.notificationsSubtitle,
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
                    title: AppLocalizations.of(context)!.testNotification,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.testNotificationSubtitle,
                    icon: Icons.notifications_active_rounded,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.roseDust,
                      size: 22.r,
                    ),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await _notificationService.showInstantNotification(
                        AppLocalizations.of(context)!.testNotificationTitle,
                        AppLocalizations.of(context)!.testNotificationBody,
                      );
                    },
                    index: 1,
                  ),
                  SizedBox(height: 14.h),
                  _buildSettingTile(
                    title: 'Language',
                    subtitle: 'Choose your preferred language',
                    icon: Icons.language_rounded,
                    trailing: Consumer<LocaleManager>(
                      builder: (context, localeManager, _) {
                        return DropdownButton<String>(
                          value: localeManager.locale.languageCode,
                          underline: const SizedBox(),
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.roseDust,
                          ),
                          dropdownColor: AppColors.ivoryCard,
                          style: GoogleFonts.outfit(
                            color: AppColors.roseDeep,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              HapticFeedback.selectionClick();
                              localeManager.setLocale(Locale(newValue));
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'ne',
                              child: Text('नेपाली'),
                            ),
                            DropdownMenuItem(value: 'zh', child: Text('中文')),
                            DropdownMenuItem(value: 'ja', child: Text('日本語')),
                          ],
                        );
                      },
                    ),
                    index: 2,
                  ),
                  SizedBox(height: 14.h),
                  _buildSettingTile(
                    title: 'Encrypt Journal',
                    subtitle: 'AES-256 encrypt your journal entries',
                    icon: Icons.lock_rounded,
                    trailing: Switch.adaptive(
                      value: _journalEncryptionEnabled,
                      activeTrackColor: AppColors.roseDeep,
                      onChanged: (value) async {
                        HapticFeedback.selectionClick();
                        // Show migration progress dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.ivoryCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: AppColors.roseDeep,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  value
                                      ? 'Encrypting entries...'
                                      : 'Decrypting entries...',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.warmBrown,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        try {
                          await _journalRepository.migrateEncryption(value);
                          await _journalRepository.setEncryptionEnabled(value);
                          if (mounted) {
                            setState(() => _journalEncryptionEnabled = value);
                          }
                        } finally {
                          if (mounted) Navigator.of(context).pop();
                        }
                      },
                    ),
                    index: 3,
                  ),
                  SizedBox(height: 14.h),
                  _buildSettingTile(
                    title: 'Biometric Lock',
                    subtitle: 'Secure your app with Fingerprint/FaceID',
                    icon: Icons.fingerprint_rounded,
                    trailing: Switch.adaptive(
                      value: _biometricEnabled,
                      activeTrackColor: AppColors.roseDeep,
                      onChanged: (value) async {
                        HapticFeedback.selectionClick();
                        await _repository.setBiometricEnabled(value);
                        setState(() => _biometricEnabled = value);
                      },
                    ),
                    index: 4,
                  ),
                  SizedBox(height: 14.h),
                  // ── Couple Section ────────────────────────
                  Text(
                    'Couple',
                    style: GoogleFonts.outfit(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warmBrown,
                    ),
                  ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                  SizedBox(height: 16.h),
                  _buildSettingTile(
                    title: 'Link Partner',
                    subtitle: 'Link accounts via email',
                    icon: Icons.link_rounded,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.roseDust,
                      size: 22.r,
                    ),
                    onTap: () {
                      _showLinkPartnerDialog();
                    },
                    index: 4,
                  ),
                  SizedBox(height: 14.h),
                  _buildSettingTile(
                    title: 'Together Timeline',
                    subtitle: 'See how long you have been together',
                    icon: Icons.timer_rounded,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.roseDust,
                      size: 22.r,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TogetherSinceScreen(),
                        ),
                      );
                    },
                    index: 5,
                  ),
                  SizedBox(height: 24.h),

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
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    index: 2,
                  ),
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────────────
            _AdminFooter().animate().fadeIn(delay: 600.ms, duration: 500.ms),
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
                                        color: palette.roseDeep.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 16.r,
                                        offset: Offset(0, 6.h),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: AppColors.warmBrown.withValues(
                                          alpha: 0.04,
                                        ),
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
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 18.r,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            palette.name,
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
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
                  child: Icon(icon, color: AppColors.roseDeep, size: 22.r),
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

// ── Admin Footer (Easter Egg) ─────────────────────────────────────────────────

class _AdminFooter extends StatefulWidget {
  const _AdminFooter();

  @override
  State<_AdminFooter> createState() => _AdminFooterState();
}

class _AdminFooterState extends State<_AdminFooter>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onHoldComplete();
        }
      });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _onHoldComplete() {
    HapticFeedback.heavyImpact();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == AdminRepository.adminEmail) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const AdminPanelScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔒 Not authorized.',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: const Color(0xFF21262D),
        ),
      );
    }
    _progressController.reset();
    setState(() => _isHolding = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() => _isHolding = true);
        HapticFeedback.lightImpact();
        _progressController.forward(from: 0);
      },
      onLongPressEnd: (_) {
        if (_progressController.status != AnimationStatus.completed) {
          _progressController.reset();
          setState(() => _isHolding = false);
        }
      },
      onLongPressCancel: () {
        _progressController.reset();
        setState(() => _isHolding = false);
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 32.h),
        child: Column(
          children: [
            // Progress ring — only visible while holding
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return AnimatedOpacity(
                  opacity: _isHolding ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: SizedBox(
                      width: 28.r,
                      height: 28.r,
                      child: CircularProgressIndicator(
                        value: _progressController.value,
                        strokeWidth: 2.5,
                        backgroundColor: AppColors.champagne,
                        color: AppColors.roseDeep,
                      ),
                    ),
                  ),
                );
              },
            ),
            Text(
              AppLocalizations.of(context)!.madeWithLoveBy,
              style: GoogleFonts.outfit(
                fontStyle: FontStyle.italic,
                color: AppColors.softBrown.withValues(alpha: 0.5),
                fontSize: 13.sp,
                fontWeight: FontWeight.w300,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              AppLocalizations.of(context)!.authorName,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: AppColors.warmBrown,
                fontSize: 18.sp,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
