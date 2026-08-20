import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../../booking/domain/booking.dart';
import '../../booking/widgets/practice_calendar.dart';
import '../data/doctor_repository.dart';
import '../domain/doctor.dart';
import 'widgets/appointment_method_sheet.dart';
import '../../../core/widgets/pressable.dart';

/// A doctor's practising days, with the option to book one.
class DoctorScheduleScreen extends ConsumerStatefulWidget {
  const DoctorScheduleScreen({
    super.key,
    required this.doctorId,
    this.initialDate,
  });

  final String doctorId;
  final DateTime? initialDate;

  @override
  ConsumerState<DoctorScheduleScreen> createState() =>
      _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen> {
  late DateTime? _date = widget.initialDate;

  Future<void> _book(Doctor doctor) async {
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal terlebih dahulu.')),
      );
      return;
    }

    final method = await showModalBottomSheet<BookingKind>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppointmentMethodSheet(doctor: doctor),
    );

    if (method == null || !mounted) return;

    context.push(
      AppRoutes.bookingSchedule,
      extra: Booking(
        kind: method,
        doctorId: doctor.id,
        doctorName: doctor.name,
        specialty: doctor.specialty,
        date: _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = ref.watch(doctorByIdProvider(widget.doctorId));

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: 'Jadwal Dokter'),
              Expanded(
                child: doctor == null
                    ? Center(
                        child: Text(
                          'Dokter tidak ditemukan',
                          style: AppTypography.bodyMd,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          AppSpacing.md,
                          AppSpacing.xxl,
                          AppSpacing.xxl,
                        ),
                        children: [
                          Pressable(
                            scale: 0.98,
                            child: _DoctorCard(doctor: doctor),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Berikut ini Jadwal Dokter yang tersedia:',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PracticeCalendar(
                            kind: BookingKind.appointment,
                            selected: _date,
                            onSelected: (value) =>
                                setState(() => _date = value),
                          ),
                        ],
                      ),
              ),
              if (doctor != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    0,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  child: AppButton(
                    label: 'Buat Appointment',
                    expand: true,
                    background: AppColors.accentSoft,
                    onPressed: () => _book(doctor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 84,
                height: 84,
                child: doctor.photoAsset == null
                    ? const _PhotoPlaceholder()
                    : Image.asset(
                        doctor.photoAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _PhotoPlaceholder(),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: AppTypography.inputText.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _MetaLine(
                    icon: Icons.medical_services_outlined,
                    text: doctor.specialty,
                  ),
                  _MetaLine(
                    icon: Icons.location_on_outlined,
                    text: doctor.hospital,
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

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(
                fontSize: 13,
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
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
      color: AppColors.border,
      child: Icon(Icons.person, size: 40, color: AppColors.textTertiary),
    );
  }
}
