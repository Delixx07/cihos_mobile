import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/results_repository.dart';
import '../domain/exam_result.dart';

/// Full-screen modern view of an examination result with signature dark slate header,
/// curved content sheet, precision scan viewer, and document preview.
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
        backgroundColor: AppColors.accentSoft,
        body: Column(
          children: [
            _TopAppBar(
              title: 'Hasil Pemeriksaan',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Hasil tidak ditemukan',
                        style: AppTypography.headingSm.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Data pemeriksaan mungkin telah dipindahkan atau dihapus.',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final (categoryBg, categoryColor, categoryIcon) = switch (result.category) {
      ExamCategory.laboratorium => (
          const Color(0xFFE0F2FE),
          const Color(0xFF0284C7),
          Icons.science_outlined,
        ),
      ExamCategory.mcu => (
          const Color(0xFFEDE9FE),
          const Color(0xFF7C3AED),
          Icons.health_and_safety_outlined,
        ),
      ExamCategory.radiologi => (
          const Color(0xFFCCFBF1),
          const Color(0xFF0D9488),
          Icons.biotech_outlined,
        ),
    };

    return Scaffold(
      backgroundColor: AppColors.accentSoft,
      body: Column(
        children: [
          // Modern Dark Slate Header
          Container(
            color: AppColors.accentSoft,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.sm,
              AppSpacing.xxl,
              AppSpacing.lg,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Row
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Kembali',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
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
                      Expanded(
                        child: Text(
                          'Hasil ${result.category.label}',
                          style: AppTypography.headingMd.copyWith(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Bagikan',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: AppColors.primary,
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Tautan ${result.title} siap dibagikan.',
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Hero Exam Title
                  Text(
                    result.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headingMd.copyWith(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Header Badges & Details Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Category Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(categoryIcon, size: 13, color: categoryColor),
                            const SizedBox(width: 4),
                            Text(
                              result.category.label,
                              style: AppTypography.caption.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Verified Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: result.documentAsset != null
                              ? AppColors.successSurface
                              : AppColors.warningSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              result.documentAsset != null
                                  ? Icons.verified_rounded
                                  : Icons.access_time_rounded,
                              size: 13,
                              color: result.documentAsset != null
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              result.documentAsset != null
                                  ? 'Terverifikasi'
                                  : 'Proses Validasi',
                              style: AppTypography.caption.copyWith(
                                color: result.documentAsset != null
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Patient Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              result.patientName,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Date Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy', 'id_ID').format(result.date),
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Main Curved White/Surface Content Panel
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Viewer Component
                  Expanded(
                    child: result.category.isImagery
                        ? _ScanViewer(result: result)
                        : _DocumentViewer(result: result),
                  ),

                  // Bottom Action Dock
                  _ResultBottomBar(result: result),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accentSoft,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.md,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Kembali',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              onPressed: onBack,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              title,
              style: AppTypography.headingMd.copyWith(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radiology scan viewer styled like a modern PACS / DICOM medical lightbox.
class _ScanViewer extends StatefulWidget {
  const _ScanViewer({required this.result});

  final ExamResult result;

  @override
  State<_ScanViewer> createState() => _ScanViewerState();
}

class _ScanViewerState extends State<_ScanViewer> {
  final TransformationController _controller = TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformationChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      setState(() => _currentScale = scale);
    }
  }

  void _zoomIn() {
    HapticFeedback.selectionClick();
    final newScale = (_currentScale * 1.3).clamp(1.0, 4.0);
    _controller.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
  }

  void _zoomOut() {
    HapticFeedback.selectionClick();
    final newScale = (_currentScale / 1.3).clamp(1.0, 4.0);
    _controller.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
  }

  void _resetZoom() {
    HapticFeedback.selectionClick();
    _controller.value = Matrix4.identity();
  }

  void _openFullscreen(BuildContext context) {
    if (widget.result.documentAsset == null) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => _FullscreenScanDialog(
          result: widget.result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.result.documentAsset == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: _MissingAsset(isImagery: true),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF11131C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF282B3C), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Interactive Medical Scan
            InteractiveViewer(
              transformationController: _controller,
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Image.asset(
                  widget.result.documentAsset!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const _MissingAsset(isImagery: true),
                ),
              ),
            ),

            // Top Status Overlay: Zoom Scale & Fullscreen Button
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.zoom_in_rounded,
                          size: 13,
                          color: Color(0xFF4BAEE2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(_currentScale * 100).toInt()}%',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _openFullscreen(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fullscreen_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Layar Penuh',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Floating Controls Toolbar
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E212E).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _zoomOut,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Perkecil',
                      ),
                      Container(
                        height: 18,
                        width: 1,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      TextButton(
                        onPressed: _resetZoom,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(40, 36),
                        ),
                        child: Text(
                          'Reset',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      Container(
                        height: 18,
                        width: 1,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _zoomIn,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Perbesar',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen immersive scan dialog for detailed medical inspection.
class _FullscreenScanDialog extends StatelessWidget {
  const _FullscreenScanDialog({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 6.0,
              child: Center(
                child: Image.asset(
                  result.documentAsset!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                tooltip: 'Tutup',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 24,
              left: 70,
              right: 16,
              child: Text(
                result.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lab & MCU reports render inside a paper sheet presentation.
class _DocumentViewer extends StatefulWidget {
  const _DocumentViewer({required this.result});

  final ExamResult result;

  @override
  State<_DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<_DocumentViewer> {
  final TransformationController _docController = TransformationController();

  @override
  void dispose() {
    _docController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.result.documentAsset == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: _MissingAsset(isImagery: false),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Top Document Header Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: AppColors.accentSoft,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Dokumen Resmi PDF',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Halaman 1 / 1',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Paper Sheet with Interactive Zoom
            Expanded(
              child: InteractiveViewer(
                transformationController: _docController,
                minScale: 1.0,
                maxScale: 3.5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        widget.result.documentAsset!,
                        fit: BoxFit.fitWidth,
                        errorBuilder: (context, error, stackTrace) =>
                            const _MissingAsset(isImagery: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A modern in-progress / missing document state with medical timeline steps.
class _MissingAsset extends StatelessWidget {
  const _MissingAsset({required this.isImagery});

  final bool isImagery;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: isImagery ? const Color(0xFF171924) : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isImagery ? const Color(0xFF2E3146) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isImagery
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFFFF7ED),
              shape: BoxShape.circle,
              border: Border.all(
                color: isImagery
                    ? Colors.white24
                    : const Color(0xFFFDBA74).withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              size: 32,
              color: isImagery
                  ? const Color(0xFF4BAEE2)
                  : const Color(0xFFEA580C),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Hasil Dalam Proses Verifikasi',
            textAlign: TextAlign.center,
            style: AppTypography.headingSm.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isImagery ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Dokumen digital sedang divalidasi oleh dokter spesialis dan laboratorium. File akan otomatis dapat diunduh setelah terbit.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              fontSize: 12.5,
              height: 1.4,
              color: isImagery ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 3-Step Process Progress
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isImagery
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isImagery ? Colors.white12 : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepBadge(
                  step: '1',
                  label: 'Pemeriksaan',
                  isCompleted: true,
                  isDark: isImagery,
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: AppColors.success,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                _StepBadge(
                  step: '2',
                  label: 'Validasi Dokter',
                  isCurrent: true,
                  isDark: isImagery,
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: isImagery ? Colors.white24 : AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                _StepBadge(
                  step: '3',
                  label: 'Dokumen Terbit',
                  isDark: isImagery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.step,
    required this.label,
    this.isCompleted = false,
    this.isCurrent = false,
    required this.isDark,
  });

  final String step;
  final String label;
  final bool isCompleted;
  final bool isCurrent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppColors.success
        : isCurrent
            ? const Color(0xFFEA580C)
            : (isDark ? Colors.white38 : AppColors.textTertiary);

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success
                : isCurrent
                    ? const Color(0xFFEA580C)
                    : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : Text(
                  step,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isCurrent || isCompleted
                        ? Colors.white
                        : (isDark ? Colors.white54 : AppColors.textSecondary),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isCurrent || isCompleted
                ? FontWeight.w700
                : FontWeight.w500,
            color: isCurrent || isCompleted
                ? (isDark ? Colors.white : AppColors.textPrimary)
                : (isDark ? Colors.white38 : AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}

/// Bottom action bar to download PDF or view result status.
class _ResultBottomBar extends StatelessWidget {
  const _ResultBottomBar({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    final hasDoc = result.documentAsset != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: ElevatedButton(
        onPressed: hasDoc
            ? () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppColors.primary,
                    content: Row(
                      children: [
                        const Icon(
                          Icons.file_download_done_rounded,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mengunduh ${result.title}.pdf...',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentSoft,
          disabledBackgroundColor: AppColors.accentSoft.withValues(alpha: 0.3),
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_rounded,
              size: 18,
              color: hasDoc ? AppColors.white : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              hasDoc ? 'Unduh Hasil (PDF)' : 'Menunggu Rilis',
              style: AppTypography.inputText.copyWith(
                color: hasDoc ? AppColors.white : Colors.white60,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
