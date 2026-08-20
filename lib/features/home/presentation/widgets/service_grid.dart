import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_elevation.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/staggered_entrance.dart';

/// One tile in the 3x2 service grid.
class ServiceItem {
  const ServiceItem({
    required this.label,
    required this.icon,
    required this.imageAsset,
    this.onTap,
  });

  final String label;
  final IconData icon;

  /// The illustrated icon from Figma; the Material [icon] stands in until it
  /// is exported.
  final String imageAsset;
  final VoidCallback? onTap;
}

/// The 3x2 grid of primary services under the promo banner.
class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key, required this.items});

  final List<ServiceItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.xl,
        crossAxisSpacing: AppSpacing.lg,
        // Taller than the Figma 97:86 box: the icon plus two lines of label
        // no longer fit that ratio at the current text size.
        childAspectRatio: 97 / 104,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => StaggeredEntrance(
        index: index,
        child: Pressable(scale: 0.95, child: _ServiceTile(item: items[index])),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.item});

  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.level2,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  item.imageAsset,
                  width: 42,
                  height: 42,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    item.icon,
                    size: 34,
                    color: AppColors.accentSoft,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentSoft,
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
