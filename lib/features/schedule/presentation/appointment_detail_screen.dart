import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/illustrations.dart';
import '../data/schedule_repository.dart';
import '../domain/scheduled_appointment.dart';
import 'widgets/cancel_appointment_sheet.dart';
import 'widgets/cost_estimate_sheet.dart';

/// Full-screen modern view of a booked appointment featuring a signature dark slate header,
/// curved content sheet, QR check-in pass, doctor info, and action dock.
class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({
    super.key,
    required this.appointmentId,
    this.initialAppointment,
  });

  final String appointmentId;
  final ScheduledAppointment? initialAppointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointment = initialAppointment ??
        ref.watch(scheduledAppointmentProvider(appointmentId));

    if (appointment == null) {
      return Scaffold(
        backgroundColor: AppColors.accentSoft,
        body: Column(
          children: [
            _TopAppBar(
              title: 'Detail Janji Temu',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Janji temu tidak ditemukan',
                        style: AppTypography.headingSm.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Jadwal mungkin telah dibatalkan atau dipindahkan.',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentSoft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Kembali ke Jadwal'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isCancelled = appointment.status == AppointmentStatus.cancelled;
    final isRescheduled = appointment.status == AppointmentStatus.rescheduled;

    final (statusBg, statusColor, statusIcon) = isCancelled
        ? (
            const Color(0xFFFEE2E2),
            const Color(0xFFDC2626),
            Icons.cancel_outlined,
          )
        : (isRescheduled
            ? (
                const Color(0xFFFEF3C7),
                const Color(0xFFD97706),
                Icons.schedule_rounded,
              )
            : (
                const Color(0xFFDCFCE7),
                const Color(0xFF15803D),
                Icons.check_circle_outline_rounded,
              ));

    return Scaffold(
      backgroundColor: AppColors.accentSoft,
      body: Column(
        children: [
          // 1. Signature Dark Slate Header
          Container(
            color: AppColors.accentSoft,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.sm,
              AppSpacing.xxl,
              AppSpacing.lg,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Row
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Detail Janji Temu',
                          style: AppTypography.headingMd.copyWith(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  'Kode Booking: ${appointment.bookingCode}\nDokter: ${appointment.doctorName}\nJadwal: ${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(appointment.startsAt)} (${appointment.timeRange})',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: AppColors.primary,
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Detail janji temu disalin ke clipboard.',
                                      style: TextStyle(color: AppColors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Hero Doctor Name & Specialty
                  Text(
                    appointment.doctorName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headingMd.copyWith(
                      color: AppColors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${appointment.specialty} • ${appointment.hospital}',
                    style: AppTypography.bodySm.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Header Badges Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Specialty Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.medical_services_outlined,
                              size: 13,
                              color: Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appointment.specialty,
                              style: AppTypography.caption.copyWith(
                                color: const Color(0xFF0284C7),
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              appointment.status.label,
                              style: AppTypography.caption.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Patient Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appointment.patientName,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Date Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy', 'id_ID')
                                  .format(appointment.startsAt),
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Curved Surface Content Panel
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.xl,
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                      ),
                      children: [
                        // Card 1: QR Pass & Digital Check-In
                        _QrPassCard(
                          appointment: appointment,
                          onShowFullQr: () => _showFullQrDialog(context, appointment),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Card 2: Detail Rumah Sakit & Jadwal
                        _HospitalScheduleCard(appointment: appointment),
                        const SizedBox(height: AppSpacing.lg),

                        // Card 3: Informasi Pasien & Penjamin
                        _PatientGuarantorCard(appointment: appointment),
                        const SizedBox(height: AppSpacing.lg),

                        // Card 4: Informasi Penting
                        const _ImportantNoticeCard(),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),

                  // 3. Bottom Action Dock
                  _BottomActionDock(
                    appointment: appointment,
                    onShowFullQr: () => _showFullQrDialog(context, appointment),
                    onCancelAppointment: () =>
                        _confirmCancel(context, ref, appointment),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullQrDialog(BuildContext context, ScheduledAppointment appointment) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QR Check-In Pendaftaran',
                style: AppTypography.headingMd.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Illustrations.qrCode(size: 210),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                appointment.bookingCode,
                style: AppTypography.headingSm.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'No. Antrean: ${appointment.queueNumber}',
                style: AppTypography.bodySm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentSoft,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tunjukkan QR ini pada petugas atau arahkan ke scanner mesin KiosK mandiri.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    ScheduledAppointment appointment,
  ) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CancelAppointmentSheet(),
    );

    if (reason == null || !context.mounted) return;

    // Cancelling writes to the hospital system, so the patient waits on the
    // real result rather than being told it worked before it has.
    final progress = showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CancelInProgressSheet(),
    );

    String? failure;
    try {
      await ref
          .read(scheduleRepositoryProvider)
          .voidAppointment(
            appointmentNo: appointment.bookingCode,
            reason: reason,
          );
      // The list still holds the appointment as booked; refetch so the
      // schedule and history tabs move it across.
      ref.invalidate(appointmentsProvider);
    } on ApiException catch (e) {
      failure = switch (e.code) {
        'already_registered' =>
          'Anda sudah check-in untuk janji temu ini, jadi pembatalan tidak '
              'bisa dilakukan lewat aplikasi. Silakan hubungi rumah sakit.',
        'already_voided' => 'Janji temu ini sudah dibatalkan sebelumnya.',
        'not_found' => 'Janji temu ini tidak ditemukan pada akun Anda.',
        _ => e.message,
      };
    } catch (_) {
      failure = 'Pembatalan gagal diproses. Silakan coba lagi.';
    }

    // Close the progress sheet before showing the outcome.
    if (context.mounted) Navigator.of(context).pop();
    await progress;
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => failure == null
          ? const CancelSubmittedSheet()
          : CancelFailedSheet(message: failure),
    );

    // A cancelled appointment no longer belongs on its detail screen.
    if (failure == null && context.mounted) context.pop();
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accentSoft,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.md,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              onPressed: onBack,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              title,
              style: AppTypography.headingMd.copyWith(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Digital check-in pass card with high contrast QR Code and Booking Code.
class _QrPassCard extends StatelessWidget {
  const _QrPassCard({
    required this.appointment,
    required this.onShowFullQr,
  });

  final ScheduledAppointment appointment;
  final VoidCallback onShowFullQr;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentSoft.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QR Code Box
              InkWell(
                onTap: onShowFullQr,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Illustrations.qrCode(size: 96),
                      const SizedBox(height: 4),
                      Text(
                        'Perbesar QR',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Code & Queue details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KODE BOOKING',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            appointment.bookingCode,
                            style: AppTypography.headingMd.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(
                              ClipboardData(text: appointment.bookingCode),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kode booking disalin!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'NOMOR ANTREAN',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${appointment.queueNumber}',
                      style: AppTypography.headingLg.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accentSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: AppColors.accentSoft,
              ),
              const SizedBox(width: 6),
              Text(
                'Perkiraan Sesi:',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                appointment.timeRange,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hospital location, clinic and practice time card.
class _HospitalScheduleCard extends StatelessWidget {
  const _HospitalScheduleCard({required this.appointment});

  final ScheduledAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Lokasi & Jadwal Praktik',
                style: AppTypography.titleMd.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.accentSoft,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.hospital,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jl. CitraLand Utama, Made, Kec. Sambikerep, Surabaya',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: AppColors.accentSoft,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                      .format(appointment.startsAt),
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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

/// Patient and insurance guarantor details card.
class _PatientGuarantorCard extends StatelessWidget {
  const _PatientGuarantorCard({required this.appointment});

  final ScheduledAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final isInsurance =
        !appointment.guaranteeType.toLowerCase().contains('pribadi');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_pin_rounded,
                  size: 18,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Data Pasien & Penjamin',
                style: AppTypography.titleMd.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            label: 'Nama Pasien',
            value: appointment.patientName,
            trailingBadge: appointment.isSelf ? 'Pasien Utama' : 'Keluarga',
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            label: 'Jenis Jaminan',
            value: appointment.guaranteeType,
            valueColor: isInsurance
                ? const Color(0xFF059669)
                : AppColors.textPrimary,
          ),
          if (appointment.partnerId != null &&
              appointment.partnerId!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              label: 'No. ID Rekanan / Polis',
              value: appointment.partnerId!,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CostEstimateSheet(
                doctorName: appointment.doctorName,
                lines: const [
                  CostLine(label: 'Jasa Konsultasi Spesialis', amount: 350000),
                  CostLine(label: 'Biaya Administrasi RS', amount: 65000),
                ],
              ),
            ),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Lihat Perkiraan Biaya',
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.primary,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.trailingBadge,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? trailingBadge;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              fontSize: 13,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailingBadge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trailingBadge!,
                    style: AppTypography.caption.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Important instructions notice card with clean visual styling.
class _ImportantNoticeCard extends StatelessWidget {
  const _ImportantNoticeCard();

  static const _notes = [
    'Pindai QR Kode Booking di mesin KiosK mandiri saat tiba di rumah sakit.',
    'Harap check-in paling lambat 15 menit sebelum jam praktik dokter berakhir.',
    'Urutan antrean dapat dipantau langsung secara real-time via fitur Monitor Antrean.',
    'Nomor antrean poliklinik diterbitkan otomatis saat proses check-in berhasil.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE0F2FE).withValues(alpha: 0.7),
            const Color(0xFFF0F9FF).withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFBAE6FD),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF0284C7),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Penting Untuk Diketahui',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0369A1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final note in _notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•  ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      note,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12,
                        height: 1.3,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom persistent actions dock for QR modal and cancellation.
class _BottomActionDock extends StatelessWidget {
  const _BottomActionDock({
    required this.appointment,
    required this.onShowFullQr,
    required this.onCancelAppointment,
  });

  final ScheduledAppointment appointment;
  final VoidCallback onShowFullQr;
  final VoidCallback onCancelAppointment;

  @override
  Widget build(BuildContext context) {
    final isCancelled = appointment.status == AppointmentStatus.cancelled;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCancelled) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentSoft,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onShowFullQr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tampilkan QR Pendaftaran',
                        style: AppTypography.button.copyWith(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ubah jadwal akan segera hadir.'),
                          ),
                        );
                      },
                      child: Text(
                        'Ubah Jadwal',
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        backgroundColor: const Color(0xFFFEF2F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onCancelAppointment,
                      child: Text(
                        'Batalkan Janji',
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => context.push(AppRoutes.appointmentSearch),
                  child: const Text(
                    'Buat Janji Temu Baru',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
