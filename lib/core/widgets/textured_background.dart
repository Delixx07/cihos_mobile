import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// White page with the backdrop photo laid over it at 46% opacity, per the
/// Figma frames.
///
/// Renders cleanly whether or not `assets/images/bg_texture.jpg` has been
/// exported yet.
class TexturedBackground extends StatelessWidget {
  const TexturedBackground({super.key, required this.child});

  final Widget child;

  static const _texturePath = 'assets/images/bg_texture.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.46,
              child: Image.asset(
                _texturePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
