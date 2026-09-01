import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_elevation.dart';

/// "Mengapa Anda Ingin Membatalkan Janji Temu?" — pick a reason, then confirm.
///
/// Pops the chosen reason, or null when dismissed.
class CancelAppointmentSheet extends StatefulWidget {
  const CancelAppointmentSheet({super.key});

  static const reasons = [
    'Kondisi sudah membaik',
    'Tidak bisa datang diwaktu tersebut',
    'Lainnya',
  ];

  @override
  State<CancelAppointmentSheet> createState() =>
      _CancelAppointmentSheetState();
}

class _CancelAppointmentSheetState extends State<CancelAppointmentSheet> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mengapa Anda Ingin Membatalkan Janji Temu?',
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.black,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final reason in CancelAppointmentSheet.reasons) ...[
              _ReasonRow(
                label: reason,
                isSelected: reason == _reason,
                onTap: () => setState(() => _reason = reason),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Apakah Anda yakin akan membatalkan Janji Temu?',
              style: AppTypography.bodySm.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ConfirmButton(
              isEnabled: _reason != null,
              onTap: () => Navigator.of(context).pop(_reason),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      // Selected reasons take the blue fill from the design.
      color: isSelected ? const Color(0xFF4BAEE2) : AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 39,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: const BoxDecoration(
            boxShadow: AppElevation.level2,
          ),
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.isEnabled, required this.onTap});

  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1 : 0.5,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: InkWell(
          key: const Key('confirmCancel'),
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Container(
            width: double.infinity,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(color: AppColors.textPrimary),
            ),
            child: Text(
              'Batalkan Janji Temu',
              style: AppTypography.button.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown once the cancellation has been submitted.
class CancelSubmittedSheet extends StatelessWidget {
  const CancelSubmittedSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pembatalan Janji Temu sedang diproses',
              textAlign: TextAlign.center,
              style: AppTypography.headingSm.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Harap cek lanjut status pembatalan Janji Temu Anda melalui '
              'menu Riwayat Janji Temu.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(fontSize: 15, height: 1.3),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _OutlinedAction(
              key: const Key('cancelDone'),
              label: 'Kembali ke Beranda',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Container(
          width: double.infinity,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: AppColors.textPrimary),
          ),
          child: Text(
            label,
            style: AppTypography.button.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown while the cancellation is in flight with the hospital system.
///
/// Not dismissible: the request is already on its way, and letting the patient
/// back out here would leave them unsure whether it went through.
class CancelInProgressSheet extends StatelessWidget {
  const CancelInProgressSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Membatalkan janji temu…',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the hospital system refused the cancellation.
///
/// The reason matters here — a patient who has already checked in has to be
/// told to call the hospital, not to try again.
class CancelFailedSheet extends StatelessWidget {
  const CancelFailedSheet({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pembatalan tidak berhasil',
              textAlign: TextAlign.center,
              style: AppTypography.headingSm.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(fontSize: 15, height: 1.3),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _OutlinedAction(
              key: const Key('cancelFailedDismiss'),
              label: 'Tutup',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
