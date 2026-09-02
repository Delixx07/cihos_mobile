import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/application/auth_controller.dart';
import '../../doctors/data/catalog_repository.dart';
import '../../doctors/data/doctor_repository.dart';
import '../../doctors/domain/practice_schedule.dart';
import '../../schedule/data/schedule_repository.dart';
import '../data/booking_repository.dart';
import '../domain/booking.dart';
import '../widgets/booking_success_sheet.dart';
import '../widgets/edit_booking_sheet.dart';

/// Final review screen before the booking is confirmed and sent to backend.
/// Designed with rich color variations, clear information hierarchy, and no time/hour display.
class BookingSummaryScreen extends ConsumerStatefulWidget {
  const BookingSummaryScreen({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<BookingSummaryScreen> createState() =>
      _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  Future<void> _edit() async {
    final choice = await showModalBottomSheet<EditBookingChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditBookingSheet(),
    );

    if (choice == null || !mounted) return;

    switch (choice) {
      case EditBookingChoice.doctor:
        // Navigasi kembali ke pencarian dokter
        context.push(
          widget.booking.kind == BookingKind.videoCall
              ? AppRoutes.videoCallSearch
              : AppRoutes.appointmentSearch,
        );
      case EditBookingChoice.schedule:
        // Kembali ke pemilihan tanggal
        if (Navigator.of(context).canPop()) {
          context.pop(); // pop summary -> patient
          if (Navigator.of(context).canPop()) {
            context.pop(); // pop patient -> schedule
          }
        } else {
          context.push(AppRoutes.bookingSchedule, extra: widget.booking);
        }
      case EditBookingChoice.patient:
        // Kembali ke pemilihan pasien
        if (Navigator.of(context).canPop()) {
          context.pop(); // pop summary -> patient
        } else {
          context.push(AppRoutes.bookingPatient, extra: widget.booking);
        }
    }
  }

  Future<void> _addAnotherBooking() async {
    await context.push(
      widget.booking.kind == BookingKind.videoCall
          ? AppRoutes.videoCallSearch
          : AppRoutes.appointmentSearch,
      extra: true, // isAddingAnother flag
    );
  }

  Future<void> _submit() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan setujui Syarat & Ketentuan untuk melanjutkan.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Debug: log booking fields to flutter console so we can trace what
      // values are being sent to the API.
      // ignore: avoid_print
      print('[BookingSummary] submitting booking: '
          'unitCode=${widget.booking.unitCode}, '
          'paramedicCode=${widget.booking.paramedicCode}, '
          'doctorId=${widget.booking.doctorId}, '
          'operationalTimeCode=${widget.booking.operationalTimeCode}, '
          'date=${widget.booking.date}');

      final result =
          await ref.read(bookingRepositoryProvider).create(widget.booking);

      // The new appointment belongs in Jadwal Temu, and a first booking makes
      // MEDINFRAS issue the account's real MRN in place of its temporary
      // APP-XXXXXX one — both are only visible after a refetch.
      ref.invalidate(appointmentsProvider);
      await ref.read(authControllerProvider.notifier).restoreSession();

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final destination = await showModalBottomSheet<BookingSuccessAction>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BookingSuccessSheet(result: result),
      );

