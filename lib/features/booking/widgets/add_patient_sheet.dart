import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../data/patient_repository.dart';
import '../domain/booking.dart';
import '../../patient_registration/domain/patient_draft.dart';

/// Modern modal sheet to quickly add a new patient for booking.
class AddPatientSheet extends ConsumerStatefulWidget {
  const AddPatientSheet({super.key});

  static Future<BookingPatient?> show(BuildContext context) {
    return showModalBottomSheet<BookingPatient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddPatientSheet(),
    );
  }

  @override
  ConsumerState<AddPatientSheet> createState() => _AddPatientSheetState();
}

class _AddPatientSheetState extends ConsumerState<AddPatientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rmController = TextEditingController();
  final _phoneController = TextEditingController();

  /// Deliberately unset: pre-filling "Diri Sendiri" made every relative the
  /// patient added look like the account holder, and the booking flow treats
  /// that relation as "this is me" — so an untouched dropdown could file an
  /// appointment under the wrong person.
  String? _relation;
  String _gender = 'Laki-laki';
  DateTime? _birthDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rmController.dispose();
    _phoneController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // The server resolves the NIK against MEDINFRAS and only stores a
      // confirmed match, so an unregistered relative is caught here rather
      // than failing later at booking.
      final savedPatient = await ref
          .read(registeredPatientsProvider.notifier)
          .addFamilyMember(
            nik: _rmController.text.trim(),
            name: _nameController.text.trim(),
            dob: _birthDate,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            relation: _relation,
          );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (savedPatient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_nameController.text.trim()} belum terdaftar di Ciputra '
              'Hospital Surabaya. Pendaftaran pasien baru harus dilakukan '
              'langsung di rumah sakit.',
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      Navigator.of(context).pop(savedPatient);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        bottomInset + AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title & close
                Row(
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
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah Pasien Baru',
                            style: AppTypography.headingMd.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Lengkapi data pasien yang akan didaftarkan',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Nama Pasien
                Text(
                  'Nama Lengkap Pasien *',
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: AppTypography.inputText.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Ahmad Fauzi',
                    hintStyle: AppTypography.inputText.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: Color(0xFF0D9488),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 13,
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
                  validator: (val) =>
                      (val?.trim().isEmpty ?? true) ? 'Nama pasien wajib diisi' : null,
                ),
                const SizedBox(height: AppSpacing.md),

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
                  value: _relation,
                  style: AppTypography.inputText.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.family_restroom_rounded,
                      size: 20,
                      color: Color(0xFF4F46E5),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 13,
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
                  hint: Text(
                    'Pilih hubungan dengan pasien',
                    style: AppTypography.inputText.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 13.5,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Hubungan wajib dipilih'
                      : null,
                  // "Diri Sendiri" is not offered: the account holder is
                  // already in the list automatically, and picking it here
                  // would create a second entry for the same person.
                  items: PatientOptions.familyRelations
                      .where((rel) => rel != 'Diri Sendiri')
                      .map((rel) {
                    return DropdownMenuItem(
                      value: rel,
                      child: Text(rel, style: AppTypography.inputText),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _relation = val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // No. Rekam Medis / NIK
                Text(
                  'No. Rekam Medis atau NIK *',
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _rmController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  style: AppTypography.inputText.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Masukkan No. RM atau NIK 16 digit',
                    hintStyle: AppTypography.inputText.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.badge_rounded,
                      size: 20,
                      color: Color(0xFF0284C7),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 13,
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
                  validator: (val) =>
                      (val?.trim().isEmpty ?? true) ? 'No. RM atau NIK wajib diisi' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Tanggal Lahir & Jenis Kelamin Row
                Row(
                  children: [
                    // Tanggal Lahir
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggal Lahir',
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
                                vertical: 13,
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
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      _birthDate == null
                                          ? 'Pilih Tgl'
                                          : DateFormat('d MMM yyyy', 'id_ID')
                                              .format(_birthDate!),
                                      style: AppTypography.inputText.copyWith(
                                        color: _birthDate == null
                                            ? AppColors.textTertiary
                                            : AppColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Jenis Kelamin
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jenis Kelamin',
                            style: AppTypography.bodySm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          DropdownButtonFormField<String>(
                            value: _gender,
                            style: AppTypography.inputText.copyWith(fontSize: 13.5),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.wc_rounded,
                                size: 20,
                                color: Color(0xFF059669),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 13,
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
                            items: const [
                              DropdownMenuItem(
                                value: 'Laki-laki',
                                child: Text('Laki-laki'),
                              ),
                              DropdownMenuItem(
                                value: 'Perempuan',
                                child: Text('Perempuan'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _gender = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // No. HP Pasien (Opsional)
                Text(
                  'Nomor Handphone (Opsional)',
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  style: AppTypography.inputText.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 081234567890',
                    hintStyle: AppTypography.inputText.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.phone_iphone_rounded,
                      size: 20,
                      color: Color(0xFF7C3AED),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 13,
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
                ),
                const SizedBox(height: AppSpacing.xl),

                // Save button
                AppButton(
                  label: 'Simpan Data Pasien',
                  expand: true,
                  isLoading: _isSaving,
                  background: AppColors.accentSoft,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
