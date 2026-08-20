import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_back_button.dart';

/// The back arrow and title row that opens every pushed screen.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.fallback,
    this.trailing,
  });

  final String title;

  /// Where back goes when there is nothing to pop.
  final String? fallback;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (fallback == null)
            const AppBackButton()
          else
            AppBackButton(fallback: fallback!),
          Expanded(
            child: Text(
              title,
              style: AppTypography.headingMd.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ?trailing,
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
