import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The seated-person-with-laptop artwork on the registration screens, sized
/// 270x278 in the design.
///
/// The Figma frame references the "login-leady" Lottie animation. This renders
/// a static export for now; swap in `Lottie.asset` once the .json is added and
/// the `lottie` package is a dependency.
class RegistrationIllustration extends StatelessWidget {
  const RegistrationIllustration({super.key, this.width = 270});

  final double width;

  /// Width over height, from the 270x278 frame in the design.
  static const aspectRatio = 270 / 278;

  static const _illustrationPath = 'assets/images/artwork/illust_registration.png';

  @override
  Widget build(BuildContext context) {
    final height = width / aspectRatio;

    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        _illustrationPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(
            Icons.image_outlined,
            size: height * 0.28,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
