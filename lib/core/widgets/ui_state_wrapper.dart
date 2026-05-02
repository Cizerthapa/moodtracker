import 'package:flutter/material.dart';
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
            if (uiState.isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: CircularProgressIndicator(
                      color: AppColors.roseDeep,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
