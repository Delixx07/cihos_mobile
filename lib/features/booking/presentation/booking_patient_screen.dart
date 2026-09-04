import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../data/patient_repository.dart';
import '../domain/booking.dart';
import '../widgets/add_patient_sheet.dart';
import '../widgets/patient_picker_sheet.dart';
import '../../doctors/data/doctor_repository.dart';

/// Modern screen for choosing which patient the booking is for, and how it will be paid.
class BookingPatientScreen extends ConsumerStatefulWidget {
  const BookingPatientScreen({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<BookingPatientScreen> createState() =>
      _BookingPatientScreenState();
}

class _BookingPatientScreenState extends ConsumerState<BookingPatientScreen> {
  BookingPatient? _patient;
  String _paymentMethod = 'Pribadi';
  String? _company;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // If the booking already carried a patient name/mrn, preserve it.
    if (widget.booking.patientName != null) {
      _patient = BookingPatient(
        name: widget.booking.patientName!,
        medicalRecordNumber:
            widget.booking.patientMedicalRecordNumber ?? '-',
      );
    }
  }

  Future<void> _openAddPatient() async {
    // The verified sheet, not the old /patient/type flow — see the note in
    // patient_picker_sheet.dart.
    final added = await AddPatientSheet.show(context);
    if (added != null && mounted) {
      setState(() => _patient = added);
    }
  }

  Future<void> _pickPatient() async {
    final picked = await showModalBottomSheet<BookingPatient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PatientPickerSheet(selected: _patient),
    );

    if (picked != null && mounted) {
      setState(() => _patient = picked);
    }
  }

