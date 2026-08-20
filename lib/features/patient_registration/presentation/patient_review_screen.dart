import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../domain/patient_draft.dart';

/// Step 3 — read the entered data back before committing it.
class PatientReviewScreen extends StatefulWidget {
  const PatientReviewScreen({super.key, required this.draft});

  final PatientDraft draft;

  @override
  State<PatientReviewScreen> createState() => _PatientReviewScreenState();
}

class _PatientReviewScreenState extends State<PatientReviewScreen> {
  bool _isSubmitting = false;

  Future<void> _confirm() async {
    setState(() => _isSubmitting = true);
    // Stands in for the create-patient call.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SuccessDialog(),
    );

    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: 'Pendaftaran Pasien'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                  ),
                  children: [
                    Text(
                      'Harap pastikan data sudah tepat',
                      style: AppTypography.headingSm.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    const _SectionTitle('INFORMASI UTAMA'),
                    _Row(label: 'Nama', value: draft.name),
                    _Row(
                      label: 'Hubungan Keluarga',
                      value: draft.familyRelation,
                    ),
                    _Row(
                      label: 'Tanggal Lahir',
                      value: draft.birthDate == null
                          ? null
                          : DateFormat(
                              'd MMMM yyyy',
                              'id_ID',
                            ).format(draft.birthDate!),
                    ),
                    _Row(label: 'Jenis Kelamin', value: draft.gender),

                    const _SectionTitle('KARTU ID'),
                    _Row(label: 'Jenis ID Pasien', value: draft.idType),
                    _Row(label: 'Nomor ID Pasien', value: draft.idNumber),
                    _Row(label: 'Kewarganegaraan', value: draft.nationality),

                    const _SectionTitle('INFORMASI TAMBAHAN'),
                    _Row(
                      label: 'Status Pernikahan',
                      value: draft.maritalStatus,
                    ),
                    _Row(label: 'Agama', value: draft.religion),
                    _Row(label: 'Pendidikan Terakhir', value: draft.education),
                    _Row(label: 'Pekerjaan', value: draft.occupation),

                    if (draft.phone != null || draft.email != null) ...[
                      const _SectionTitle('INFORMASI KONTAK'),
                      _Row(label: 'Nomor HP', value: draft.phone),
                      _Row(label: 'Email', value: draft.email),
                      _Row(label: 'Alamat', value: draft.address),
                      _Row(label: 'Provinsi', value: draft.province),
                      _Row(label: 'Kota', value: draft.city),
                      _Row(label: 'Kelurahan', value: draft.village),
                    ],
                  ],
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
                  label: 'Konfirmasi',
                  expand: true,
                  isLoading: _isSubmitting,
                  onPressed: _confirm,
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
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
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

/// One reviewed value. Rows with nothing to show are omitted entirely rather
/// than rendering an empty line.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySm.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(value!, style: AppTypography.inputText),
        ],
      ),
    );
  }
}

/// Step 4 — the confirmation dialog.
class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: AppColors.link,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Data Pasien Baru Berhasil Ditambahkan!',
              textAlign: TextAlign.center,
              style: AppTypography.headingSm.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Anda sudah bisa membuat appointment untuk pasien ini',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Lanjutkan',
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
