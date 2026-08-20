import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../domain/patient_draft.dart';
import '../widgets/underline_field.dart';

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final draft = PatientDraft(
      medicalRecordNumber: _recordController.text.trim(),
      familyRelation: _relation,
      birthDate: _birthDate,
      gender: _gender,
      // The lookup would fill these in from the record; stand in for now.
      name: 'Nadila',
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
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: 'Pendaftaran Pasien'),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                    ),
                    children: [
                      UnderlineField(
                        label: 'No. Rekam Medis atau NIK Pasien*',
                        hint: 'Masukkan No. Rekam Medis/NIK Pasien',
                        controller: _recordController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                        ],
                        helper:
                            'Nomor Rekam Medis tertera pada kartu Pasien/hasil '
                            'pemeriksaan/bukti transaksi RS. Nomor NIK tertera '
                            'di Kartu Keluarga (<17 tahun) / KTP (>17 Tahun)',
                        validator: (value) =>
                            (value?.trim().isEmpty ?? true)
                            ? 'Nomor wajib diisi'
                            : null,
                      ),
                      UnderlineDropdown(
                        label: 'Hubungan Keluarga*',
                        hint: 'Pilih Hubungan Keluarga',
                        value: _relation,
                        options: PatientOptions.familyRelations,
                        onChanged: (value) => setState(() => _relation = value),
                        validator: (value) =>
                            value == null ? 'Hubungan wajib dipilih' : null,
                      ),
                      UnderlineDateField(
                        label: 'Tanggal Lahir*',
                        hint: 'Pilih Tanggal Lahir',
                        value: _birthDate,
                        onChanged: (value) =>
                            setState(() => _birthDate = value),
                        validator: (value) =>
                            value == null ? 'Tanggal lahir wajib diisi' : null,
                      ),
                      _GenderPicker(
                        value: _gender,
                        onChanged: (value) => setState(() => _gender = value),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: AppButton(
                  label: 'Lanjut',
                  expand: true,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The two radio options for sex, laid out in a row as in the design.
class _GenderPicker extends StatelessWidget {
  const _GenderPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin*',
          style: AppTypography.inputText.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (final option in PatientOptions.genders)
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(option),
                  child: Row(
                    children: [
                      Icon(
                        option == value
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        option,
                        style: AppTypography.bodySm.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
