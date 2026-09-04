import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_motion.dart';
import '../data/results_repository.dart';
import '../domain/exam_result.dart';

/// Finished examinations, filtered by category and by which patient they belong to.
class ExamResultsScreen extends ConsumerStatefulWidget {
  const ExamResultsScreen({super.key});

  @override
  ConsumerState<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends ConsumerState<ExamResultsScreen> {
  /// Null means "Semua".
  ExamCategory? _category;
  String? _patientName;
  bool _isPatientListOpen = false;

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(resultPatientsProvider);
    final results = ref.watch(examResultsProvider);
    final patient = _patientName ?? patients.first.name;

    final visible = results
        .where(
          (r) =>
              r.patientName == patient &&
              (_category == null || r.category == _category),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Header Linear Gradient (0% #003366 to 100% #0047AB) extending behind the curve
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF003366), // 0%
                    Color(0xFF0047AB), // 100%
                  ],
                ),
              ),
            ),
          ),

          // Foreground Content
          Column(
            children: [
              // Header Controls
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.sm,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                  ),
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
                          'Hasil Pemeriksaan',
                          style: AppTypography.headingMd.copyWith(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Patient Selector Row
                  _PatientSelector(
                    value: patient,
                    isOpen: _isPatientListOpen,
                    onToggle: () => setState(
                      () => _isPatientListOpen = !_isPatientListOpen,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category Filter Chips
                  _CategoryTabs(
                    selected: _category,
                    onSelected: (value) => setState(() => _category = value),
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
              child: Stack(
                children: [
                  visible.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xxl,
                            AppSpacing.xl,
                            AppSpacing.xxl,
                            AppSpacing.xxxl,
                          ),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) =>
                              _ResultCard(result: visible[index]),
                        ),

                  // Expandable Patient Dropdown Overlay
                  if (_isPatientListOpen)
                    Positioned(
                      top: 0,
                      left: AppSpacing.xxl,
                      right: AppSpacing.xxl,
                      child: _PatientList(
                        patients: patients,
                        selected: patient,
                        onSelected: (value) => setState(() {
                          _patientName = value;
                          _isPatientListOpen = false;
                        }),
                      ),
                    ),
                ],
              ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}

/// The modern category filter pill bar.
class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onSelected});

  final ExamCategory? selected;
  final ValueChanged<ExamCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabPill(
            label: 'Semua',
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in ExamCategory.values)
            _TabPill(
              label: category.label,
              isSelected: selected == category,
              onTap: () => onSelected(category),
            ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected
            ? AppColors.white
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.accentSoft : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The collapsed row showing whose results are on screen.
class _PatientSelector extends StatelessWidget {
  const _PatientSelector({
    required this.value,
    required this.isOpen,
    required this.onToggle,
  });

  final String value;
  final bool isOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('resultPatientSelector'),
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Rekam Medis',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: AppMotion.fast,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The expanded panel of family members.
class _PatientList extends StatelessWidget {
  const _PatientList({
    required this.patients,
    required this.selected,
    required this.onSelected,
  });

  final List<ResultPatient> patients;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final patient in patients)
            Material(
              color: patient.name == selected
                  ? AppColors.surface
                  : AppColors.white,
              child: InkWell(
                onTap: () => onSelected(patient.name),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: patient.name == selected
                              ? AppColors.accentSoft.withValues(alpha: 0.1)
                              : AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: patient.name == selected
                              ? AppColors.accentSoft
                              : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 13.5,
                                fontWeight: patient.name == selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'No. RM: ${patient.medicalRecordNumber}',
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (patient.name == selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.accentSoft,
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
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () =>
              context.push('${AppRoutes.examResults}/${result.id}'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CategoryPill(category: result.category),
                    Row(
                      children: [
                        Text(
                          result.documentAsset != null
                              ? 'Tersedia'
                              : 'Diproses',
                          style: AppTypography.caption.copyWith(
                            color: result.documentAsset != null
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  result.title,
                  style: AppTypography.headingSm.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MetaLine(
                  icon: Icons.calendar_today_outlined,
                  text: DateFormat(
                    'EEEE, dd MMMM yyyy',
                    'id_ID',
                  ).format(result.date),
                ),
                const SizedBox(height: AppSpacing.xs),
                _MetaLine(
                  icon: Icons.person_outline_rounded,
                  text: result.patientName,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});

  final ExamCategory category;

  @override
  Widget build(BuildContext context) {
    final (categoryBg, categoryColor, categoryIcon) = switch (category) {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(categoryIcon, size: 12, color: categoryColor),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: AppTypography.caption.copyWith(
              color: categoryColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySm.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
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
              Icons.folder_off_outlined,
              size: 44,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada hasil pemeriksaan',
            style: AppTypography.headingSm.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hasil pemeriksaan akan muncul di sini setelah selesai diproses.',
            style: AppTypography.bodySm.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
