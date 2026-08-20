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
import '../../../core/theme/app_elevation.dart';

/// Step 2b — the full intake form for someone with no record here yet.
class NewPatientFormScreen extends StatefulWidget {
  const NewPatientFormScreen({super.key});

  @override
  State<NewPatientFormScreen> createState() => _NewPatientFormScreenState();
}

class _NewPatientFormScreenState extends State<NewPatientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String? _idType;
  String? _nationality;
  String? _maritalStatus;
  String? _religion;
  String? _education;
  String? _occupation;
  String? _province;
  String? _city;
  String? _village;

  bool _agreedToTerms = false;
  bool _wantsWhatsApp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Wajib diisi' : null;

  String? _requiredChoice(String? value) =>
      value == null ? 'Wajib dipilih' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      // Validation errors sit above the fold on a form this long.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data yang bertanda *.')),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centang persetujuan untuk melanjutkan.'),
        ),
      );
      return;
    }

    final draft = PatientDraft(
      name: _nameController.text.trim(),
      idType: _idType,
      idNumber: _idNumberController.text.trim(),
      nationality: _nationality,
      maritalStatus: _maritalStatus,
      religion: _religion,
      education: _education,
      occupation: _occupation,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      province: _province,
      city: _city,
      village: _village,
      agreedToTerms: _agreedToTerms,
      wantsWhatsAppUpdates: _wantsWhatsApp,
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
                      const _SectionTitle('Kartu ID'),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Pendaftaran pasien usia diatas 1 tahun, wajib '
                        'memasukkan nomor NIK Pasien di Kartu Keluarga '
                        '(<17 tahun) / KTP (>17 Tahun)',
                        style: AppTypography.inputText,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      UnderlineField(
                        label: 'Nama Lengkap*',
                        hint: 'Masukkan nama sesuai kartu identitas',
                        controller: _nameController,
                        validator: _required,
                      ),
                      UnderlineDropdown(
                        label: 'Jenis ID Pasien*',
                        hint: 'Pilih ID Pasien',
                        value: _idType,
                        options: PatientOptions.idTypes,
                        onChanged: (value) => setState(() => _idType = value),
                        validator: _requiredChoice,
                      ),
                      UnderlineField(
                        label: 'Nomor ID Pasien*',
                        hint: 'Nomor ID Pasien',
                        controller: _idNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                        ],
                        validator: _required,
                      ),
                      UnderlineDropdown(
                        label: 'Kewarganegaraan*',
                        hint: 'Pilih Kewarganegaraan',
                        value: _nationality,
                        options: PatientOptions.nationalities,
                        onChanged: (value) =>
                            setState(() => _nationality = value),
                        validator: _requiredChoice,
                      ),

                      const _SectionTitle('INFORMASI TAMBAHAN'),
                      const SizedBox(height: AppSpacing.lg),
                      UnderlineDropdown(
                        label: 'Status Pernikahan*',
                        hint: 'Pilih Status Pernikahan',
                        value: _maritalStatus,
                        options: PatientOptions.maritalStatuses,
                        onChanged: (value) =>
                            setState(() => _maritalStatus = value),
                        validator: _requiredChoice,
                      ),
                      UnderlineDropdown(
                        label: 'Agama*',
                        hint: 'Pilih Agama',
                        value: _religion,
                        options: PatientOptions.religions,
                        onChanged: (value) => setState(() => _religion = value),
                        validator: _requiredChoice,
                      ),
                      UnderlineDropdown(
                        label: 'Pendidikan Terakhir*',
                        hint: 'Pilih Pendidikan Terakhir',
                        value: _education,
                        options: PatientOptions.educations,
                        onChanged: (value) =>
                            setState(() => _education = value),
                        validator: _requiredChoice,
                      ),
                      UnderlineDropdown(
                        label: 'Pekerjaan*',
                        hint: 'Pilih Pekerjaan',
                        value: _occupation,
                        options: PatientOptions.occupations,
                        onChanged: (value) =>
                            setState(() => _occupation = value),
                        validator: _requiredChoice,
                      ),

                      const _SectionTitle('INFORMASI KONTAK'),
                      const SizedBox(height: AppSpacing.lg),
                      UnderlineField(
                        label: 'Nomor HP*',
                        hint: 'Masukkan no. HP',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        validator: _required,
                      ),
                      UnderlineField(
                        label: 'Email*',
                        hint: 'Masukkan alamat e-mail Anda',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Wajib diisi';
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      UnderlineField(
                        label: 'Alamat*',
                        hint: 'Masukkan alamat rumah Anda',
                        controller: _addressController,
                        maxLines: 2,
                        validator: _required,
                      ),
                      UnderlineDropdown(
                        label: 'Provinsi*',
                        hint: 'Pilih Provinsi',
                        value: _province,
                        options: PatientOptions.provinces,
                        onChanged: (value) => setState(() => _province = value),
                        validator: _requiredChoice,
                      ),
                      UnderlineDropdown(
                        label: 'Kota*',
                        hint: 'Pilih Kota',
                        value: _city,
                        options: PatientOptions.cities,
                        onChanged: (value) => setState(() => _city = value),
                        validator: _requiredChoice,
                      ),
                      UnderlineDropdown(
                        label: 'Kelurahan*',
                        hint: 'Pilih Kelurahan',
                        value: _village,
                        options: PatientOptions.villages,
                        onChanged: (value) => setState(() => _village = value),
                        validator: _requiredChoice,
                      ),

                      const _WarningCard(),
                      const SizedBox(height: AppSpacing.xl),
                      _Consent(
                        value: _agreedToTerms,
                        onChanged: (value) =>
                            setState(() => _agreedToTerms = value),
                        text:
                            'Dengan ini, saya menyatakan bahwa data diatas '
                            'adalah benar dan saya menyetujui pembuatan data '
                            'pasien sesuai dengan Syarat & Ketentuan yang '
                            'berlaku',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _Consent(
                        value: _wantsWhatsApp,
                        onChanged: (value) =>
                            setState(() => _wantsWhatsApp = value),
                        text:
                            'Saya bersedia mendapatkan informasi terbaru dari '
                            'Ciputra Hospital melalui WA',
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppButton(
                        label: 'Lanjut',
                        expand: true,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        text,
        style: AppTypography.inputText.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.link,
        ),
      ),
    );
  }
}

/// The red notice about what editing here does and does not change.
class _WarningCard extends StatelessWidget {
  const _WarningCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppElevation.level2,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              size: 21,
              color: Color(0xFFDE3333),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Perubahan data pada halaman ini tidak mengubah data rekam '
                'medis saat ini. Akan tetapi akan digunakan pada saat '
                'pembuatan nomor rekam medis baru.',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  height: 1.27,
                  color: const Color(0xFFDE3333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Consent extends StatelessWidget {
  const _Consent({
    required this.value,
    required this.onChanged,
    required this.text,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySm.copyWith(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
