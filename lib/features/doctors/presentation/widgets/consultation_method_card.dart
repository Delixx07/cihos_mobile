import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../booking/domain/booking.dart';
import '../../../../core/theme/app_elevation.dart';
import '../../../../core/theme/app_motion.dart';
import '../../domain/doctor.dart';

/// The benefits a consultation method offers, per the design.
abstract final class ConsultationBenefits {
  static const appointment = [
    'Buat Janji Temu dengan Dokter',
    'Ubah jadwal dan pembatalan / refund di satu aplikasi',
    'Monitor antrean dokter sebelum tiba di RS',
    'Benefit promo biaya administrasi konsultasi dokter dan biaya '
        'pengantaran obat (S&K berlaku)',
  ];

  static const videoCall = [
    'Video Call dokter spesialis dengan durasi 15 menit.',
    'Video Call psikolog dengan durasi 30 menit',
    'Pasien mendapat diagnosis',
    'Pasien mendapat resep obat digital',
    'Privasi terjamin',
  ];

  static List<String> forKind(BookingKind kind) => switch (kind) {
    BookingKind.appointment => appointment,
    BookingKind.videoCall => videoCall,
  };

  static IconData iconFor(BookingKind kind) => switch (kind) {
    BookingKind.appointment => Icons.medical_information,
    BookingKind.videoCall => Icons.videocam,
  };

  static String titleFor(BookingKind kind) => switch (kind) {
    BookingKind.appointment => 'Janji Temu dengan Dokter',
    BookingKind.videoCall => 'Video Call dengan Dokter',
  };
}

/// One consultation method with its benefit list and a choose button.
///
/// Shared by the method picker and the "Buat Appointment?" sheet.
class ConsultationMethodCard extends StatelessWidget {
  const ConsultationMethodCard({
    super.key,
    required this.kind,
    required this.isSelected,
    required this.onSelect,
    required this.onConfirm,
  });

  final BookingKind kind;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE4F1F8) : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(
          color: isSelected ? AppColors.link : Colors.transparent,
        ),
        boxShadow: isSelected
            ? null
            : AppElevation.level2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      ConsultationBenefits.iconFor(kind),
                      size: 33,
                      color: AppColors.link,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        ConsultationBenefits.titleFor(kind),
                        style: AppTypography.inputText.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Keuntungan yang Anda dapatkan:',
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final benefit in ConsultationBenefits.forKind(kind))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle,
                            size: 11,
                            color: AppColors.link,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            benefit,
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 14,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: _PickButton(
                    isSelected: isSelected,
                    onTap: isSelected ? onConfirm : onSelect,
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

/// The card's own action: dark once its card is chosen, light otherwise.
class _PickButton extends StatelessWidget {
  const _PickButton({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        boxShadow: AppElevation.level2,
      ),
      child: Material(
        color: isSelected ? AppColors.accentSoft : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Container(
            width: 250,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : const Color(0xFFF3F3F3),
              ),
            ),
            child: Text(
              'Pilih',
              style: AppTypography.button.copyWith(
                color: isSelected
                    ? const Color(0xFFF5F5F5)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Buat Appointment?" — sheet to pick a consultation method for [doctor].
class ConsultationMethodSheet extends StatefulWidget {
  const ConsultationMethodSheet({super.key, this.doctor});

  final Doctor? doctor;

  @override
  State<ConsultationMethodSheet> createState() =>
      _ConsultationMethodSheetState();
}

class _ConsultationMethodSheetState extends State<ConsultationMethodSheet> {
  BookingKind _selected = BookingKind.appointment;

  static const _available = [
    BookingKind.appointment,
    BookingKind.videoCall,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Buat Appointment?',
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
              for (final kind in _available) ...[
                ConsultationMethodCard(
                  key: Key('method_${kind.name}'),
                  kind: kind,
                  isSelected: kind == _selected,
                  onSelect: () => setState(() => _selected = kind),
                  onConfirm: () => Navigator.of(context).pop(kind),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

