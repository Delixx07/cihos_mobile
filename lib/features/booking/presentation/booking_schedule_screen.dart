import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/booking.dart';
import '../widgets/practice_calendar.dart';
import '../../doctors/data/catalog_repository.dart';
import '../../doctors/data/doctor_repository.dart';
import '../../doctors/domain/practice_schedule.dart';

/// Pick the day for the chosen consultation kind, then continue to patient selection.
class BookingScheduleScreen extends ConsumerStatefulWidget {
  const BookingScheduleScreen({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends ConsumerState<BookingScheduleScreen> {
  late DateTime? _date = widget.booking.date;
  // Caches the matched UpcomingScheduleDate when the user picks a calendar date.
  UpcomingScheduleDate? _selectedScheduleCache;

  void _confirm({
    required List<UpcomingScheduleDate>? upcomingList,
    required List<PracticeSchedule> weeklySchedules,
  }) {
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal terlebih dahulu.')),
      );
      return;
    }

    // Prefer cached entry; fall back to scanning the latest upcoming list.
    final schedule = _selectedScheduleCache ??
        upcomingList?.cast<UpcomingScheduleDate?>().firstWhere(
          (s) =>
              s != null &&
              s.date.year == _date!.year &&
              s.date.month == _date!.month &&
              s.date.day == _date!.day,
          orElse: () => null,
        );

    // Resolve unitCode: prefer upcoming entry → weekly schedule → booking original.
    String? resolvedUnitCode = (schedule?.unitCode.isNotEmpty == true)
        ? schedule!.unitCode
        : null;

    // Resolve operationalTimeCode: prefer upcoming entry → weekly schedule.
    String? resolvedOpTimeCode = (schedule?.operationalTimeCode.isNotEmpty == true)
        ? schedule!.operationalTimeCode
        : null;

    // If either field is still empty, fall back to the weekly practice schedule
    // matched by day-of-week (ISO weekday: Mon=1 … Sun=7).
    if ((resolvedUnitCode == null || resolvedOpTimeCode == null) &&
        _date != null &&
        weeklySchedules.isNotEmpty) {
      final dayOfWeek = _date!.weekday; // 1=Mon … 7=Sun
      final weeklyMatch = weeklySchedules.cast<PracticeSchedule?>().firstWhere(
        (s) => s != null && s.dayNumber == dayOfWeek,
        orElse: () => null,
      );
      if (weeklyMatch != null) {
        resolvedUnitCode ??= weeklyMatch.unitCode.isNotEmpty
            ? weeklyMatch.unitCode
            : null;
        resolvedOpTimeCode ??= weeklyMatch.operationalTimeCode.isNotEmpty
            ? weeklyMatch.operationalTimeCode
            : null;
      }
    }

    // Final fallback: keep original value from the booking object.
    resolvedUnitCode ??= widget.booking.unitCode;

    context.push(
      AppRoutes.bookingPatient,
      extra: widget.booking.copyWith(
        date: _date,
        operationalTimeCode: resolvedOpTimeCode,
        unitCode: resolvedUnitCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.booking.doctorId != null 
        ? ref.watch(doctorByIdProvider(widget.booking.doctorId!)) 
        : null;

    final isAppointment = widget.booking.kind == BookingKind.appointment;
    final methodIcon = isAppointment 
        ? Icons.medical_services_outlined 
        : Icons.videocam_outlined;
    final methodIconBg = isAppointment 
        ? const Color(0xFFE0F2FE) 
        : const Color(0xFFEDE9FE);
    final methodIconColor = isAppointment 
        ? const Color(0xFF0284C7) 
        : const Color(0xFF7C3AED);
    final methodTitle = isAppointment 
        ? 'Janji Temu dengan Dokter' 
        : 'Video Call dengan Dokter';

    final effectiveUnitCode = widget.booking.unitCode ?? doctor?.unitCode;
    final upcomingQuery = widget.booking.doctorId != null
        ? UpcomingScheduleQuery(
            doctorId: widget.booking.doctorId!,
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

    final selectedSchedule = _selectedScheduleCache ?? (_date == null
        ? null
        : upcomingAsync?.valueOrNull?.cast<UpcomingScheduleDate?>().firstWhere(
            (s) =>
                s != null &&
                s.date.year == _date!.year &&
                s.date.month == _date!.month &&
                s.date.day == _date!.day,
            orElse: () => null,
          ));

    final availableDates = upcomingAsync?.valueOrNull != null
        ? (practisingDates ?? const <DateTime>{})
        : const <DateTime>{};

    // Fetch weekly practice schedules as a fallback source for
    // operationalTimeCode and unitCode, since /app/schedule-upcoming
    // sometimes omits these fields. /taptalk/schedule reliably includes them.
    final weeklySchedulesAsync = widget.booking.doctorId != null
        ? ref.watch(doctorSchedulesProvider(widget.booking.doctorId!))
        : null;
    final weeklySchedules = weeklySchedulesAsync?.valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.accentSoft,
      body: Column(
        children: [
          // Doctor Info Header (using App's native colors)
          Container(
            color: AppColors.accentSoft,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.sm,
              AppSpacing.xxl,
              AppSpacing.xl,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
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
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circle Avatar on the LEFT (Full fill & cut)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: doctor?.photoAsset == null
                              ? const Icon(
                                  Icons.person,
                                  size: 38,
                                  color: AppColors.white,
                                )
                              : Image.asset(
                                  doctor!.photoAsset!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.person,
                                    size: 38,
                                    color: AppColors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.booking.doctorName ?? 'Dokter',
                              style: AppTypography.headingMd.copyWith(
                                color: AppColors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (widget.booking.specialty ?? '').toUpperCase(),
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.lavender,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
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
          // White Content Panel
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                children: [
                  // Consultation Method Card (Above Calendar)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: methodIconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            methodIcon,
                            size: 22,
                            color: methodIconColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Metode Konsultasi',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                methodTitle,
                                style: AppTypography.inputText.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Tanggal',
                        style: AppTypography.inputText.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (upcomingAsync?.isLoading == true)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentSoft,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PracticeCalendar(
                    kind: widget.booking.kind,
                    selected: _date,
                    practisingDates: availableDates,
                    onSelected: (value) {
                      // Cache the matched schedule entry so _confirm() can
                      // read operationalTimeCode without needing build context.
                      final matched = upcomingAsync?.valueOrNull
                          ?.cast<UpcomingScheduleDate?>()
                          .firstWhere(
                            (s) =>
                                s != null &&
                                s.date.year == value.year &&
                                s.date.month == value.month &&
                                s.date.day == value.day,
                            orElse: () => null,
                          );
                      setState(() {
                        _date = value;
                        _selectedScheduleCache = matched;
                      });
                    },
                  ),
                  if (upcomingAsync != null &&
                      upcomingAsync.hasValue &&
                      practisingDates != null &&
                      practisingDates.isEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Dokter tidak memiliki jadwal praktek dalam 30 hari ke depan.',
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_date != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.mint.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentSoft,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.accentSoft,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tanggal Dipilih:',
                                  style: AppTypography.bodySm.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'EEEE, d MMMM yyyy',
                                    'id_ID',
                                  ).format(_date!),
                                  style: AppTypography.bodySm.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (selectedSchedule != null &&
                                    selectedSchedule.timeLabel.isNotEmpty)
                                  Text(
                                    'Jam Praktek: ${selectedSchedule.timeLabel}',
                                    style: AppTypography.bodySm.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.link,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.booking.kind.leadTimeNote,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 13,
                      height: 1.3,
                      color: AppColors.accentSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.white,
        padding: EdgeInsets.only(
          left: AppSpacing.xxl,
          right: AppSpacing.xxl,
          top: AppSpacing.sm,
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
        ),
        child: AppButton(
          label: 'Lanjutkan',
          expand: true,
          background: AppColors.accentSoft,
          onPressed: () => _confirm(
            upcomingList: upcomingAsync?.valueOrNull,
            weeklySchedules: weeklySchedules,
          ),
        ),
      ),
    );
  }
}
