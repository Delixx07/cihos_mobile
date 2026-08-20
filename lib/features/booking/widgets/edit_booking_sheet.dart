import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Which part of the booking the patient wants to change.
enum EditBookingChoice { doctor, schedule, patient }

/// "Ubah Janji Temu?" — the three things that can still be changed before the
/// booking is confirmed.
class EditBookingSheet extends StatelessWidget {
  const EditBookingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFDDDFF3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ubah Janji Temu?',
              style: AppTypography.headingSm.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Silahkan pilih bagian yang ingin Anda ubah',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Option(
              key: const Key('editDoctor'),
              icon: Icons.local_hospital_outlined,
              label: 'Ubah Dokter',
              onTap: () =>
                  Navigator.of(context).pop(EditBookingChoice.doctor),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Option(
              key: const Key('editSchedule'),
              icon: Icons.calendar_month_outlined,
              label: 'Ubah Tanggal/Waktu',
              onTap: () =>
                  Navigator.of(context).pop(EditBookingChoice.schedule),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Option(
              key: const Key('editPatient'),
              icon: Icons.badge_outlined,
              label: 'Ubah Pasien/Jaminan',
              onTap: () =>
                  Navigator.of(context).pop(EditBookingChoice.patient),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF9F9),
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Container(
          height: 53,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: AppColors.textPrimary),
          ),
          child: Row(
            children: [
              Icon(icon, size: 28, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 15,
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
