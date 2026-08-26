import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../booking/domain/booking.dart';
import '../../domain/doctor.dart';

/// Modern doctor card for search and catalog screens.
class DoctorCard extends StatelessWidget {
  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onProfileTap,
    required this.onBookTap,
    this.kind,
  });

  final Doctor doctor;
  final VoidCallback onProfileTap;
  final VoidCallback onBookTap;
  final BookingKind? kind;

  @override
  Widget build(BuildContext context) {
    final (actionIcon, actionLabel) = switch (kind) {
      BookingKind.appointment => (
        Icons.medical_services_outlined,
        'Janji Temu',
      ),
      BookingKind.videoCall => (
        Icons.videocam_rounded,
        'Video Call',
      ),
      null => (
        Icons.calendar_month_outlined,
        'Jadwal',
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle Avatar on the LEFT (Full fill & cut)
              Container(
                width: 64,
                height: 64,
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
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) =>
                              const _PhotoPlaceholder(),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Doctor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: AppTypography.inputText.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Specialty Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doctor.specialty,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentSoft,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Hospital line
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doctor.hospital,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          // Actions
          Row(
            children: [
              // Lihat Profil Button
              Expanded(
                child: OutlinedButton(
                  onPressed: onProfileTap,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(
                      color: AppColors.accentSoft.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: AppColors.accentSoft,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Profil',
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Dynamic Action Button (Janji Temu / Video Call / Jadwal)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onBookTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentSoft,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        actionIcon,
                        size: 15,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        actionLabel,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 32,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
