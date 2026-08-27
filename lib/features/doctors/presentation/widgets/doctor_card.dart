import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../booking/domain/booking.dart';
import '../../domain/doctor.dart';

/// Modern doctor card for search and catalog screens with rich color accents.
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
    final (actionIcon, actionLabel, actionBgColor) = switch (kind) {
      BookingKind.appointment => (
        Icons.medical_services_rounded,
        'Janji Temu',
        AppColors.accentSoft,
      ),
      BookingKind.videoCall => (
        Icons.videocam_rounded,
        'Video Call',
        const Color(0xFF059669),
      ),
      null => (
        Icons.calendar_month_rounded,
        'Lihat Jadwal',
        AppColors.accentSoft,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
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
              // Circle Avatar with vibrant border ring
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(
                    color: const Color(0xFF14B8A6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: doctor.photoAsset == null
                      ? const _PhotoPlaceholder()
                      : Image.asset(
                          doctor.photoAsset!,
                          width: 66,
                          height: 66,
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
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          // Actions Row
          Row(
            children: [
              // Lihat Profil Button
              Expanded(
                child: OutlinedButton(
                  onPressed: onProfileTap,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    side: const BorderSide(
                      color: AppColors.border,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Profil',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
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
                    backgroundColor: actionBgColor,
                    foregroundColor: AppColors.white,
                    elevation: 1,
                    shadowColor: actionBgColor.withValues(alpha: 0.3),
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
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
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
