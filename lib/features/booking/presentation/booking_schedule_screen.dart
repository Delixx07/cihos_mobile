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

  /// Whether the chosen date still has a bookable session left.
  ///
  /// The patient does not pick a queue number — the hospital assigns it. This
  /// only gates "Lanjutkan" so nobody walks into the summary screen for a day
  /// that is already full or over.
  bool _hasBookableSession = false;

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

    if (!_hasBookableSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada jadwal tersisa pada tanggal ini. '
              'Silakan pilih tanggal lain.'),
        ),
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
        // Session and slot_no are deliberately not set: the hospital assigns
        // the queue number at booking time. See docs/PROMPT_BACKEND_SLOT_TIME.md
      ),
    );
  }

  /// Confirms the chosen day without making the patient scroll for it.
  Future<void> _showDaySheet(
    DateTime date,
    UpcomingScheduleDate? schedule,
  ) async {
    final unitCode =
        (schedule?.unitCode.isNotEmpty == true ? schedule!.unitCode : null) ??
        widget.booking.unitCode;

    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DaySheet(
        date: date,
        timeLabel: schedule?.timeLabel ?? '',
        doctorId: widget.booking.doctorId,
        unitCode: unitCode,
        onAvailability: (available) {
          if (!mounted || _hasBookableSession == available) return;
          setState(() => _hasBookableSession = available);
        },
      ),
    );

    if (proceed != true || !mounted) return;
    _confirm(
      upcomingList: ref
          .read(
            upcomingSchedulesProvider(
              UpcomingScheduleQuery(
                doctorId: widget.booking.doctorId!,
                unitCode: widget.booking.unitCode,
                days: 30,
              ),
            ),
          )
          .valueOrNull,
      weeklySchedules:
          ref
              .read(doctorSchedulesProvider(widget.booking.doctorId!))
              .valueOrNull ??
          const [],
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
    // sometimes omits these fields. /app/schedule reliably includes them.
    final weeklySchedulesAsync = widget.booking.doctorId != null
        ? ref.watch(doctorSchedulesProvider(widget.booking.doctorId!))
        : null;
    final weeklySchedules = weeklySchedulesAsync?.valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Header Linear Gradient (0% #003366 to 100% #0047AB)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 260,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF003366), // 0%
                    Color(0xFF0047AB), // 100%
                  ],
                ),
              ),
            ),
          ),

          // Foreground Content
          Column(
            children: [
              // Doctor Info Header Controls
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.sm,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  IconButton(
                    tooltip: 'Kembali',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
                        // Availability is per date; re-checked for the new one.
                        _hasBookableSession = false;
                      });
                      // The calendar fills the screen, so the summary below it
                      // sits off-screen and the patient never sees what they
                      // just picked. Bring it to them instead.
                      _showDaySheet(value, matched);
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
                    // A compact echo of what the sheet confirmed, so the choice
                    // stays visible after the sheet closes. Tapping reopens it.
                    Material(
                      color: AppColors.mint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            _showDaySheet(_date!, selectedSchedule),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accentSoft,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_available_rounded,
                                color: AppColors.accentSoft,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'EEEE, d MMMM yyyy',
                                        'id_ID',
                                      ).format(_date!),
                                      style: AppTypography.bodySm.copyWith(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (selectedSchedule != null &&
                                        selectedSchedule.timeLabel.isNotEmpty)
                                      Text(
                                        'Jam Praktek: '
                                        '${selectedSchedule.timeLabel}',
                                        style: AppTypography.bodySm.copyWith(
                                          fontSize: 12,
                                          color: AppColors.link,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
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

/// Lets the patient take one of the queue numbers still free that day.
///
/// The hospital books by queue position inside a practice session, not by a
/// fifteen-minute appointment, so each option is a number plus the session's
/// hours. `slot_no` is mandatory when booking and the API picks nothing on the
/// patient's behalf, which is why this step cannot be skipped.
/// Shows which practice sessions still have room on the chosen date.
///
/// Read-only on purpose: the patient does not choose a queue number — the
/// hospital assigns it when the booking is made. This exists so the patient
/// knows the day is actually bookable (and roughly when they will be seen)
/// before continuing, and so a full or finished day is caught here rather
/// than after they have filled in the rest of the form.
class _SessionAvailability extends ConsumerWidget {
  const _SessionAvailability({
    required this.doctorId,
    required this.unitCode,
    required this.date,
    required this.onAvailability,
  });

  final String? doctorId;
  final String? unitCode;
  final DateTime date;

  /// Reports whether any session is still bookable, so the screen can enable
  /// or block "Lanjutkan".
  final ValueChanged<bool> onAvailability;

  /// Reports availability after the current frame.
  ///
  /// Every call site below sits inside `build`, and the parent answers by
  /// calling setState — which Flutter rejects mid-build. Deferring by one
  /// frame keeps the report without the rebuild-during-build error.
  void _report(bool available) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onAvailability(available);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (doctorId == null || unitCode == null || unitCode!.isEmpty) {
      _report(false);
      return const _Notice(
        message: 'Klinik dokter belum diketahui, jadi jadwal tidak bisa '
            'dimuat. Silakan pilih ulang dokter.',
        color: AppColors.danger,
      );
    }

    final slotsAsync = ref.watch(
      slotsProvider(
        SlotQuery(doctorId: doctorId!, unitCode: unitCode!, date: date),
      ),
    );

    return slotsAsync.when(
      loading: () {
        _report(false);
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        );
      },
      error: (_, _) {
        _report(false);
        return const _Notice(
          message: 'Gagal memuat jadwal. Periksa jaringan Anda, lalu pilih '
              'ulang tanggalnya.',
          color: AppColors.danger,
        );
      },
      data: (daySlots) {
        final now = DateTime.now();
        // A session that already finished today cannot be booked into.
        final sessions = daySlots.sessions
            .where((s) => !s.hasEndedOn(date, now))
            .toList();

        _report(sessions.isNotEmpty);

        if (sessions.isEmpty) {
          return _Notice(
            message: daySlots.isEmpty
                ? 'Antrean untuk tanggal ini sudah penuh. Silakan pilih '
                    'tanggal lain.'
                : 'Jadwal praktik hari ini sudah berakhir. Silakan pilih '
                    'tanggal lain.',
            color: AppColors.danger,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jadwal Tersedia',
              style: AppTypography.bodySm.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Nomor antrean Anda ditentukan otomatis oleh rumah sakit '
              'setelah janji temu dikonfirmasi.',
              style: AppTypography.bodySm.copyWith(
                fontSize: 12,
                height: 1.3,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final session in sessions) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: AppColors.accentSoft,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sessions.length > 1
                                ? 'Sesi ${session.session} · ${session.timeLabel}'
                                : session.timeLabel,
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${session.slots.length} antrean tersisa',
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
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: AppTypography.bodySm.copyWith(
          fontSize: 13,
          height: 1.3,
          color: color,
        ),
      ),
    );
  }
}

/// Confirms the chosen day, with the sessions still open on it.
///
/// Shown as a sheet because the calendar takes the whole screen: the same
/// information rendered underneath it would sit below the fold, and patients
/// would tap "Lanjutkan" without ever seeing which session they were getting.
class _DaySheet extends StatelessWidget {
  const _DaySheet({
    required this.date,
    required this.timeLabel,
    required this.doctorId,
    required this.unitCode,
    required this.onAvailability,
  });

  final DateTime date;
  final String timeLabel;
  final String? doctorId;
  final String? unitCode;
  final ValueChanged<bool> onAvailability;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: AppColors.accentSoft,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Dipilih',
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(date),
                          style: AppTypography.headingSm.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (timeLabel.isNotEmpty)
                          Text(
                            'Jam Praktek: $timeLabel',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.link,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SessionAvailability(
                doctorId: doctorId,
                unitCode: unitCode,
                date: date,
                onAvailability: onAvailability,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        // Comfortably above the 48dp floor: many patients here
                        // are elderly.
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Ganti Tanggal',
                        style: AppTypography.bodySm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.accentSoft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Lanjutkan',
                        style: AppTypography.bodySm.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
