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
    required this.icon,
    required this.tint,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Backs the icon chip so the tools stay distinguishable at a glance.
  final Color tint;
}

/// Self-care tools, presented inside one dark panel.
class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  static const _tools = [
    WellnessTool(
      title: 'Asuransi',
      subtitle: 'Gunakan asuransimu di CiHos Mobile',
      icon: Icons.shield_outlined,
      tint: AppColors.link,
    ),
    WellnessTool(
      title: 'Kalender Haid',
      subtitle: 'Pantau siklus haid setiap bulannya',
      icon: Icons.calendar_month_outlined,
      tint: AppColors.danger,
    ),
    WellnessTool(
      title: 'Kalkulator BMI',
      subtitle: 'Ketahui skor BMI yang ideal untukmu',
      icon: Icons.monitor_weight_outlined,
      tint: AppColors.success,
    ),
    WellnessTool(
      title: 'Pengingat Olahraga',
      subtitle: 'Pengingat untuk rutin olahraga setiap hari',
      icon: Icons.self_improvement_outlined,
      tint: AppColors.primary,
    ),
    WellnessTool(
      title: 'Pengingat Obat',
      subtitle: 'Pengingat untuk minum obat tepat waktu',
      icon: Icons.alarm_outlined,
      tint: AppColors.warning,
    ),
    WellnessTool(
      title: 'Hitung Kalori Makan',
      subtitle: 'Kendalikan asupan harian anda',
      icon: Icons.restaurant_outlined,
      tint: AppColors.success,
    ),
    WellnessTool(
      title: 'Tracker Berhenti Merokok',
      subtitle: 'Berhenti merokok dimulai dari hari ini',
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.lg,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    Center(child: Illustrations.wellness(size: 96)),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Cek Kebutuhan\nKesehatanmu',
                      textAlign: TextAlign.center,
                      style: AppTypography.headingLg.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    for (final tool in _tools) ...[
                      _ToolCard(tool: tool),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
            ),
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tool.title} akan segera hadir.')),
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tool.tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(tool.icon, size: 21, color: tool.tint),
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      tool.subtitle,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12,
                        height: 1.25,
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
