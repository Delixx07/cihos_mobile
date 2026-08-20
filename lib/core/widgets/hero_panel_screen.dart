import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_back_button.dart';
import 'textured_background.dart';
import '../theme/app_elevation.dart';
import './image_placeholder.dart';

/// A photo across the top with a dark rounded panel over its lower edge —
/// the layout shared by the emergency and queue-check screens.
class HeroPanelScreen extends StatelessWidget {
  const HeroPanelScreen({
    super.key,
    required this.heroAsset,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String heroAsset;
  final String title;
  final String subtitle;

  /// Content inside the dark panel, below the subtitle.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TexturedBackground(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 120),
                SizedBox(
                  height: 420,
                  width: double.infinity,
                  child: Image.asset(
                    heroAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ImagePlaceholder(iconSize: 40),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(13),
                  ),
                  boxShadow: AppElevation.level4,
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xxxl,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTypography.headingLg.copyWith(
                          fontSize: 32,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyStrong.copyWith(
                          fontSize: 14,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: AppBackButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A wide light button used inside [HeroPanelScreen], with a chevron on the
/// right.
class HeroPanelAction extends StatelessWidget {
  const HeroPanelAction({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(-1, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 196,
              height: 45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.lg),
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headingLg.copyWith(fontSize: 24),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 26,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
