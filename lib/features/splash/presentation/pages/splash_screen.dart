import 'dart:developer';
import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodtrack/core/navigation/app_routes.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/features/settings/data/repositories/settings_repository.dart';
import 'package:moodtrack/features/auth/data/repositories/user_repository.dart';
import 'package:moodtrack/core/di/service_locator.dart';
import 'package:moodtrack/core/error/result.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();
  final SettingsRepository _repository = sl<SettingsRepository>();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAuthenticating = false;
  final List<String> _cuteMessages = [
    "you look beautiful today 💕",
    "I'm so lucky to have you ✨",
    "my favorite person in the world 🌸",
    "can't stop thinking about you 🦋",
    "you make my heart smile 😊",
    "you're my safe place 🏡",
    "I love you more than words ❤️",
    "I love you more today than yesterday. 💕",
    "You make every day brighter. ☀️",
    "Every memory with you is a treasure. 💎",
    "You are my favorite notification. 📱",
    "Smile, you are beautiful! 😊",
  ];
  late String _randomMessage;

  @override
  void initState() {
    super.initState();
    _randomMessage = _cuteMessages[Random().nextInt(_cuteMessages.length)];
    _setupAnimation();
    _startAppFlow();
  }

  void _setupAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startAppFlow() async {
    // 1. Mandatory Delay for visual Splash Screen effect
    await Future.delayed(const Duration(seconds: 2));

    // 2. Version Check
    await _checkVersion();

    if (!mounted) return;

    // 3. Check Biometric Requirement
    final bioResult = await _repository.getBiometricEnabled();
    bool isEnabled = false;
    if (bioResult is Success<bool>) {
      isEnabled = bioResult.data;
    }

    if (isEnabled) {
      bool canCheck = await _auth.canCheckBiometrics;
      bool isSupported = await _auth.isDeviceSupported();

      if (canCheck && isSupported) {
        await _authenticate();
      } else {
        _navigateToHome();
      }
    } else {
      _navigateToHome();
    }
  }

  Future<void> _authenticate() async {
    setState(() => _isAuthenticating = true);
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Unlock your memories 💙',
      );

      if (authenticated) {
        _navigateToHome();
      } else {
        setState(() => _isAuthenticating = false);
        // Authentication failed or cancelled - retry trigger placeholder
      }
    } on PlatformException catch (e) {
      log("Biometric Error: $e");
      setState(() => _isAuthenticating = false);
      // Fallback or Alert user if permanent failure
    }
  }

  Future<void> _checkVersion() async {
    try {
      final configSnap = await sl<FirebaseFirestore>()
          .collection('system_config')
          .doc('app_version')
          .get();

      if (!configSnap.exists) return;

      final data = configSnap.data() as Map<String, dynamic>;
      final minVersion = data['minVersion'] as String;
      final latestVersion = data['latestVersion'] as String;
      final message = data['updateMessage'] as String;
      final forceUpdate = data['forceUpdate'] as bool;

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      if (_isVersionOlder(currentVersion, minVersion)) {
        await _showUpdateDialog(message, forceUpdate);
      } else if (_isVersionOlder(currentVersion, latestVersion)) {
        await _showUpdateDialog(message, false);
      }
    } catch (e) {
      log("Version Check Error: $e");
    }
  }

  bool _isVersionOlder(String current, String target) {
    try {
      List<int> c = current.split('+')[0].split('.').map(int.parse).toList();
      List<int> t = target.split('+')[0].split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        if (c[i] < t[i]) return true;
        if (c[i] > t[i]) return false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _showUpdateDialog(String message, bool force) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: AppColors.cream,
        title: Text(
          force ? 'Update Required' : 'New Version Available',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(),
        ),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Later', style: GoogleFonts.outfit(color: AppColors.softBrown)),
            ),
          TextButton(
            onPressed: () {
              // Usually link to App Store / Play Store
              // For now just Pop if not forced
              if (!force) Navigator.pop(context);
            },
            child: Text(
              'Update Now',
              style: GoogleFonts.outfit(color: AppColors.roseDeep, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final repo = sl<UserRepository>();
      repo.updateLastSeen();
      repo.refreshFcmToken(user.uid);
      context.goNamed(AppRoutes.home);
    } else {
      context.goNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Background soft gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.champagne.withValues(alpha: 0.3),
                    AppColors.cream,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: EdgeInsets.all(22.r),
                    decoration: BoxDecoration(
                      color: AppColors.roseDust.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.roseDust.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 64.sp,
                      color: AppColors.roseDeep,
                    ),
                  ),
                ),
                28.verticalSpace,
                Text(
                  "Welcome baby,",
                  style: GoogleFonts.outfit(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warmBrown,
                    letterSpacing: -0.5,
                  ),
                ),
                8.verticalSpace,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Text(
                    _randomMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.softBrown,
                      height: 1.4,
                    ),
                  ),
                ),

                if (!_isAuthenticating) ...[
                  40.verticalSpace,
                  GestureDetector(
                    onTap: _authenticate,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.roseDeep,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.roseDeep.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_open_rounded,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                          8.horizontalSpace,
                          Text(
                            "Tap to Unlock",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  48.verticalSpace,
                  SizedBox(
                    width: 24.r,
                    height: 24.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.roseDeep,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Aves World",
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: AppColors.softBrown.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
