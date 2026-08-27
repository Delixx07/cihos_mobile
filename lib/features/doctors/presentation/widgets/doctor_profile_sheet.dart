import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/doctor.dart';

/// A doctor's full profile, shown as a sheet over the search results.
///
/// Pops true when the patient chooses this doctor.
class DoctorProfileSheet extends StatelessWidget {
  const DoctorProfileSheet({super.key, required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Profil Dokter',
                          style: AppTypography.headingMd.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Header(doctor: doctor),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Metode Konsultasi',
                    style: AppTypography.titleMd.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (doctor.supports(ConsultationMethod.appointment))
                    const _MethodLine(
                      icon: Icons.medical_information,
                      label: 'Janji Temu ',
                      highlight: 'Tersedia',
                    ),
                  if (doctor.supports(ConsultationMethod.videoCall))
                    const _MethodLine(
                      icon: Icons.videocam,
                      label: 'Video Call ',
                      highlight: 'Tersedia',
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  _Section(
                    icon: Icons.school_outlined,
                    title: 'Riwayat Pendidikan',
                    lines: doctor.education,
                  ),
                  _Section(
                    icon: Icons.medical_services_outlined,
                    title: 'Minat Klinis',
                    lines: doctor.clinicalInterests,
                  ),
                  _Section(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Penghargaan',
                    lines: doctor.awards,
                  ),
                  _Section(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Kursus / Seminar',
                    lines: doctor.courses,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                0,
                AppSpacing.xxl,
                AppSpacing.xl,
              ),
              child: AppButton(
                label: 'Pilih Dokter Ini',
                expand: true,
                background: AppColors.accentSoft,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circle Avatar on the LEFT (Full fill & cut)
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: ClipOval(
            child: doctor.photoAsset == null
                ? const _PhotoPlaceholder()
                : Image.asset(
                    doctor.photoAsset!,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) =>
                        const _PhotoPlaceholder(),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: AppTypography.titleMd.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                doctor.specialty.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0284C7),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.border,
      child: Icon(Icons.person, size: 56, color: AppColors.textTertiary),
    );
  }
}

class _MethodLine extends StatelessWidget {
  const _MethodLine({
    required this.icon,
    required this.label,
    required this.highlight,
  });

  final IconData icon;
  final String label;

  /// The availability word, shown in bold.
  final String highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Text('•  ', style: TextStyle(color: AppColors.textPrimary)),
          Icon(icon, size: 22, color: AppColors.accentSoft),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodyMd.copyWith(fontSize: 15),
                children: [
                  TextSpan(text: label),
                  TextSpan(
                    text: highlight,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One titled block. Renders a dash when the list is empty, matching the
/// design rather than hiding the section.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppColors.accentSoft),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMd.copyWith(fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (lines.isEmpty)
                  Text('-', style: AppTypography.titleMd.copyWith(fontSize: 15))
                else
                  for (final line in lines)
                    Text(
                      line,
                      style: AppTypography.bodyMd.copyWith(fontSize: 15),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
