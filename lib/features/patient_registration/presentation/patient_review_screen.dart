import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../booking/data/patient_repository.dart';
import '../../booking/domain/booking.dart';
import '../domain/patient_draft.dart';

/// Step 3 — read the entered data back before committing it.
class PatientReviewScreen extends ConsumerStatefulWidget {
  const PatientReviewScreen({super.key, required this.draft});

  final PatientDraft draft;

  @override
  ConsumerState<PatientReviewScreen> createState() =>
      _PatientReviewScreenState();
}

class _PatientReviewScreenState extends ConsumerState<PatientReviewScreen> {
  bool _isSubmitting = false;

  Future<void> _confirm() async {
    setState(() => _isSubmitting = true);
    // Stands in for the create-patient call.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final draft = widget.draft;
    final patient = BookingPatient(
      name: draft.name ?? 'Pasien Baru',
      medicalRecordNumber: draft.medicalRecordNumber ??
          'RM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      familyRelation: draft.familyRelation ?? 'Diri Sendiri',
      nik: draft.idNumber,
      gender: draft.gender,
      birthDate: draft.birthDate,
      phone: draft.phone,
    );

    await ref.read(registeredPatientsProvider.notifier).addPatient(patient);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SuccessDialog(),
    );

    if (mounted) {
      if (context.canPop()) {
        context.pop(); // pop review screen
        if (context.canPop()) {
          context.pop(); // pop form screen
          if (context.canPop()) {
            context.pop(); // pop patient type screen
          }
        }
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

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
                    'Review Data Pasien',
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                children: [
                  Text(
                    'Konfirmasi Data',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Harap pastikan seluruh data pasien sudah tepat',
                    style: AppTypography.headingSm.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section: Informasi Utama
                  _ReviewCard(
                    title: 'INFORMASI UTAMA',
                    icon: Icons.person_outline_rounded,
                    items: [
                      _ReviewItem(label: 'Nama', value: draft.name),
                      _ReviewItem(
                        label: 'Hubungan Keluarga',
                        value: draft.familyRelation,
                      ),
                      _ReviewItem(
                        label: 'Tanggal Lahir',
                        value: draft.birthDate == null
                            ? null
                            : DateFormat('d MMMM yyyy', 'id_ID')
                                .format(draft.birthDate!),
                      ),
                      _ReviewItem(label: 'Jenis Kelamin', value: draft.gender),
                      if (draft.medicalRecordNumber != null)
                        _ReviewItem(
                          label: 'No. Rekam Medis / NIK',
                          value: draft.medicalRecordNumber,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Section: Kartu ID
                  if (draft.idType != null || draft.idNumber != null) ...[
                    _ReviewCard(
                      title: 'KARTU IDENTITAS',
                      icon: Icons.badge_outlined,
                      items: [
                        _ReviewItem(label: 'Jenis ID Pasien', value: draft.idType),
                        _ReviewItem(label: 'Nomor ID Pasien', value: draft.idNumber),
                        _ReviewItem(
                          label: 'Kewarganegaraan',
                          value: draft.nationality,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Section: Informasi Tambahan
                  if (draft.maritalStatus != null ||
                      draft.religion != null ||
                      draft.education != null ||
                      draft.occupation != null) ...[
                    _ReviewCard(
                      title: 'INFORMASI TAMBAHAN',
                      icon: Icons.info_outline_rounded,
                      items: [
                        _ReviewItem(
                          label: 'Status Pernikahan',
                          value: draft.maritalStatus,
                        ),
                        _ReviewItem(label: 'Agama', value: draft.religion),
                        _ReviewItem(
                          label: 'Pendidikan Terakhir',
                          value: draft.education,
                        ),
                        _ReviewItem(label: 'Pekerjaan', value: draft.occupation),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Section: Informasi Kontak
                  if (draft.phone != null ||
                      draft.email != null ||
                      draft.address != null) ...[
                    _ReviewCard(
                      title: 'INFORMASI KONTAK',
                      icon: Icons.contact_phone_outlined,
                      items: [
                        _ReviewItem(label: 'Nomor HP', value: draft.phone),
                        _ReviewItem(label: 'Email', value: draft.email),
                        _ReviewItem(label: 'Alamat', value: draft.address),
                        _ReviewItem(label: 'Provinsi', value: draft.province),
                        _ReviewItem(label: 'Kota', value: draft.city),
                        _ReviewItem(label: 'Kelurahan', value: draft.village),
                      ],
                    ),
                  ],
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
          label: 'Konfirmasi & Simpan',
          expand: true,
          isLoading: _isSubmitting,
          background: AppColors.accentSoft,
          onPressed: _confirm,
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_ReviewItem> items;

  @override
  Widget build(BuildContext context) {
    final validItems = items.where((i) => i.value != null && i.value!.isNotEmpty).toList();
    if (validItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.accentSoft),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentSoft,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: AppSpacing.lg),
          for (final item in validItems)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      item.label,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 6,
                    child: Text(
                      item.value!,
                      style: AppTypography.inputText.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewItem {
  const _ReviewItem({required this.label, required this.value});
  final String label;
  final String? value;
}

/// Step 4 — modern confirmation dialog.
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: AppColors.accentSoft,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Pasien Berhasil Ditambahkan!',
              textAlign: TextAlign.center,
              style: AppTypography.headingSm.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Data pasien telah tersimpan dan siap digunakan untuk membuat janji temu.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Lanjutkan',
              expand: true,
              background: AppColors.accentSoft,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
