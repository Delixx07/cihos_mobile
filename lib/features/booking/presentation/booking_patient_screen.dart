import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../data/patient_repository.dart';
import '../domain/booking.dart';
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
    context.push(AppRoutes.patientType);
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

  void _confirm() {
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

    context.push(
      AppRoutes.bookingSummary,
      extra: widget.booking.copyWith(
        patientName: _patient!.name,
        patientMedicalRecordNumber: _patient!.medicalRecordNumber,
        paymentMethod: _paymentMethod,
        company: _company,
      ),
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
      backgroundColor: AppColors.accentSoft,
      body: Column(
        children: [
          // Top Header (consistent with BookingScheduleScreen)
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
                  Row(
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
                            borderRadius: BorderRadius.circular(10),
                            image: doctor?.photoAsset != null
                                ? DecorationImage(
                                    image: AssetImage(doctor!.photoAsset!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: doctor?.photoAsset == null
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.white,
                                  size: 22,
                                )
                              : null,
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
                      ),
                      if (patients.isNotEmpty)
                        InkWell(
                          onTap: _openAddPatient,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 16,
                                  color: AppColors.accentSoft,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tambah Pasien',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentSoft,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.accentSoft,
                            child: Text(
                              _patient?.name.isNotEmpty == true
                                  ? _patient!.name[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
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
                                          color: AppColors.accentSoft
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _patient!.familyRelation!,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accentSoft,
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Pilih metode penjaminan untuk pendaftaran janji temu ini',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Radio Card: Pribadi (Umum)
                  _PaymentOptionCard(
                    title: 'Pribadi (Umum)',
                    subtitle: 'Pembayaran mandiri',
                    icon: Icons.account_balance_wallet_outlined,
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
                    subtitle: 'Klaim penjaminan via asuransi',
                    icon: Icons.health_and_safety_outlined,
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
          onPressed: _confirm,
        ),
      ),
    );
  }
}

/// Modern Card for Payment Options (Pribadi vs Asuransi)
class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentSoft.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? AppColors.accentSoft : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentSoft
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
              color: isSelected ? AppColors.accentSoft : AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
