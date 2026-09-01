import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/hospital_logo.dart';

/// Top header artwork displaying the Ciputra Hospital logo (and optionally illust_registration.png)
/// seamlessly over the app's standard textured background.
class AuthArtwork extends StatelessWidget {
  const AuthArtwork({
    super.key,
    this.height = 240,
    this.showBackButton = false,
    this.onBackPressed,
    this.showLogo = true,
    this.showIllustration = false,
    this.isLargeLogo = true,
  });

  final double height;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showLogo;
  final bool showIllustration;
  final bool isLargeLogo;

  static const _illustrationPath = 'assets/images/illust_registration.png';

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Central Content (Logo & optional illustration)
          Positioned(
            top: topPadding + 4,
            bottom: 20,
            left: AppSpacing.xxl,
            right: AppSpacing.xxl,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLogo) ...[
                    if (isLargeLogo)
                      const HospitalLogo.splash()
                    else
                      const HospitalLogo.medium(),
                    if (showIllustration) const SizedBox(height: 10),
                  ],
                  if (showIllustration)
                    Flexible(
                      child: Image.asset(
                        _illustrationPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Top Circular Back Button (if enabled)
          if (showBackButton)
            Positioned(
              top: topPadding + 10,
              left: AppSpacing.xl,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: 'Kembali',
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
