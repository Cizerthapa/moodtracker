import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/features/auth/data/repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _authRepository.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await _authRepository.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32.0.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60.h),

              // ── Heart Icon ────────────────────────────────────────
              Container(
                width: 90.r,
                height: 90.r,
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
                      color: AppColors.roseDeep.withValues(alpha: 0.12),
                      blurRadius: 30.r,
                      spreadRadius: 4.r,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 44.r,
                  color: AppColors.roseDeep,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),

              SizedBox(height: 28.h),

              // ── Title ─────────────────────────────────────────────
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warmBrown,
                  letterSpacing: -0.8,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 500.ms),

              SizedBox(height: 8.h),

              // ── Subtitle ──────────────────────────────────────────
              Text(
                _isLogin
                    ? 'Login to track your moods'
                    : 'Join us to start your journey',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontStyle: FontStyle.italic,
                  fontSize: 15.sp,
                  color: AppColors.softBrown.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w300,
                ),
              )
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, delay: 350.ms, duration: 500.ms),

              SizedBox(height: 48.h),

              // ── Email Field ───────────────────────────────────────
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: AppColors.roseDust, size: 20.r),
                ),
                keyboardType: TextInputType.emailAddress,
              )
                  .animate()
                  .fadeIn(delay: 450.ms, duration: 400.ms)
                  .slideX(
                      begin: 0.1,
                      end: 0,
                      delay: 450.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic),

              SizedBox(height: 16.h),

              // ── Password Field ────────────────────────────────────
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded,
                      color: AppColors.roseDust, size: 20.r),
                ),
                obscureText: true,
              )
                  .animate()
                  .fadeIn(delay: 550.ms, duration: 400.ms)
                  .slideX(
                      begin: 0.1,
                      end: 0,
                      delay: 550.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic),

              SizedBox(height: 36.h),

              // ── Submit Button ─────────────────────────────────────
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.roseDeep,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 22.r,
                        width: 22.r,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _isLogin ? 'Login' : 'Sign Up',
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              )
                  .animate()
                  .fadeIn(delay: 650.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, delay: 650.ms, duration: 400.ms),

              SizedBox(height: 16.h),

              // ── Toggle Login/Signup ──────────────────────────────
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text(
                  _isLogin
                      ? "Don't have an account? Sign Up"
                      : "Already have an account? Login",
                  style: GoogleFonts.outfit(
                    color: AppColors.roseDeep,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 750.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
