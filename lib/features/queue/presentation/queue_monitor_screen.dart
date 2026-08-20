import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../../../core/theme/app_elevation.dart';

/// Live queue position for today's appointment.
class QueueMonitorScreen extends StatefulWidget {
  const QueueMonitorScreen({super.key, this.hasQueue = true});

  /// Whether the patient has an appointment today. The design covers both
  /// states, and there is no backend yet to decide.
  final bool hasQueue;

  @override
  State<QueueMonitorScreen> createState() => _QueueMonitorScreenState();
}

class _QueueMonitorScreenState extends State<QueueMonitorScreen> {
  DateTime _lastUpdated = DateTime(2025, 2, 13, 8, 54);
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      _lastUpdated = DateTime.now();
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Monitor Antrean Dokter'),
              Expanded(
                child: widget.hasQueue
                    ? _QueueBody(
                        lastUpdated: _lastUpdated,
                        isRefreshing: _isRefreshing,
                        onRefresh: _refresh,
                      )
                    : const _EmptyQueue(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueBody extends StatelessWidget {
  const _QueueBody({
    required this.lastUpdated,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final DateTime lastUpdated;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      children: [
        const _NoticeCard(),
        const SizedBox(height: AppSpacing.xxl),
        const _PatientChip(name: 'NADILA'),
        const SizedBox(height: AppSpacing.xxl),
        _QueueCard(
          lastUpdated: lastUpdated,
          isRefreshing: isRefreshing,
          onRefresh: onRefresh,
        ),
      ],
    );
  }
}

/// The blue "Penting Untuk Diketahui" advisory above the queue card.
class _NoticeCard extends StatelessWidget {
  const _NoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
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
                'Penting Untuk Diketahui',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.link,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final line in const [
            'Tekan REFRESH untuk mendapatkan informasi status antrean yang '
                'terbaru.',
            'Harap melakukan check in sebelum jam praktek dokter berakhir.',
            'Check in akan gagal bila dilakukan setelah jam praktek dokter '
                'selesai.',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      line,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12,
                        height: 1.2,
                        color: Colors.black,
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

class _PatientChip extends StatelessWidget {
  const _PatientChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDDDFF3),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          name,
          style: AppTypography.inputText.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.accentSoft,
          ),
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.lastUpdated,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final DateTime lastUpdated;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: AppElevation.level2,
      ),
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Stat(
              label: 'No. Antrean',
              value: '2',
              valueColor: AppColors.link,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _Stat(label: 'Di Depan Anda', value: '1', suffix: 'Orang'),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                '1 Orang belum check in',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Terakhir Diupdate',
                    value: DateFormat('HH.mm').format(lastUpdated),
                  ),
                ),
                _RefreshButton(isRefreshing: isRefreshing, onTap: onRefresh),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'dr. Edwin Hadinata, Sp.PD',
              style: AppTypography.titleMd.copyWith(
                fontSize: 15,
                color: AppColors.accentSoft,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _IconLine(
              icon: Icons.medical_services_outlined,
              text: 'Penyakit Dalam',
            ),
            const _IconLine(
              icon: Icons.location_on,
              text: 'Ciputra Hospital Surabaya',
            ),
            const _IconLine(
              icon: Icons.calendar_today,
              text: 'Rabu, 13 Februari 2025  12:00 - 12:15 WIB',
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.suffix,
    this.valueColor = AppColors.accentSoft,
  });

  final String label;
  final String value;
  final String? suffix;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.titleMd.copyWith(
            fontSize: 15,
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: AppTypography.headingLg.copyWith(
                fontSize: 32,
                color: valueColor,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  suffix!,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.isRefreshing, required this.onTap});

  final bool isRefreshing;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFDDDFF3),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: isRefreshing ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: 124,
          height: 45,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.textPrimary),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: isRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.accentSoft,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Refresh',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inputText.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentSoft,
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

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.accentSoft),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySm.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.accentSoft.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when there is no appointment queued for today.
class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            'Tidak ada antrean Janji Temu Dokter hari ini',
            textAlign: TextAlign.center,
            style: AppTypography.headingMd.copyWith(
              color: AppColors.accentSoft,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Antrean Janji Temu Dokter akan tampil apabila Anda Memiliki '
            'Janji Temu dokter hari ini.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Illustrations.emptySchedule(size: 240),
        ],
      ),
    );
  }
}
