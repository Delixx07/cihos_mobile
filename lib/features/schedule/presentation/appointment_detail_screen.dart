import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../data/schedule_repository.dart';
import 'widgets/cancel_appointment_sheet.dart';
import 'widgets/cost_estimate_sheet.dart';
import '../domain/scheduled_appointment.dart';

/// Everything about one booked visit, plus the actions that can change it.
class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointment = ref.watch(
      scheduledAppointmentProvider(appointmentId),
    );

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: 'Detail Janji Temu'),
              Expanded(
                child: appointment == null
                    ? Center(
                        child: Text(
                          'Janji temu tidak ditemukan',
                          style: AppTypography.bodyMd,
                        ),
                      )
                    : _Body(appointment: appointment),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.appointment});

  final ScheduledAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      children: [
        const _SectionTitle('PASIEN'),
        _Card(
          child: _IconLine(
            icon: Icons.account_circle_outlined,
            text: appointment.patientName,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        const _SectionTitle('RUMAH SAKIT'),
        _Card(
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 28,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.hospital,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lihat di Peta',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4858EF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        Row(
          children: [
            const Expanded(child: _SectionTitle('DETAIL JANJI TEMU')),
            _StatusPill(status: appointment.status),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _Card(child: _DetailBody(appointment: appointment)),
        const SizedBox(height: AppSpacing.xxl),

        _OutlinedAction(
          icon: Icons.calendar_month_outlined,
          label: 'Ubah Jadwal',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ubah jadwal akan segera hadir.')),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _OutlinedAction(
          key: const Key('cancelAppointment'),
          label: 'Batalkan Janji Temu',
          onTap: () => _confirmCancel(context),
        ),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CancelAppointmentSheet(),
    );

    if (reason == null || !context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CancelSubmittedSheet(),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.appointment});

  final ScheduledAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Field(
                    label: 'KODE BOOKING',
                    value: appointment.bookingCode,
                    isLarge: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Field(
                    label: 'No. Antrean',
                    value: '${appointment.queueNumber}',
                    isLarge: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x33000000)),
              ),
              child: Illustrations.qrCode(size: 94),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Field(
                label: 'Tanggal',
                value: DateFormat(
                  'EEEE, d MMMM yyyy',
                  'id_ID',
                ).format(appointment.startsAt),
              ),
            ),
            Expanded(
              child: _Field(
                label: 'Perkiraan Slot Waktu',
                value: appointment.timeRange,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Field(
          label: 'Dokter',
          value: appointment.doctorName,
          isBold: true,
        ),
        Text(
          appointment.specialty,
          style: AppTypography.bodySm.copyWith(fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Field(
                label: 'Jenis Jaminan',
                value: appointment.guaranteeType,
                isBold: true,
              ),
            ),
            Expanded(
              child: _Field(
                label: 'No. ID Rekanan',
                value: appointment.partnerId ?? '–',
                isBold: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          key: const Key('costEstimate'),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => CostEstimateSheet(
              doctorName: appointment.doctorName,
              lines: const [
                CostLine(label: 'Jaminan Asuransi/Perusahaan', amount: 500000),
                CostLine(label: 'Biaya Administrasi', amount: 69000),
              ],
            ),
          ),
          child: Row(
            children: [
              Text(
                'Lihat Perkiraan Biaya',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.link,
                ),
              ),
              const Icon(Icons.chevron_right, size: 14, color: AppColors.link),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _InfoBox(),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox();

  static const _notes = [
    'Masukkan scan/Kode Booking di KiosK pendaftaran',
    'Harap melakukan check in sebelum jam praktek dokter berakhir. Check in '
        'akan gagal bila dilakukan setelah jam praktek dokter selesai',
    'Pantau antrean dokter via fitur Monitor Antrean Dokter di hari '
        'konsultasi, urutan antrean akan disesuaikan.',
    'Nomor antrean Dokter berubah jika melakukan ubah jadwal.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDF9FF),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 22,
                color: AppColors.link,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Informasi Tambahan',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.link,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final note in _notes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(fontSize: 11)),
                  Expanded(
                    child: Text(
                      note,
                      textAlign: TextAlign.justify,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        height: 1.25,
                        color: Colors.black,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      AppointmentStatus.onSchedule => (
        const Color(0xFFDDFEC8),
        const Color(0xFF2D8014),
      ),
      AppointmentStatus.rescheduled => (
        AppColors.warningSurface,
        AppColors.warning,
      ),
      AppointmentStatus.cancelled => (
        AppColors.dangerSurface,
        AppColors.danger,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        status.label,
        style: AppTypography.bodySm.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.headingSm.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySm.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.isLarge = false,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isLarge;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySm.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTypography.bodySm.copyWith(
            fontSize: isLarge ? 20 : (isBold ? 13 : 11),
            fontWeight: isLarge || isBold
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: AppColors.textPrimary),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22, color: AppColors.textPrimary),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  label,
                  textAlign: icon == null ? TextAlign.center : TextAlign.start,
                  style: AppTypography.button.copyWith(
                    color: AppColors.textPrimary,
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
