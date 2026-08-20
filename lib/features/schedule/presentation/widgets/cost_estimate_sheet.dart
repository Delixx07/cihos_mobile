import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// One line on the estimate.
class CostLine {
  const CostLine({required this.label, required this.amount});

  final String label;
  final int amount;
}

/// "Perkiraan Biaya" — the itemised estimate for a booked visit.
class CostEstimateSheet extends StatelessWidget {
  const CostEstimateSheet({
    super.key,
    required this.doctorName,
    required this.lines,
  });

  final String doctorName;
  final List<CostLine> lines;

  int get _subtotal =>
      lines.fold(0, (total, line) => total + line.amount);

  @override
  Widget build(BuildContext context) {
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
                    'Perkiraan Biaya',
                    style: AppTypography.inputText.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.black,
                ),
              ],
            ),
            const Divider(color: Color(0xFFEEE8E8)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Jasa Dokter',
              style: AppTypography.inputText.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              doctorName,
              style: AppTypography.bodySm.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _Row(
                  label: line.label,
                  value: rupiah.format(line.amount),
                ),
              ),
            const Divider(color: Color(0xFFEEE8E8)),
            const SizedBox(height: AppSpacing.sm),
            _Row(
              label: 'Subtotal',
              value: rupiah.format(_subtotal),
              isTotal: true,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _Notice(),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.w500 : FontWeight.w600,
              color: isTotal
                  ? Colors.black
                  : Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySm.copyWith(
            fontSize: 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDF9FF),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 20,
                color: AppColors.link,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Informasi Tambahan',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.link,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nominal yang tertera merupakan perkiraan biaya. Belum termasuk '
            'biaya tindakan/pemeriksaan penunjang/obat dan alkes yang '
            'digunakan pada saat di RS',
            style: AppTypography.bodySm.copyWith(
              fontSize: 12,
              height: 1.2,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
