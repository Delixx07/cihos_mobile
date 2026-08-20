import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/illustrations.dart';
import '../../../../core/theme/app_elevation.dart';

/// The booked-appointment card under "Konsultasi Anda", carrying the check-in
/// QR code.
class ConsultationCard extends StatelessWidget {
  const ConsultationCard({
    super.key,
    required this.patientName,
    required this.scheduledAt,
    required this.endsAt,
    required this.bookingCode,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    this.onDetailTap,
  });

  final String patientName;
  final DateTime scheduledAt;
  final DateTime endsAt;
  final String bookingCode;
  final String doctorName;
  final String specialty;
  final String hospital;
  final VoidCallback? onDetailTap;

  @override
  Widget build(BuildContext context) {
    final dayFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        boxShadow: AppElevation.level2,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  patientName,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.textPrimary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Field(
                        label: 'Jadwal Janji Temu',
                        value: dayFormat.format(scheduledAt),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _Field(
                        label: 'Perkiraan Waktu',
                        value:
                            '${timeFormat.format(scheduledAt)} - '
                            '${timeFormat.format(endsAt)} WIB',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _Field(label: 'Kode Booking', value: bookingCode),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _QrPanel(onTap: onDetailTap),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Field(label: 'Detail Janji Temu', value: doctorName),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    specialty,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 12,
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          hospital,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: onDetailTap,
              child: Row(
                children: [
                  Text(
                    'Lihat Detail',
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySm.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTypography.bodySm.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// The dark panel holding the check-in QR code.
class _QrPanel extends StatelessWidget {
  const _QrPanel({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 113,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          const Text(
            'Scan QR Janji Temu',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: 94,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Illustrations.qrCode(size: 79),
          ),
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: onTap,
            child: const Text(
              'KLIK DISINI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
