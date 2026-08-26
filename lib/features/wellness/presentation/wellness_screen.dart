import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/textured_background.dart';

/// One self-care tool in the Sehat-mu list.
class WellnessTool {
  const WellnessTool({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    this.icon = Icons.health_and_safety_outlined,
    required this.tint,
  });

  final String title;
  final String subtitle;
  final String imageAsset;
  final IconData icon;

  /// Backs the icon chip so the tools stay distinguishable at a glance.
  final Color tint;
}

/// Self-care tools screen with modern layout and beautiful colorful cards.
class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  static const _tools = [
    WellnessTool(
      title: 'Asuransi',
      subtitle: 'Gunakan asuransimu di CiHos Mobile',
      imageAsset: 'assets/images/sehat-mu/asuransi.png',
      icon: Icons.shield_outlined,
      tint: AppColors.link,
    ),
    WellnessTool(
      title: 'Kalender Haid',
      subtitle: 'Pantau siklus haid setiap bulannya',
      imageAsset: 'assets/images/sehat-mu/kalender haid.png',
      icon: Icons.calendar_month_outlined,
      tint: AppColors.danger,
    ),
    WellnessTool(
      title: 'Kalkulator BMI',
      subtitle: 'Ketahui skor BMI yang ideal untukmu',
      imageAsset: 'assets/images/sehat-mu/kalender bmi.png',
      icon: Icons.monitor_weight_outlined,
      tint: AppColors.success,
    ),
    WellnessTool(
      title: 'Pengingat Olahraga',
      subtitle: 'Pengingat untuk rutin olahraga setiap hari',
      imageAsset: 'assets/images/sehat-mu/yoga.png',
      icon: Icons.self_improvement_outlined,
      tint: AppColors.primary,
    ),
    WellnessTool(
      title: 'Pengingat Obat',
      subtitle: 'Pengingat untuk minum obat tepat waktu',
      imageAsset: 'assets/images/sehat-mu/pengingat obat.png',
      icon: Icons.alarm_outlined,
      tint: AppColors.warning,
    ),
    WellnessTool(
      title: 'Hitung Kalori Makan',
      subtitle: 'Kendalikan asupan harian anda',
      imageAsset: 'assets/images/sehat-mu/hitung kalori.png',
      icon: Icons.restaurant_outlined,
      tint: AppColors.success,
    ),
    WellnessTool(
      title: 'Tracker Berhenti Merokok',
      subtitle: 'Berhenti merokok dimulai dari hari ini',
      imageAsset: 'assets/images/sehat-mu/berhenti merokok.png',
      icon: Icons.smoke_free_outlined,
      tint: AppColors.danger,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: AppTab.health),
      body: TexturedBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sehat-mu',
                          style: AppTypography.headingLg.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Hero Banner Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF5F7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.mint.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cek Kebutuhan\nKesehatanmu',
                              style: AppTypography.headingMd.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pantau kebiasaan sehat harian Anda dengan fitur mandiri.',
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Illustrations.wellness(size: 68),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Text(
                  'Fitur Kesehatan Mandiri',
                  style: AppTypography.titleMd.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Tools List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xs,
                    AppSpacing.xxl,
                    AppSpacing.xxxl,
                  ),
                  itemCount: _tools.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) =>
                      _ToolCard(tool: _tools[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});

  final WellnessTool tool;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fitur ${tool.title} akan segera hadir.'),
            duration: const Duration(seconds: 2),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentSoft.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Badge with image asset and distinct tint background
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tool.tint.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  tool.imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    tool.icon,
                    size: 24,
                    color: tool.tint,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.subtitle,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