      if (!mounted) return;
      context.go(
        destination == BookingSuccessAction.viewHistory
            ? AppRoutes.appointments
            : AppRoutes.home,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      // ApiException messages are already written in Indonesian by the server;
      // anything else would leak Dart type names at the patient.
      final message = switch (e) {
        ApiException(code: 'no_slot_available') =>
          'Antrean untuk tanggal ini sudah penuh atau jadwal praktiknya sudah '
              'berakhir. Silakan pilih tanggal lain.',
        ApiException(code: 'slot_taken' || 'slot_reserved') =>
          'Antrean baru saja diambil pasien lain. Silakan coba lagi.',
        ApiException(code: 'duplicate_appointment') =>
          'Anda sudah memiliki janji temu dengan dokter ini pada tanggal '
              'tersebut.',
        ApiException(code: 'holiday') =>
          'Tanggal tersebut adalah hari libur. Silakan pilih tanggal lain.',
        ApiException(code: 'on_leave') =>
          'Dokter sedang tidak praktik pada tanggal tersebut.',
        final ApiException api => api.message,
        _ => 'Gagal membuat janji temu. Silakan coba lagi.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.booking.doctorId != null
        ? ref.watch(doctorByIdProvider(widget.booking.doctorId!))
        : null;

    final isVideoCall = widget.booking.kind == BookingKind.videoCall;

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

    final matchedUpcoming = widget.booking.date == null
        ? null
        : upcomingAsync?.valueOrNull?.cast<UpcomingScheduleDate?>().firstWhere(
            (s) =>
                s != null &&
                s.date.year == widget.booking.date!.year &&
                s.date.month == widget.booking.date!.month &&
                s.date.day == widget.booking.date!.day,
            orElse: () => null,
          );

    final resolvedPracticeTime =
        (widget.booking.practiceTime?.isNotEmpty == true)
            ? widget.booking.practiceTime
            : (matchedUpcoming?.timeLabel.isNotEmpty == true
                ? matchedUpcoming!.timeLabel
                : null);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Header Linear Gradient (0% #003366 to 100% #0047AB)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
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
              // Top Header Controls
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.sm,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text(
                        isVideoCall
                            ? 'Ringkasan Video Call'
                            : 'Ringkasan Janji Temu',
                        style: AppTypography.headingMd.copyWith(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Main Continuous White Content Area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Scrollable Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                        AppSpacing.lg,
                      ),
                      children: [
                        // Main Booking Summary Card
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Section: Consultation Method Badge + Ubah Button + Doctor Info
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Method Badge + Ubah Button
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 3.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isVideoCall
                                                ? const Color(0xFFECFDF5)
                                                : const Color(0xFFEFF6FF),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isVideoCall
                                                  ? const Color(0xFFA7F3D0)
                                                  : const Color(0xFFBFDBFE),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isVideoCall
                                                    ? Icons.videocam_rounded
                                                    : Icons.medical_services_rounded,
                                                size: 13,
                                                color: isVideoCall
                                                    ? const Color(0xFF059669)
                                                    : const Color(0xFF2563EB),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                isVideoCall
                                                    ? 'Video Call Dokter'
                                                    : 'Janji Temu Rumah Sakit',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: isVideoCall
                                                      ? const Color(0xFF065F46)
                                                      : const Color(0xFF1D4ED8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        InkWell(
                                          key: const Key('summaryEdit'),
                                          onTap: _edit,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFFBFDBFE),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.edit_outlined,
                                                  size: 12,
                                                  color: Color(0xFF2563EB),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Ubah',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: Color(0xFF1D4ED8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: AppSpacing.md),

                                    // Doctor Row & Hospital
                                    Row(
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFF1F5F9),
                                            border: Border.all(
                                              color: const Color(0xFFBAE6FD),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: doctor?.photoAsset == null
                                                ? const Icon(
                                                    Icons.person_rounded,
                                                    size: 24,
                                                    color: AppColors
                                                        .textTertiary,
                                                  )
                                                : Image.asset(
                                                    doctor!.photoAsset!,
                                                    width: 46,
                                                    height: 46,
                                                    fit: BoxFit.cover,
                                                    alignment:
                                                        Alignment.topCenter,
                                                    errorBuilder:
                                                        (_, _, _) =>
                                                            const Icon(
                                                      Icons.person_rounded,
                                                      size: 24,
                                                      color: AppColors
                                                          .textTertiary,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.booking.doctorName ??
                                                    '-',
                                                style: AppTypography.inputText
                                                    .copyWith(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                widget.booking.specialty ??
                                                    'Dokter Spesialis',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      const Color(0xFF0284C7),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.local_hospital_rounded,
                                                    size: 13,
                                                    color: Color(0xFFEF4444),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Ciputra Hospital Surabaya',
                                                    style: AppTypography
                                                        .caption
                                                        .copyWith(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const Divider(height: 1, color: AppColors.border),

                              // Detail Section: Direct line items (NO individual container boxes)
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  children: [
                                    // 1. Jadwal & Jam Praktek
                                    _SummaryLineItem(
                                      icon: Icons.event_available_rounded,
                                      iconColor: const Color(0xFF2563EB),
                                      iconBgColor: const Color(0xFFEFF6FF),
                                      primaryText: widget.booking.date != null
                                          ? DateFormat(
                                              'EEEE, d MMMM yyyy',
                                              'id_ID',
                                            ).format(widget.booking.date!)
                                          : '-',
                                      extra: (resolvedPracticeTime != null &&
                                              resolvedPracticeTime.isNotEmpty)
                                          ? Container(
                                              margin:
                                                  const EdgeInsets.only(top: 4),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 2.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.access_time_rounded,
                                                    size: 12,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Praktek: $resolvedPracticeTime',
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF1D4ED8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : null,
                                    ),

                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(
                                        height: 1,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                    ),

                                    // 2. Pasien (Kiri) & Pembayaran (Kanan) dalam 1 Row
                                    IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Kolom Kiri: Pasien
                                          Expanded(
                                            child: _SummaryLineItem(
                                              icon: Icons.person_rounded,
                                              iconColor:
                                                  const Color(0xFF7C3AED),
                                              iconBgColor:
                                                  const Color(0xFFF5F3FF),
                                              primaryText: widget
                                                      .booking.patientName ??
                                                  'Pasien',
                                              secondaryText: (widget
                                                              .booking
                                                              .patientMedicalRecordNumber
                                                              ?.isNotEmpty ==
                                                          true)
                                                  ? 'No. RM: ${widget.booking.patientMedicalRecordNumber}'
                                                  : (widget
                                                          .booking.isNewPatient
                                                      ? 'Pasien Baru'
                                                      : 'Pasien Terdaftar'),
                                            ),
                                          ),

                                          // Garis Pembatas Vertikal Halus
                                          Container(
                                            width: 1,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                            ),
                                            color: const Color(0xFFF1F5F9),
                                          ),

                                          // Kolom Kanan: Pembayaran
                                          Expanded(
                                            child: _SummaryLineItem(
                                              icon: Icons
                                                  .account_balance_wallet_rounded,
                                              iconColor:
                                                  const Color(0xFF059669),
                                              iconBgColor:
                                                  const Color(0xFFECFDF5),
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              primaryText: (widget.booking
                                                              .company
                                                              ?.isNotEmpty ==
                                                          true)
                                                  ? widget.booking.company!
                                                  : (widget.booking
                                                          .paymentMethod ??
                                                      'Pribadi'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Add Another Booking Button
                        InkWell(
                          onTap: _addAnotherBooking,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFBAE6FD),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0284C7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tambah ${widget.booking.kind.label}',
                                  style: AppTypography.inputText.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0369A1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Anda dapat membuat lebih dari 1 janji temu sebelum konfirmasi.',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Confirmation Panel (Integrated inside same white sheet)
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.sm,
                      AppSpacing.xxl,
                      AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TermsCheckbox(
                            value: _agreedToTerms,
                            onChanged: (val) =>
                                setState(() => _agreedToTerms = val),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // Confirm Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF003366), Color(0xFF0047AB)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0047AB)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _isSubmitting ? null : _submit,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isVideoCall
                                                ? 'Konfirmasi Video Call'
                                                : 'Konfirmasi Janji Temu',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
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
        ],
      ),
    ],
  ),
);
}
}

class _SummaryLineItem extends StatelessWidget {
  const _SummaryLineItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.primaryText,
    this.secondaryText,
    this.extra,
    this.crossAxisAlignment,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String primaryText;
  final String? secondaryText;
  final Widget? extra;
  final CrossAxisAlignment? crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final isSingleLine =
        (secondaryText == null || secondaryText!.isEmpty) && extra == null;
    final effectiveCrossAxis = crossAxisAlignment ??
        (isSingleLine
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start);

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: effectiveCrossAxis,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 17,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inputText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (secondaryText != null && secondaryText!.isNotEmpty) ...[
                  const SizedBox(height: 1.5),
                  Text(
                    secondaryText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                ?extra,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('summaryTerms'),
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                value
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: value ? AppColors.accentSoft : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                  children: const [
                    TextSpan(text: 'Saya telah memeriksa dan menyetujui '),
                    TextSpan(
                      text: 'Syarat & Ketentuan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: ' yang berlaku.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