  Future<void> _confirm() async {
    if (_patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih atau tambahkan data pasien terlebih dahulu.'),
        ),
      );
      return;
    }

    if (_paymentMethod == 'Asuransi/Perusahaan' && _company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih asuransi atau perusahaan penjamin.'),
        ),
      );
      return;
    }

    // If the patient already has a valid MRN (not a temporary APP- one), we can proceed directly.
    if (_patient!.medicalRecordNumber.isNotEmpty && !_patient!.medicalRecordNumber.startsWith('APP-')) {
      _proceedToSummary();
      return;
    }

    if (_patient!.nik == null || _patient!.nik!.isEmpty) {
       // If no NIK and no valid MRN, we can't reliably look them up. 
       // We'll proceed and let the backend handle it (which may result in a new patient or failure).
       _proceedToSummary();
       return;
    }

    setState(() => _isChecking = true);

    try {
      final repo = ref.read(patientRepositoryProvider);
      final result = await repo.checkPatientLink(
        nik: _patient!.nik!,
        name: _patient!.name,
        phone: _patient!.phone ?? '',
        dob: _patient!.birthDate,
      );

      if (!mounted) return;

      if (result.status == LinkStatus.ambiguous) {
        _showAmbiguousDialog();
      } else if (result.status == LinkStatus.found && result.medicalNo != null) {
        // If it's the main account holder ("Diri Sendiri"), auto-link without prompt
        if (_patient!.familyRelation == 'Diri Sendiri') {
          await _saveLinkedPatient(result.medicalNo!);
          _proceedToSummary();
        } else {
          // Show confirmation bottom sheet for family member
          _showLinkConfirmationSheet(result);
        }
      } else if (_patient!.familyRelation == 'Diri Sendiri') {
        // The account holder can go on: MEDINFRAS registers them from the
        // account's own NIK on their first booking.
        _proceedToSummary();
      } else {
        // A relative who is not in MEDINFRAS cannot be registered from here.
        // The API refuses it on purpose — guessing once created duplicate
        // records for people who were already registered.
        _showNotRegisteredSheet();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.isNetwork
                ? 'Tidak dapat memeriksa data pasien. Periksa jaringan Anda, '
                      'lalu coba lagi.'
                : e.message,
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _proceedToSummary() {
    context.push(
      AppRoutes.bookingSummary,
      extra: widget.booking.copyWith(
        patientName: _patient!.name,
        patientMedicalRecordNumber: _patient!.medicalRecordNumber,
        patientNik: _patient!.nik,
        patientPhone: _patient!.phone,
        patientBirthDate: _patient!.birthDate,
        patientGender: _patient!.gender,
        patientFamilyId: _patient!.familyId,
        patientRelation: _patient!.familyRelation,
        paymentMethod: _paymentMethod,
        company: _company,
      ),
    );
  }

  Future<void> _saveLinkedPatient(String newMedicalNo) async {
    final updatedPatient = _patient!.copyWith(medicalRecordNumber: newMedicalNo);
    await ref.read(registeredPatientsProvider.notifier).addPatient(updatedPatient);
    setState(() => _patient = updatedPatient);
  }

  /// Explains that a relative has to be registered at the hospital first.
  ///
  /// Deliberately a dead end rather than a "continue anyway": the API will not
  /// create a record for them, and letting the patient walk further into the
  /// booking flow would only fail later with a less clear message.
  void _showNotRegisteredSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.xl,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  size: 32,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Pasien Belum Terdaftar',
                textAlign: TextAlign.center,
                style: AppTypography.headingSm.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${_patient?.name ?? 'Pasien ini'} belum memiliki rekam medis '
                'di Ciputra Hospital Surabaya. Pendaftaran pasien baru harus '
                'dilakukan langsung di rumah sakit.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.accentSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Mengerti',
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w800,
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

  void _showAmbiguousDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data Ganda / Tidak Pasti', style: TextStyle(color: AppColors.danger)),
        content: const Text(
          'Data pasien dengan NIK ini belum dapat dipastikan karena terdapat kemiripan data ganda di sistem rumah sakit.\n\n'
          'Untuk menjaga keamanan rekam medis, mohon lakukan pendaftaran atau verifikasi manual di meja pendaftaran Rumah Sakit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(color: AppColors.accentSoft)),
          ),
        ],
      ),
    );
  }

  void _showLinkConfirmationSheet(PatientLinkResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Mask the MRN for privacy e.g. 010304596 -> ******596
        final rawMrn = result.medicalNo ?? '';
        final maskedMrn = rawMrn.length > 3 
            ? '${'*' * (rawMrn.length - 3)}${rawMrn.substring(rawMrn.length - 3)}' 
            : rawMrn;
        
        // Mask the name e.g. SITI AMINAH -> SITI A*****
        final rawName = result.matchedName ?? 'Pasien';
        final nameParts = rawName.split(' ');
        final maskedName = nameParts.length > 1 
            ? '${nameParts[0]} ${nameParts[1].substring(0, 1)}${'*' * (nameParts[1].length - 1)}'
            : '$rawName***';

        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.paddingOf(ctx).bottom + 24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Konfirmasi Pasien',
                style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'Sistem rumah sakit mendeteksi ada rekam medis yang sudah cocok dengan NIK keluarga Anda:',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentSoft.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(maskedName, style: AppTypography.titleMd.copyWith(color: AppColors.accentSoft)),
                    const SizedBox(height: 4),
                    Text('No. RM: $maskedMrn', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                    if (result.matchedDob != null) ...[
                      const SizedBox(height: 4),
                      Text('Tgl Lahir: ${result.matchedDob}', style: AppTypography.bodySm),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Apakah ini benar pasien yang dimaksud?',
                style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Bukan', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _saveLinkedPatient(result.medicalNo!);
                        _proceedToSummary();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentSoft,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Ya, Lanjutkan', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(registeredPatientsProvider);

    // Auto-select if there is only 1 patient and nothing selected yet
    if (_patient == null && patients.isNotEmpty) {
      _patient = patients.first;
    } else if (_patient != null &&
        !patients.any((p) =>
            p.medicalRecordNumber == _patient!.medicalRecordNumber &&
            p.name == _patient!.name)) {
      _patient = patients.isNotEmpty ? patients.first : null;
    }

    final doctor = widget.booking.doctorId != null
        ? ref.watch(doctorByIdProvider(widget.booking.doctorId!))
        : null;

    final isAppointment = widget.booking.kind == BookingKind.appointment;
    final isInsurance = _paymentMethod == 'Asuransi/Perusahaan';

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
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Pilih Pasien',
                        style: AppTypography.headingMd.copyWith(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Mini Doctor & Date Context Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: doctor?.photoAsset == null
                                ? const Icon(
                                    Icons.person,
                                    color: AppColors.white,
                                    size: 22,
                                  )
                                : Image.asset(
                                    doctor!.photoAsset!,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                      Icons.person,
                                      color: AppColors.white,
                                      size: 22,
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
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${isAppointment ? 'Janji Temu' : 'Video Call'}'
                                '${widget.booking.date != null ? ' • ${DateFormat('d MMM yyyy', 'id_ID').format(widget.booking.date!)}' : ''}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.lavender,
                                  fontSize: 11,
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
          ),

          // White Content Area
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
                  // Section: Pasien
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pasien yang Berobat',
                        style: AppTypography.inputText.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Patient Selection Box
                  if (patients.isEmpty)
                    // Empty state card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.accentSoft.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 32,
                              color: AppColors.accentSoft,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Belum Ada Data Pasien',
                            style: AppTypography.inputText.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Akun Anda belum memiliki data pasien terdaftar. Silakan tambahkan data pasien terlebih dahulu.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: '+ Tambah Pasien Baru',
                            background: AppColors.accentSoft,
                            expand: true,
                            onPressed: _openAddPatient,
                          ),
                        ],
                      ),
                    )
                  else
                    // Active Selected Patient Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.accentSoft.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentSoft.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
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
                                _patient?.name.isNotEmpty == true
                                    ? _patient!.name[0].toUpperCase()
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _patient?.name ?? 'Pilih Pasien',
                                        style:
                                            AppTypography.inputText.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_patient?.familyRelation != null &&
                                        _patient!.familyRelation!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
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
                                        child: Text(
                                          _patient!.familyRelation!,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF166534),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.badge_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'No. RM: ${_patient?.medicalRecordNumber ?? '-'}',
                                      style: AppTypography.bodySm.copyWith(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.accentSoft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xs),
                                side: const BorderSide(
                                  color: AppColors.accentSoft,
                                ),
                              ),
                            ),
                            onPressed: _pickPatient,
                            child: const Text(
                              'Ganti',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Section: Jenis Jaminan
                  Text(
                    'Jenis Jaminan / Pembayaran',
                    style: AppTypography.inputText.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Radio Card: Pribadi (Umum)
                  _PaymentOptionCard(
                    title: 'Pribadi (Umum)',
                    subtitle: 'Pembayaran mandiri',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: const Color(0xFF0284C7),
                    selectedBgColor: const Color(0xFFF0F9FF),
                    isSelected: _paymentMethod == 'Pribadi',
                    onTap: () => setState(() {
                      _paymentMethod = 'Pribadi';
                      _company = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Radio Card: Asuransi / Perusahaan
                  _PaymentOptionCard(
                    title: 'Asuransi / Perusahaan',
                    subtitle: 'Klaim penjaminan via asuransi rekanan',
                    icon: Icons.health_and_safety_rounded,
                    accentColor: const Color(0xFFD97706),
                    selectedBgColor: const Color(0xFFFFFBEB),
                    isSelected: _paymentMethod == 'Asuransi/Perusahaan',
                    onTap: () => setState(() {
                      _paymentMethod = 'Asuransi/Perusahaan';
                    }),
                  ),

                  // Dropdown if Asuransi is chosen
                  if (isInsurance) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.accentSoft.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Asuransi / Perusahaan Rekanan *',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<String>(
                            value: _company,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Pilih Asuransi atau Perusahaan',
                              hintStyle: AppTypography.inputText.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.business_rounded,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: AppColors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                borderSide: const BorderSide(
                                  color: AppColors.accentSoft,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            style: AppTypography.inputText.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            items: BookingOptions.companies.map((comp) {
                              return DropdownMenuItem(
                                value: comp,
                                child: Text(comp),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _company = val),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Guide Bar
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentSoft.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.accentSoft,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Pastikan data pasien dan penjamin sesuai dengan identitas resmi untuk kelancaran administrasi RS.',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
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
        child: _isChecking
            ? const Center(child: CircularProgressIndicator(color: AppColors.accentSoft))
            : AppButton(
                label: 'Lanjutkan',
                expand: true,
                background: AppColors.accentSoft,
                onPressed: _confirm,
              ),
      ),
    );
  }
}

/// Modern Card for Payment Options (Pribadi vs Asuransi) with colorful accents
class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.accentColor = AppColors.accentSoft,
    this.selectedBgColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;
  final Color? selectedBgColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = isSelected
        ? (selectedBgColor ?? accentColor.withValues(alpha: 0.08))
        : AppColors.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : AppColors.textSecondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.inputText.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? accentColor : AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
