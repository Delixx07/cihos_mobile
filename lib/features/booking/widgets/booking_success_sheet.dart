import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/booking_repository.dart';

/// Where the patient goes after a booking is created.
enum BookingSuccessAction { viewHistory, home }

/// Modern and vibrant confirmation sheet shown once the booking has been created.
class BookingSuccessSheet extends StatelessWidget {
  const BookingSuccessSheet({super.key, required this.result});

  final BookingResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Glowing Success Badge
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDCFCE7),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'Janji Temu Berhasil Dibuat!',
                textAlign: TextAlign.center,
                style: AppTypography.headingSm.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jadwal konsultasi Anda telah tersimpan di sistem.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // The hospital assigns the queue number, so this is the first
              // time the patient sees it — give it the most weight on screen.
              if (result.queueNumber != null || result.slotTime != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Nomor Antrean Anda',
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.queueNumber != null
                            ? 'No. ${result.queueNumber}'
                            : (result.queueLabel ?? '-'),
                        style: AppTypography.headingSm.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      if (result.slotTime != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Perkiraan dilayani pukul ${result.slotTime}',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Kode Janji Temu: ${result.appointmentNo}',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),

              // Information Box with Visual Badges
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Info 1: QR & Check-in
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tunjukkan QR Code dari aplikasi saat tiba di Rumah Sakit untuk check-in otomatis.',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 10),
                    // Info 2: Kuitansi di RS
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Kuitansi & rincian biaya berobat akan Anda dapatkan di kasir / counter RS.',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              // 1. Primary: Lihat Riwayat Janji Temu
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  key: const Key('successHistory'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentSoft,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: AppColors.accentSoft.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context)
                      .pop(BookingSuccessAction.viewHistory),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Lihat Riwayat Janji Temu',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 2. Secondary: Kembali ke Beranda
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  key: const Key('successHome'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(BookingSuccessAction.home),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Kembali ke Beranda',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
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
