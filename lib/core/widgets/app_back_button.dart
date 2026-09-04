import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';

/// Uniform back button used across the app with [Icons.arrow_back_ios_new].
///
/// Falls back to a route when there is nothing to pop — reaching a screen
/// through a replacement leaves an empty stack, and a dead back button is
/// worse than one that lands somewhere sensible. Signed-in screens fall back
/// to home; the auth screens pass [AppRoutes.login] or the onboarding route
/// instead.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.fallback = AppRoutes.home,
    this.color,
    this.backgroundColor,
    this.onPressed,
  });

  final String fallback;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary;
    final isWhite = effectiveColor == Colors.white || effectiveColor == AppColors.white;

    return IconButton(
      tooltip: 'Kembali',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: onPressed ??
          () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(fallback);
            }
          },
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isWhite
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.05)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          color: effectiveColor,
          size: 16,
        ),
      ),
    );
  }
}
