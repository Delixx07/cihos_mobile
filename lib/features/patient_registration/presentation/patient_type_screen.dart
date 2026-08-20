import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../../../core/theme/app_elevation.dart';

/// Step 1 — has this person been a patient here before?
class PatientTypeScreen extends StatelessWidget {
  const PatientTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: ListView(
            children: [
              const ScreenHeader(title: 'Pendaftaran Pasien'),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                child: Text(
                  'Apakah Anda pernah menjadi pasien Ciputra Hospital '
                  'Surabaya?',
                  style: AppTypography.headingSm.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: Column(
                  children: [
                    _ChoiceCard(
                      key: const Key('existingPatient'),
                      icon: Icons.badge_outlined,
                      title: 'Ya, saya pernah terdaftar sebagai pasien',
                      subtitle:
                          'Daftar dengan menggunakan no. rekam medis atau KTP',
                      onTap: () =>
                          context.push(AppRoutes.registerExistingPatient),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _ChoiceCard(
                      key: const Key('newPatient'),
                      icon: Icons.assignment_outlined,
                      title: 'Tidak, saya belum pernah terdaftar sebagai pasien',
                      subtitle: 'Daftarkan sebagai pasien baru',
                      onTap: () => context.push(AppRoutes.registerNewPatient),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Pasien diatas satu tahun wajib memasukkan no. NIK yang '
                      'terdaftar di Kartu Keluarga*',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        boxShadow: AppElevation.level2,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Icon(icon, size: 40, color: AppColors.textPrimary),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.inputText.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
