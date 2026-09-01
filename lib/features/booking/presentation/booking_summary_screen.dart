import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../doctors/data/doctor_repository.dart';
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

      final bookingCode =
          await ref.read(bookingRepositoryProvider).create(widget.booking);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final destination = await showModalBottomSheet<BookingSuccessAction>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BookingSuccessSheet(bookingCode: bookingCode),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat janji temu: ${e.toString()}'),
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
                        'Ringkasan Janji Temu',
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
                        // Location Card with rich blue/teal styling
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color.fromARGB(255, 139, 139, 139),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0D9488),
                                      Color(0xFF14B8A6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0D9488)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_hospital_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'LOKASI PELAYANAN',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: const Color(0xFF0F766E),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Surabaya Barat',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF166534),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Ciputra Hospital Surabaya',
                                      style: AppTypography.inputText.copyWith(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Main Booking Summary Card
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Method Badge + Edit Button
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  10,
                                  AppSpacing.sm,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: isVideoCall
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFF0FDFA),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isVideoCall
                                          ? const Color(0xFFA7F3D0)
                                          : const Color(0xFF99F6E4),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isVideoCall
                                            ? const Color(0xFF059669)
                                            : const Color(0xFF0D9488),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isVideoCall
                                            ? Icons.videocam_rounded
                                            : Icons.medical_services_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isVideoCall
                                          ? 'Video Call Dokter'
                                          : 'Janji Temu Rumah Sakit',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: isVideoCall
                                            ? const Color(0xFF065F46)
                                            : const Color(0xFF115E59),
                                      ),
                                    ),
                                    const Spacer(),
                                    // Styled Ubah Button
                                    InkWell(
                                      key: const Key('summaryEdit'),
                                      onTap: _edit,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.accentSoft
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 13,
                                              color: AppColors.accentSoft,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Ubah',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.accentSoft,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Patient Row with Colorful Avatar
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF4F46E5),
                                                Color(0xFF6366F1),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              (widget.booking.patientName
                                                          ?.isNotEmpty ==
                                                      true)
                                                  ? widget.booking
                                                      .patientName![0]
                                                      .toUpperCase()
                                                  : 'P',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 18,
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
                                                widget.booking.patientName ??
                                                    'Pasien',
                                                style: AppTypography.inputText
                                                    .copyWith(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  (widget.booking
                                                              .patientMedicalRecordNumber
                                                              ?.isNotEmpty ==
                                                          true)
                                                      ? 'No. RM: ${widget.booking.patientMedicalRecordNumber}'
                                                      : 'Pasien Terdaftar',
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: AppSpacing.md),
                                    const Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                    const SizedBox(height: AppSpacing.md),

                                    // Doctor & Specialty Row
                                    Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.white,
                                            border: Border.all(
                                              color: const Color(0xFF14B8A6),
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: doctor?.photoAsset == null
                                                ? const Icon(
                                                    Icons.person_rounded,
                                                    size: 28,
                                                    color:
                                                        AppColors.textTertiary,
                                                  )
                                                : Image.asset(
                                                    doctor!.photoAsset!,
                                                    width: 52,
                                                    height: 52,
                                                    fit: BoxFit.cover,
                                                    alignment:
                                                        Alignment.topCenter,
                                                    errorBuilder:
                                                        (_, _, _) => const Icon(
                                                      Icons.person_rounded,
                                                      size: 28,
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
                                              const SizedBox(height: 4),
                                              Text(
                                                (widget.booking.specialty ??
                                                        'Spesialis')
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0284C7),
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: AppSpacing.md),
                                    const Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                    const SizedBox(height: AppSpacing.md),

                                    // 2-Column Info Grid: [Tanggal] & [Metode Pembayaran] (Replaces Jam)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Column 1: Tanggal (Warm Amber Card)
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFFBEB),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFFFDE68A),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .calendar_today_rounded,
                                                      size: 14,
                                                      color: Color(0xFFD97706),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      'Tanggal',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xFF92400E),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  widget.booking.date != null
                                                      ? DateFormat(
                                                          'd MMM yyyy',
                                                          'id_ID',
                                                        ).format(
                                                          widget.booking.date!,
                                                        )
                                                      : '-',
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        // Column 2: Metode Pembayaran (Emerald Card - Replaces Jam)
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFFA7F3D0),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .account_balance_wallet_rounded,
                                                      size: 14,
                                                      color: Color(0xFF059669),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      'Pembayaran',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xFF065F46),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  widget.booking.company !=
                                                              null &&
                                                          widget
                                                              .booking
                                                              .company!
                                                              .isNotEmpty
                                                      ? widget.booking.company!
                                                      : (widget.booking
                                                              .paymentMethod ??
                                                          'Pribadi (Umum)'),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        AppColors.textPrimary,
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
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Add Another Booking Button with fresh teal theme
                        InkWell(
                          onTap: _addAnotherBooking,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF14B8A6),
                                width: 1.3,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0D9488),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tambah ${widget.booking.kind.label}',
                                  style: AppTypography.inputText.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F766E),
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
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 12,
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
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentSoft,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: AppColors.accentSoft
                                    .withValues(alpha: 0.4),
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
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Konfirmasi Janji Temu',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
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
            ),
          ),
        ],
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
