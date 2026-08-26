import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/textured_background.dart';
import '../../doctors/data/catalog_repository.dart';
import '../../doctors/data/doctor_repository.dart';
import '../../doctors/domain/clinic.dart';
import '../../doctors/domain/doctor.dart';
import '../../doctors/presentation/widgets/consultation_method_card.dart';
import '../../doctors/presentation/widgets/doctor_picker_sheet.dart';
import '../domain/booking.dart';
import '../widgets/specialty_picker_sheet.dart';

/// Modern booking search screen for Janji Temu & Video Call.
/// Allows selecting Clinic and Doctor, then directly proceeds to consultation method & schedule.
class BookingSearchScreen extends ConsumerStatefulWidget {
  const BookingSearchScreen({super.key, required this.kind});

  final BookingKind kind;

  @override
  ConsumerState<BookingSearchScreen> createState() =>
      _BookingSearchScreenState();
}

class _BookingSearchScreenState extends ConsumerState<BookingSearchScreen> {
  Clinic? _selectedClinic;
  String? _doctorId;
  String? _doctorName;

  Future<void> _pickClinic() async {
    final picked = await showModalBottomSheet<Clinic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpecialtyPickerSheet(selected: _selectedClinic),
    );

    if (picked != null) {
      setState(() {
        _selectedClinic = picked;
        _doctorId = null;
        _doctorName = null;
      });
    }
  }

  Future<void> _pickDoctor() async {
    final picked = await showModalBottomSheet<Doctor>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorPickerSheet(
        unitCode: _selectedClinic?.code,
        selectedId: _doctorId,
      ),
    );

    if (picked == null) return;

    final clinics = ref.read(clinicsProvider).valueOrNull ?? [];
    Clinic? matchedClinic;

    // 1. Coba cocokkan berdasarkan unitCode dokter jika ada
    if (picked.unitCode != null && picked.unitCode!.isNotEmpty) {
      matchedClinic = clinics.cast<Clinic?>().firstWhere(
        (c) => c?.code.toUpperCase() == picked.unitCode!.toUpperCase(),
        orElse: () => null,
      );
    }

    // 2. Jika belum cocok, cocokkan berdasarkan specialty dokter
    if (matchedClinic == null && picked.specialty.isNotEmpty) {
      final spec = picked.specialty.toLowerCase();
      matchedClinic = clinics.cast<Clinic?>().firstWhere((c) {
        if (c == null) return false;
        final dName = c.displayName.toLowerCase();
        final cName = c.name.toLowerCase();
        return dName == spec ||
            cName == spec ||
            spec.contains(dName) ||
            dName.contains(spec) ||
            spec.contains(cName) ||
            cName.contains(spec);
      }, orElse: () => null);
    }

    // 3. Fallback: jika tidak ditemukan di daftar, buat Clinic baru dari data dokter
    matchedClinic ??= Clinic(
      code: picked.unitCode ?? '',
      name: picked.specialty.isNotEmpty ? picked.specialty : 'Klinik Spesialis',
    );

    setState(() {
      _doctorId = picked.id;
      _doctorName = picked.name;
      _selectedClinic = matchedClinic;
    });
  }

  void _reset() {
    setState(() {
      _selectedClinic = null;
      _doctorId = null;
      _doctorName = null;
    });
  }

  void _clearClinic() {
    setState(() {
      _selectedClinic = null;
      _doctorId = null;
      _doctorName = null;
    });
  }

  void _clearDoctor() {
    setState(() {
      _doctorId = null;
      _doctorName = null;
    });
  }

  Future<void> _submit() async {
    if (_doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dokter terlebih dahulu.')),
      );
      return;
    }

    final cachedDoctor = ref.read(doctorByIdProvider(_doctorId!));
    final doctor = cachedDoctor ??
        Doctor(
          id: _doctorId!,
          name: _doctorName ?? '',
          specialty: _selectedClinic?.displayName ?? '',
          unitCode: _selectedClinic?.code,
          methods: const {
            ConsultationMethod.appointment,
            ConsultationMethod.videoCall,
          },
        );

    final method = await showModalBottomSheet<BookingKind>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConsultationMethodSheet(doctor: doctor),
    );

    if (method == null || !mounted) return;

    // Langsung ke pemilihan jadwal dokter tanpa membuka profil dokter
    context.push(
      AppRoutes.bookingSchedule,
      extra: Booking(
        kind: method,
        doctorId: doctor.id,
        doctorName: doctor.name,
        specialty: _selectedClinic?.displayName ?? doctor.specialty,
        unitCode: _selectedClinic?.code ?? doctor.unitCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.kind == BookingKind.videoCall
        ? 'Video Call Dokter'
        : 'Buat Janji Temu';
    final subtitle = widget.kind == BookingKind.videoCall
        ? 'Pilih klinik dan dokter untuk\nkonsultasi video call'
        : 'Pilih klinik dan dokter untuk\nmembuat janji temu';

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 90),
                  child: Image.asset(
                    'assets/images/cari dokter.png',
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _SearchPanel(
                  title: title,
                  subtitle: subtitle,
                  clinic: _selectedClinic?.displayName,
                  doctorName: _doctorName,
                  onClinicTap: _pickClinic,
                  onDoctorTap: _pickDoctor,
                  onClearClinic: _clearClinic,
                  onClearDoctor: _clearDoctor,
                  onReset: _reset,
                  onSubmit: _submit,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: AppBackButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.title,
    required this.subtitle,
    required this.clinic,
    required this.doctorName,
    required this.onClinicTap,
    required this.onDoctorTap,
    required this.onClearClinic,
    required this.onClearDoctor,
    required this.onReset,
    required this.onSubmit,
  });

  final String title;
  final String subtitle;
  final String? clinic;
  final String? doctorName;
  final VoidCallback onClinicTap;
  final VoidCallback onDoctorTap;
  final VoidCallback onClearClinic;
  final VoidCallback onClearDoctor;
  final VoidCallback onReset;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, -6),
            blurRadius: 24,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTypography.headingLg.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _CriteriaRow(
              key: const Key('bookingSearchClinic'),
              label: clinic ?? 'Pilih Klinik',
              isFilled: clinic != null,
              onTap: onClinicTap,
              onClear: onClearClinic,
            ),
            const SizedBox(height: AppSpacing.md),
            _CriteriaRow(
              key: const Key('bookingSearchDoctor'),
              label: doctorName ?? 'Cari Nama Dokter',
              isFilled: doctorName != null,
              onTap: onDoctorTap,
              onClear: onClearDoctor,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: onReset,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Reset',
                                style: AppTypography.bodySm.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x24000000),
                          offset: Offset(0, 4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: onSubmit,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Text(
                            'Lanjutkan',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CriteriaRow extends StatelessWidget {
  const _CriteriaRow({
    super.key,
    required this.label,
    required this.isFilled,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool isFilled;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inputText.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isFilled
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                if (isFilled && onClear != null) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClear,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                const Icon(Icons.expand_more, color: AppColors.textPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
