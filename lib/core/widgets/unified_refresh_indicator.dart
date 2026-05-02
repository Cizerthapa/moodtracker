import 'package:flutter/material.dart';
import 'package:moodtrack/core/di/service_locator.dart';
import 'package:moodtrack/core/services/ui_state_manager.dart';
import 'package:moodtrack/core/theme/app_colors.dart';

/// A standardized RefreshIndicator that integrates with UIStateManager.
class UnifiedRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const UnifiedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.roseDeep,
      backgroundColor: Colors.white,
      displacement: 40,
      strokeWidth: 3,
      onRefresh: () async {
        // Use runTask but without the global loading overlay 
        // since RefreshIndicator has its own loading UI.
        await sl<UIStateManager>().runTask(
          onRefresh,
          showLoading: false,
        );
      },
      child: child,
    );
  }
}
