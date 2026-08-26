import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';

/// Back control used across the app.
///
/// Falls back to a route when there is nothing to pop — reaching a screen
/// through a replacement leaves an empty stack, and a dead back button is
/// worse than one that lands somewhere sensible. Signed-in screens fall back
/// to home; the auth screens pass [AppRoutes.login] or the onboarding route
/// instead.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.fallback = AppRoutes.home, this.color});

  final String fallback;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Kembali',
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallback);
        }
      },
      icon: const Icon(Icons.arrow_back),
      color: color ?? AppColors.textPrimary,
    );
  }
}
