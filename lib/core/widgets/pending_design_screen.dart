import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_bottom_nav.dart';
import 'textured_background.dart';

/// Placeholder for a tab whose Figma frame has not been handed over yet.
class PendingDesignScreen extends StatelessWidget {
  const PendingDesignScreen({
    super.key,
    required this.title,
    required this.tab,
    required this.icon,
  });

  final String title;
  final AppTab tab;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppBottomNav(current: tab),
      body: TexturedBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: AppTypography.headingLg.copyWith(
                    color: AppColors.accentSoft,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Menunggu desain dari Figma.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
