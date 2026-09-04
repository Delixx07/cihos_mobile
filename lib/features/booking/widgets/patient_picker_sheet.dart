import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/application/auth_controller.dart';
import '../data/patient_repository.dart';
import 'add_patient_sheet.dart';
import '../domain/booking.dart';
import '../../patient_registration/domain/patient_draft.dart';

/// Clean & modern searchable sheet for selecting or managing patients.
/// Keyboard-safe with DraggableScrollableSheet and instant 1-tap selection.
class PatientPickerSheet extends ConsumerStatefulWidget {
  const PatientPickerSheet({super.key, this.selected});

  final BookingPatient? selected;

  @override
  ConsumerState<PatientPickerSheet> createState() => _PatientPickerSheetState();
}

class _PatientPickerSheetState extends ConsumerState<PatientPickerSheet> {
  final _searchController = TextEditingController();
  late BookingPatient? _selected = widget.selected;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddPatient() async {
    // Goes to the sheet that verifies the NIK against MEDINFRAS, not the old
    // /patient/type flow: that one invented a record number from a timestamp
    // and never called the API, so every patient added through it carried a
    // number the hospital had never issued.
    final added = await AddPatientSheet.show(context);
    if (added != null && mounted) {
      setState(() => _selected = added);
    }
  }

  /// Lets the patient correct a relation they set wrongly.
  ///
  /// Only the label changes — the person's medical record is untouched, so
  /// this never needs to go back through the NIK lookup.
  Future<void> _editRelation(BookingPatient patient) async {
    final options = PatientOptions.familyRelations
        .where((rel) => rel != 'Diri Sendiri')
        .toList();

    final chosen = await showModalBottomSheet<String>(
      context: context,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hubungan dengan ${patient.name}',
                style: AppTypography.headingSm.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final rel in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(rel, style: AppTypography.inputText),
                  trailing: patient.familyRelation == rel
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.accentSoft,
                          size: 20,
                        )
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(rel),
                ),
            ],
          ),
        ),
      ),
    );

    if (chosen == null || chosen == patient.familyRelation || !mounted) return;

    await ref
        .read(registeredPatientsProvider.notifier)
        .updateRelation(patient, chosen);
  }

  Future<void> _confirmDeletePatient(BookingPatient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Hapus Pasien?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Hapus data pasien "${patient.displayName}" dari daftar akun Anda?',
          style: AppTypography.bodySm.copyWith(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(registeredPatientsProvider.notifier)
          .removePatient(patient);
      if (_selected == patient ||
          (_selected?.medicalRecordNumber == patient.medicalRecordNumber &&
              _selected?.name == patient.name)) {
        setState(() => _selected = null);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data "${patient.name}" berhasil dihapus.'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPatients = ref.watch(registeredPatientsProvider);
    final accountMedicalNo =
        ref.watch(authControllerProvider).user?.medicalNo ?? '';
    final matches = allPatients.where((p) {
      final q = _query.toLowerCase().trim();
      if (q.isEmpty) return true;
      final matchName = p.name.toLowerCase().contains(q);
      final matchMrn = p.medicalRecordNumber.toLowerCase().contains(q);
      final matchNik = (p.nik ?? '').toLowerCase().contains(q);
      final matchRel = (p.familyRelation ?? '').toLowerCase().contains(q);
      return matchName || matchMrn || matchNik || matchRel;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Text(
                      'Pilih Pasien',
                      style: AppTypography.headingMd.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  style: AppTypography.inputText.copyWith(fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau No. Rekam Medis...',
                    hintStyle: AppTypography.bodySm.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.accentSoft,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                          tooltip: 'Tutup',
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.accentSoft,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Scrollable Patient List
              Expanded(
                child: matches.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 48,
                                color:
                                    AppColors.textTertiary.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                allPatients.isEmpty
                                    ? 'Belum Ada Pasien Terdaftar'
                                    : 'Pasien Tidak Ditemukan',
                                style: AppTypography.bodySm.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                allPatients.isEmpty
                                    ? 'Silakan tambahkan data pasien baru di bawah.'
                                    : 'Coba kata kunci pencarian yang lain.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySm.copyWith(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          4,
                          AppSpacing.xl,
                          AppSpacing.md,
                        ),
                        itemCount: matches.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final patient = matches[index];
                          final isSelected = _selected?.medicalRecordNumber ==
                                  patient.medicalRecordNumber &&
                              _selected?.name == patient.name;

                          final relation = patient.familyRelation ?? 'Pasien';
                          // Only the row synced from the signed-in account is
                          // truly "self", and that one always carries the
                          // account's own record number. Matching on the
                          // relation text alone stranded rows saved with a
                          // wrong "Diri Sendiri" label: they could be neither
                          // edited nor deleted.
                          final isSelf =
                              (relation.toLowerCase().contains('diri') ||
                                  relation.toLowerCase().contains('saya')) &&
                              patient.medicalRecordNumber == accountMedicalNo;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() => _selected = patient);
                                Navigator.of(context).pop(patient);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accentSoft
                                          .withValues(alpha: 0.08)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accentSoft
                                        : AppColors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    // Avatar with Gradient
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: isSelf
                                              ? const [
                                                  Color(0xFF0D9488),
                                                  Color(0xFF14B8A6),
                                                ]
                                              : const [
                                                  Color(0xFF4F46E5),
                                                  Color(0xFF6366F1),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          patient.name.isNotEmpty
                                              ? patient.name[0].toUpperCase()
                                              : 'P',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    // Patient Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  patient.name,
                                                  style: AppTypography.inputText
                                                      .copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14.5,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelf
                                                      ? const Color(0xFFDCFCE7)
                                                      : const Color(0xFFE0F2FE),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  relation,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isSelf
                                                        ? const Color(
                                                            0xFF166534)
                                                        : const Color(
                                                            0xFF0284C7),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            patient.medicalRecordNumber.isNotEmpty
                                                ? 'No. RM: ${patient.medicalRecordNumber}'
                                                : (patient.nik != null &&
                                                        patient.nik!.isNotEmpty
                                                    ? 'NIK: ${patient.nik}'
                                                    : 'Pasien Baru'),
                                            style:
                                                AppTypography.bodySm.copyWith(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Action buttons
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isSelf)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 19,
                                              color: AppColors.accentSoft,
                                            ),
                                            tooltip: 'Ubah Hubungan',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 48,
                                              minHeight: 48,
                                            ),
                                            onPressed: () =>
                                                _editRelation(patient),
                                          ),
                                        if (!isSelf)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 19,
                                              color: AppColors.danger,
                                            ),
                                            tooltip: 'Hapus Pasien',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                            onPressed: () =>
                                                _confirmDeletePatient(patient),
                                          ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 22,
                                            color: AppColors.accentSoft,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Button: Tambah Pasien Baru
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.accentSoft,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.person_add_outlined,
                      color: AppColors.accentSoft,
                      size: 18,
                    ),
                    label: Text(
                      'Tambah Pasien Baru',
                      style: AppTypography.inputText.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.accentSoft,
                      ),
                    ),
                    onPressed: _openAddPatient,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
