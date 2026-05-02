import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:moodtrack/core/services/ui_state_manager.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A wrapper widget that listens to global UI state and shows overlays/snackbars.
class UIStateWrapper extends StatelessWidget {
  final Widget child;

  const UIStateWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<UIStateManager>(
      builder: (context, uiState, _) {
        // Listen for errors and show snackbars
        if (uiState.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  uiState.errorMessage!,
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
                backgroundColor: AppColors.roseDeep,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            );
          });
        }

        return Stack(
          children: [
            child,
            // ── Offline Banner ────────────────────────────────────────
            if (uiState.isOffline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child:
                    Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 8.h,
                          bottom: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC4635A), // Soft warm red
                          boxShadow: [
                            BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              color: Colors.white,
                              size: 16.r,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "No Internet Connection",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().slideY(
                      begin: -1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),

            // ── Loading Overlay ──────────────────────────────────────
            if (uiState.isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child:
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: CircularProgressIndicator(
                          color: AppColors.roseDeep,
                          strokeWidth: 3,
                        ),
                      ).animate().scale(
                        duration: 300.ms,
                        curve: Curves.easeOutBack,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }
}
