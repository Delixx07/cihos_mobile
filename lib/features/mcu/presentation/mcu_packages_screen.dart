import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/textured_background.dart';

/// One purchasable check-up package.
class McuPackage {
  const McuPackage({
    required this.coverage,
    required this.tier,
    required this.price,
  });

  final String coverage;
  final String tier;
  final int price;
}

/// A named group of packages, e.g. "Paket Khusus".
class McuGroup {
  const McuGroup({required this.name, required this.packages});

  final String name;
  final List<McuPackage> packages;
}

/// The MCU catalogue, grouped by package family.
class McuPackagesScreen extends StatefulWidget {
  const McuPackagesScreen({super.key});

  @override
  State<McuPackagesScreen> createState() => _McuPackagesScreenState();
}

class _McuPackagesScreenState extends State<McuPackagesScreen> {
  McuPackage? _selected;

  static const _groups = [
    McuGroup(
      name: 'Paket Khusus',
      packages: [
        McuPackage(coverage: 'Paket 100%', tier: 'PNS GOL II', price: 895000),
        McuPackage(coverage: 'Paket 100%', tier: 'PNS GOL III', price: 895000),
        McuPackage(coverage: 'Paket 100%', tier: 'PNS GOL IV', price: 895000),
        McuPackage(coverage: 'Paket 100%', tier: 'Umum', price: 895000),
      ],
    ),
    McuGroup(
      name: 'Paket Lengkap',
      packages: [
        McuPackage(coverage: 'Paket 100%', tier: 'PNS GOL II', price: 1250000),
        McuPackage(coverage: 'Paket 100%', tier: 'PNS GOL III', price: 1250000),
      ],
    ),
    McuGroup(
      name: 'Paket Medium',
      packages: [
        McuPackage(coverage: 'Paket 100%', tier: 'PNS GOL II', price: 650000),
        McuPackage(coverage: 'Paket 100%', tier: 'Umum', price: 650000),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: AppBackButton(),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      Center(
                        child: Text(
                          'Paket MCU',
                          style: AppTypography.headingLg.copyWith(
                            fontSize: 24,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Image.asset(
                          'assets/images/mcu.png',
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      for (final group in _groups) ...[
                        Center(child: _GroupChip(label: group.name)),
                        const SizedBox(height: AppSpacing.lg),
                        _PackageGrid(
                          packages: group.packages,
                          selected: _selected,
                          onSelected: (value) =>
                              setState(() => _selected = value),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 121),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTypography.inputText.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PackageGrid extends StatelessWidget {
  const _PackageGrid({
    required this.packages,
    required this.selected,
    required this.onSelected,
  });

  final List<McuPackage> packages;
  final McuPackage? selected;
  final ValueChanged<McuPackage> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        for (final package in packages)
          _PackageCard(
            package: package,
            isSelected: package == selected,
            onTap: () => onSelected(package),
          ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  final McuPackage package;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Material(
      // Selected cards go grey, matching the design's two card states.
      color: isSelected ? const Color(0xFFD9D9D9) : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 76,
          // The design's 63px leaves no room for three lines of Kumbh Sans;
          // let the card size to its content instead of clipping.
          constraints: const BoxConstraints(minHeight: 63),
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                package.coverage,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                package.tier,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(height: AppSpacing.sm, color: AppColors.textPrimary),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${rupiah.format(package.price)},-',
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
