import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_constants.dart';
import '../error/app_exception.dart';
import '../error/failure.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The three universal async-UI states — loading, empty and error — as small,
/// composable widgets. Every screen funnels its non-happy paths through these so
/// the app never shows a raw spinner-less blank or an unhandled exception.

/// Centered, minimal loading indicator.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.spaceMd),
            Text(message!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

/// Empty-state placeholder with an icon, title and optional subtitle/action.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textTertiary),
            const SizedBox(height: AppConstants.spaceMd),
            Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppConstants.spaceSm),
              Text(subtitle!, style: AppTextStyles.body, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppConstants.spaceLg),
              action!,
            ],
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

/// Error-state placeholder. Distinguishes the offline case (different icon +
/// copy) and always offers a retry affordance when [onRetry] is provided.
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = failure.kind == AppErrorKind.network;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 44,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppConstants.spaceMd),
            Text(
              offline ? "You're offline" : 'Something went wrong',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spaceSm),
            Text(failure.message, style: AppTextStyles.body, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppConstants.spaceLg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}
