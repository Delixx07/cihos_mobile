import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../data/results_repository.dart';
import '../domain/exam_result.dart';
import '../../../core/theme/app_elevation.dart';

/// Full-screen view of one result — a zoomable scan for radiology, a scrolling
/// document for everything else.
class ResultViewerScreen extends ConsumerWidget {
  const ResultViewerScreen({super.key, required this.resultId});

  final String resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref
        .watch(examResultsProvider)
        .where((r) => r.id == resultId)
        .firstOrNull;

    if (result == null) {
      return Scaffold(
        body: TexturedBackground(
          child: SafeArea(
            child: Column(
              children: [
                const ScreenHeader(title: 'Hasil Pemeriksaan'),
                Expanded(
                  child: Center(
                    child: Text(
                      'Hasil tidak ditemukan',
                      style: AppTypography.bodyMd,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: 'Hasil ${result.category.label}'),
              Expanded(
                child: result.category.isImagery
                    ? _ScanViewer(result: result)
                    : _DocumentViewer(result: result),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Radiology scans sit on black and can be pinched and panned.
class _ScanViewer extends StatelessWidget {
  const _ScanViewer({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: ClipRRect
        (
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: ColoredBox(
          color: Colors.black,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: result.documentAsset == null
                  ? const _MissingAsset(onDark: true)
                  : Image.asset(
                      result.documentAsset!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const _MissingAsset(onDark: true),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lab and MCU reports render as a scrollable page.
class _DocumentViewer extends StatelessWidget {
  const _DocumentViewer({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: AppElevation.level2,
        ),
        child: ColoredBox(
          color: AppColors.white,
          child: result.documentAsset == null
              ? const SizedBox(
                  height: 400,
                  child: _MissingAsset(onDark: false),
                )
              : Image.asset(
                  result.documentAsset!,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 400,
                    child: _MissingAsset(onDark: false),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MissingAsset extends StatelessWidget {
  const _MissingAsset({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white54 : AppColors.textTertiary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 48, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Dokumen belum tersedia',
            style: AppTypography.bodySm.copyWith(fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}
