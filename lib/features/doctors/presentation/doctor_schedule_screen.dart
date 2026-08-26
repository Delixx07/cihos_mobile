import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../../booking/domain/booking.dart';
import '../data/catalog_repository.dart';
import '../data/doctor_repository.dart';
import '../domain/doctor.dart';
import 'widgets/consultation_method_card.dart';
import '../../../core/widgets/pressable.dart';

/// Doctor profile and practicing schedule preview screen.
/// Displays read-only calendar of practicing days, then proceeds to booking schedule.
class DoctorScheduleScreen extends ConsumerStatefulWidget {
  const DoctorScheduleScreen({
    super.key,
    required this.doctorId,
    this.doctor,
    this.initialDate,
  });

  final String doctorId;
  final Doctor? doctor;
  final DateTime? initialDate;

  @override
  ConsumerState<DoctorScheduleScreen> createState() =>
      _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen> {
  Future<void> _book(Doctor doctor) async {
    final method = await showModalBottomSheet<BookingKind>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConsultationMethodSheet(doctor: doctor),
    );

    if (method == null || !mounted) return;

    // Proceed to interactive booking schedule screen
    context.push(
      AppRoutes.bookingSchedule,
      extra: Booking(
        kind: method,
        doctorId: doctor.id,
        doctorName: doctor.name,
        paramedicCode: doctor.code,
        specialty: doctor.specialty,
        unitCode: doctor.unitCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor ?? ref.watch(doctorByIdProvider(widget.doctorId));

    final effectiveUnitCode = doctor?.unitCode;
    final upcomingQuery = doctor != null
        ? UpcomingScheduleQuery(
            doctorId: doctor.id,
            unitCode: effectiveUnitCode,
            days: 30,
            withSlots: 0,
          )
        : null;

    final upcomingAsync = upcomingQuery != null
        ? ref.watch(upcomingSchedulesProvider(upcomingQuery))
        : null;

    final practisingDates = upcomingAsync?.valueOrNull
        ?.map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet();

    final availableDates = upcomingAsync?.valueOrNull != null
        ? (practisingDates ?? const <DateTime>{})
        : null;

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: 'Profil & Jadwal Dokter'),
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
                          const SizedBox(height: AppSpacing.lg),

                          // Metode Konsultasi Badges
                          _ConsultationMethodsRow(doctor: doctor),
                          const SizedBox(height: AppSpacing.lg),

                          // Sections if available
                          if (doctor.education.isNotEmpty) ...[
                            _InfoSection(
                              icon: Icons.school_outlined,
                              title: 'Riwayat Pendidikan',
                              items: doctor.education,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (doctor.clinicalInterests.isNotEmpty) ...[
                            _InfoSection(
                              icon: Icons.medical_services_outlined,
                              title: 'Minat Klinis',
                              items: doctor.clinicalInterests,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Jadwal Hari Praktek Dokter:',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Read-Only Preview Calendar
                          _DoctorSchedulePreviewCalendar(
                            practisingDates: availableDates,
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
                    label: 'Pilih Dokter Ini',
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

/// A read-only preview calendar specifically designed to display active practice days.
class _DoctorSchedulePreviewCalendar extends StatefulWidget {
  const _DoctorSchedulePreviewCalendar({
    required this.practisingDates,
  });

  final Set<DateTime>? practisingDates;

  @override
  State<_DoctorSchedulePreviewCalendar> createState() =>
      _DoctorSchedulePreviewCalendarState();
}

class _DoctorSchedulePreviewCalendarState
    extends State<_DoctorSchedulePreviewCalendar> {
  late DateTime _visibleMonth = DateTime.now();

  static const _labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(_visibleMonth);

    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - DateTime.monday;
    final cellCount = leadingBlanks + daysInMonth;
    final rowCount = (cellCount / 7).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 24),
                color: AppColors.textPrimary,
                onPressed: () => _shiftMonth(-1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                monthName,
                style: AppTypography.headingSm.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 24),
                color: AppColors.textPrimary,
                onPressed: () => _shiftMonth(1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Day of week labels
          Row(
            children: [
              for (final label in _labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),

          // Day Grid (Read-Only)
          Column(
            children: [
              for (var row = 0; row < rowCount; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: _buildDayCell(
                            row * 7 + col - leadingBlanks,
                            daysInMonth,
                            today,
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

          // Legend & Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Hari Praktek',
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 18),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Tidak Ada Jadwal',
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildDayCell(int dayOffset, int daysInMonth, DateTime today) {
    if (dayOffset < 0 || dayOffset >= daysInMonth) {
      return const SizedBox(height: 34);
    }

    final day = DateTime(_visibleMonth.year, _visibleMonth.month, dayOffset + 1);
    final isPractising = widget.practisingDates != null &&
        widget.practisingDates!.any((d) =>
            d.year == day.year && d.month == day.month && d.day == day.day);

    final isPast = day.isBefore(today);

    return Container(
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isPractising
            ? const Color(0xFFE8F5E9)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isPractising
            ? Border.all(color: const Color(0xFFA5D6A7), width: 1.2)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isPractising ? FontWeight.w800 : FontWeight.w500,
            color: isPractising
                ? const Color(0xFF2E7D32)
                : (isPast
                    ? AppColors.textTertiary.withValues(alpha: 0.4)
                    : AppColors.textSecondary),
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Circle Avatar on the LEFT (Full fill & cut)
            Container(
              width: 72,
              height: 72,
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
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
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
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
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

class _ConsultationMethodsRow extends StatelessWidget {
  const _ConsultationMethodsRow({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metode Konsultasi Tersedia',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MethodChip(
                icon: Icons.medical_information_outlined,
                label: 'Janji Temu',
                isAvailable: doctor.supports(ConsultationMethod.appointment),
              ),
              const SizedBox(width: 10),
              _MethodChip(
                icon: Icons.videocam_outlined,
                label: 'Video Call',
                isAvailable: doctor.supports(ConsultationMethod.videoCall),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.icon,
    required this.label,
    required this.isAvailable,
  });

  final IconData icon;
  final String label;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isAvailable
              ? const Color(0xFFE8F5E9)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isAvailable
                ? const Color(0xFF81C784)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isAvailable
                  ? const Color(0xFF2E7D32)
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isAvailable
                      ? const Color(0xFF2E7D32)
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accentSoft),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleMd.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
      color: AppColors.surface,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 40,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
