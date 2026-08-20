import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Stands in for artwork that has not been exported yet.
///
/// Several promo and article images are still missing from `assets/`. The
/// previous fallback painted a flat surface-coloured box, which on a
/// surface-coloured page read as a rendering bug. This reads as a deliberate
/// placeholder: a soft brand-tinted wash with a glyph, so the layout is honest
/// about what is missing without looking broken.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    this.icon = Icons.image_outlined,
    this.iconSize = 28,
  });

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentSoft.withValues(alpha: 0.16),
            AppColors.link.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: AppColors.accentSoft.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
