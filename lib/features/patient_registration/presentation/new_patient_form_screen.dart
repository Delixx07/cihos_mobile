import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/patient_draft.dart';

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
                    'Pendaftaran Pasien Baru',
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

          // White Content Panel
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
                    // Section 1: Kartu ID
                    _FormSectionHeader(
                      title: 'Kartu Identitas (ID)',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.accentSoft,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Pendaftaran pasien usia diatas 1 tahun wajib memasukkan nomor NIK Pasien di Kartu Keluarga (<17 tahun) / KTP (>17 Tahun).',
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                height: 1.35,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Nama Lengkap
                    _FieldWrapper(
                      label: 'Nama Lengkap *',
                      child: TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: AppTypography.inputText,
                        decoration: _inputDecoration('Masukkan nama sesuai kartu identitas'),
                        validator: _required,
                      ),
                    ),

                    // Jenis ID Pasien
                    _FieldWrapper(
                      label: 'Jenis ID Pasien *',
                      child: DropdownButtonFormField<String>(
                        initialValue: _idType,
                        style: AppTypography.inputText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Pilih Jenis ID Pasien'),
                        items: PatientOptions.idTypes.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t));
                        }).toList(),
                        onChanged: (val) => setState(() => _idType = val),
                        validator: _requiredChoice,
                      ),
                    ),

                    // Nomor ID Pasien
                    _FieldWrapper(
                      label: 'Nomor ID Pasien *',
                      child: TextFormField(
                        controller: _idNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                        ],
                        style: AppTypography.inputText,
                        decoration: _inputDecoration('Masukkan Nomor ID Pasien'),
                        validator: _required,
                      ),
                    ),

                    // Kewarganegaraan
                    _FieldWrapper(
                      label: 'Kewarganegaraan *',
                      child: DropdownButtonFormField<String>(
                        initialValue: _nationality,
                        style: AppTypography.inputText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Pilih Kewarganegaraan'),
                        items: PatientOptions.nationalities.map((n) {
                          return DropdownMenuItem(value: n, child: Text(n));
                        }).toList(),
                        onChanged: (val) => setState(() => _nationality = val),
                        validator: _requiredChoice,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 2: Informasi Tambahan
                    _FormSectionHeader(
                      title: 'Informasi Tambahan',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Status Pernikahan
                    _FieldWrapper(
                      label: 'Status Pernikahan *',
                      child: DropdownButtonFormField<String>(
                        initialValue: _maritalStatus,
                        style: AppTypography.inputText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Pilih Status Pernikahan'),
                        items: PatientOptions.maritalStatuses.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) => setState(() => _maritalStatus = val),
                        validator: _requiredChoice,
                      ),
                    ),

                    // Agama
                    _FieldWrapper(
                      label: 'Agama *',
                      child: DropdownButtonFormField<String>(
                        initialValue: _religion,
                        style: AppTypography.inputText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Pilih Agama'),
                        items: PatientOptions.religions.map((r) {
                          return DropdownMenuItem(value: r, child: Text(r));
                        }).toList(),
                        onChanged: (val) => setState(() => _religion = val),
                        validator: _requiredChoice,
                      ),
                    ),

                    // Pendidikan Terakhir
                    _FieldWrapper(
                      label: 'Pendidikan Terakhir *',
                      child: DropdownButtonFormField<String>(
                        initialValue: _education,
                        style: AppTypography.inputText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Pilih Pendidikan Terakhir'),
                        items: PatientOptions.educations.map((e) {
                          return DropdownMenuItem(value: e, child: Text(e));
                        }).toList(),
                        onChanged: (val) => setState(() => _education = val),
                        validator: _requiredChoice,
                      ),
                    ),

                    // Pekerjaan
                    _FieldWrapper(
                      label: 'Pekerjaan *',
                      child: DropdownButtonFormField<String>(
                        initialValue: _occupation,
                        style: AppTypography.inputText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Pilih Pekerjaan'),
                        items: PatientOptions.occupations.map((o) {
                          return DropdownMenuItem(value: o, child: Text(o));
                        }).toList(),
                        onChanged: (val) => setState(() => _occupation = val),
                        validator: _requiredChoice,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 3: Informasi Kontak
                    _FormSectionHeader(
                      title: 'Informasi Kontak',
                      icon: Icons.contact_phone_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Nomor HP
                    _FieldWrapper(
                      label: 'Nomor HP *',
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        style: AppTypography.inputText,
                        decoration: _inputDecoration('Masukkan nomor handphone aktif'),
                        validator: _required,
                      ),
                    ),

                    // Email
                    _FieldWrapper(
                      label: 'Email *',
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTypography.inputText,
                        decoration: _inputDecoration('Masukkan alamat email'),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Wajib diisi';
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),

                    // Alamat
                    _FieldWrapper(
                      label: 'Alamat Rumah *',
                      child: TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        style: AppTypography.inputText,
                        decoration: _inputDecoration('Masukkan alamat rumah lengkap'),
                        validator: _required,
                      ),
                    ),

                    // Provinsi
                    _FieldWrapper(
                      label: 'Provinsi *',
                      child: DropdownButtonFormField<String>(
                        initialValue: _province,
                        style: AppTypography.inputText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Pilih Provinsi'),
                        items: PatientOptions.provinces.map((p) {
                          return DropdownMenuItem(value: p, child: Text(p));
                        }).toList(),
                        onChanged: (val) => setState(() => _province = val),
                        validator: _requiredChoice,
                      ),
                    ),

                    // Kota
                    _FieldWrapper(
                      label: 'Kota *',
                      child: DropdownButtonFormField<String>(
                        initialValue: _city,
                        style: AppTypography.inputText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Pilih Kota'),
                        items: PatientOptions.cities.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) => setState(() => _city = val),
                        validator: _requiredChoice,
                      ),
                    ),

                    // Kelurahan
                    _FieldWrapper(
                      label: 'Kelurahan *',
                      child: DropdownButtonFormField<String>(
                        initialValue: _village,
                        style: AppTypography.inputText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Pilih Kelurahan'),
                        items: PatientOptions.villages.map((v) {
                          return DropdownMenuItem(value: v, child: Text(v));
                        }).toList(),
                        onChanged: (val) => setState(() => _village = val),
                        validator: _requiredChoice,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Warning Notice
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 20,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Perubahan data pada halaman ini tidak mengubah data rekam medis saat ini. Akan tetapi akan digunakan pada saat pembuatan nomor rekam medis baru.',
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 12,
                                height: 1.3,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Consent 1
                    _ConsentRow(
                      value: _agreedToTerms,
                      onChanged: (val) => setState(() => _agreedToTerms = val),
                      text:
                          'Dengan ini, saya menyatakan bahwa data diatas adalah benar dan saya menyetujui pembuatan data pasien sesuai dengan Syarat & Ketentuan yang berlaku',
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Consent 2
                    _ConsentRow(
                      value: _wantsWhatsApp,
                      onChanged: (val) => setState(() => _wantsWhatsApp = val),
                      text:
                          'Saya bersedia mendapatkan informasi terbaru dari Ciputra Hospital melalui WA',
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

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.inputText.copyWith(
        color: AppColors.textTertiary,
        fontSize: 13,
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
    );
  }
}

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accentSoft.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.accentSoft),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.inputText.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.accentSoft,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _FieldWrapper extends StatelessWidget {
  const _FieldWrapper({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              value
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: value ? AppColors.accentSoft : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
