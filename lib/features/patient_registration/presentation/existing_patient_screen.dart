import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/patient_draft.dart';

/// Step 2a — look up someone who is already a patient here.
class ExistingPatientScreen extends StatefulWidget {
  const ExistingPatientScreen({super.key});

  @override
  State<ExistingPatientScreen> createState() => _ExistingPatientScreenState();
}

class _ExistingPatientScreenState extends State<ExistingPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recordController = TextEditingController();

  String? _relation;
  DateTime? _birthDate;
  String _gender = PatientOptions.genders.last;

  @override
  void dispose() {
    _recordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir Pasien',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentSoft,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final draft = PatientDraft(
      medicalRecordNumber: _recordController.text.trim(),
      familyRelation: _relation,
      birthDate: _birthDate,
      gender: _gender,
      name: 'Pasien Terdaftar',
      idType: PatientOptions.idTypes.first,
      idNumber: _recordController.text.trim(),
      nationality: PatientOptions.nationalities.first,
      maritalStatus: PatientOptions.maritalStatuses.first,
      religion: PatientOptions.religions.first,
    );

    context.push(AppRoutes.patientReview, extra: draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accentSoft,
      body: Column(
        children: [
          // Top Header
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
              child: Row(
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
                    'Pasien Terdaftar',
                    style: AppTypography.headingMd.copyWith(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                  ),
                  children: [
                    Text(
                      'Pencarian Pasien Lama',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masukkan data pasien yang sudah terdaftar sebelumnya',
                      style: AppTypography.headingSm.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // No. Rekam Medis / NIK
                    Text(
                      'No. Rekam Medis atau NIK Pasien *',
                      style: AppTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _recordController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                      ],
                      style: AppTypography.inputText,
                      decoration: InputDecoration(
                        hintText: 'Masukkan No. Rekam Medis/NIK Pasien',
                        hintStyle: AppTypography.inputText.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(
                            color: AppColors.accentSoft,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          (value?.trim().isEmpty ?? true)
                              ? 'Nomor wajib diisi'
                              : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nomor Rekam Medis tertera pada kartu Pasien/hasil pemeriksaan/bukti transaksi RS. Nomor NIK tertera di Kartu Keluarga (<17 tahun) / KTP (>17 Tahun).',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Hubungan Keluarga
                    Text(
                      'Hubungan Keluarga *',
                      style: AppTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: _relation,
                      style: AppTypography.inputText.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Pilih Hubungan Keluarga',
                        hintStyle: AppTypography.inputText.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        prefixIcon: const Icon(
                          Icons.family_restroom_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(
                            color: AppColors.accentSoft,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: PatientOptions.familyRelations.map((rel) {
                        return DropdownMenuItem(
                          value: rel,
                          child: Text(rel),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _relation = value),
                      validator: (value) =>
                          value == null ? 'Hubungan wajib dipilih' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Tanggal Lahir
                    Text(
                      'Tanggal Lahir *',
                      style: AppTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    InkWell(
                      onTap: _pickBirthDate,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _birthDate == null
                                    ? 'Pilih Tanggal Lahir'
                                    : DateFormat('d MMMM yyyy', 'id_ID')
                                        .format(_birthDate!),
                                style: AppTypography.inputText.copyWith(
                                  color: _birthDate == null
                                      ? AppColors.textTertiary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_birthDate == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          '*Tanggal lahir wajib dipilih saat verifikasi',
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),

                    // Jenis Kelamin
                    Text(
                      'Jenis Kelamin *',
                      style: AppTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (final option in PatientOptions.genders)
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _gender = option),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: option == PatientOptions.genders.first
                                      ? 8
                                      : 0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _gender == option
                                      ? AppColors.accentSoft
                                          .withValues(alpha: 0.08)
                                      : AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(
                                    color: _gender == option
                                        ? AppColors.accentSoft
                                        : AppColors.border,
                                    width: _gender == option ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _gender == option
                                          ? Icons.radio_button_checked_rounded
                                          : Icons
                                              .radio_button_unchecked_rounded,
                                      size: 18,
                                      color: _gender == option
                                          ? AppColors.accentSoft
                                          : AppColors.textTertiary,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      option,
                                      style: AppTypography.bodySm.copyWith(
                                        fontWeight: _gender == option
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
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
          label: 'Lanjut',
          expand: true,
          background: AppColors.accentSoft,
          onPressed: _submit,
        ),
      ),
    );
  }
}
