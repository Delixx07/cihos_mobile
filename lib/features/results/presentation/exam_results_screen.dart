import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../data/results_repository.dart';
import '../domain/exam_result.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_motion.dart';

/// Finished examinations, filtered by category and by which patient they
/// belong to.
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
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Hasil Pemeriksaan'),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: _CategoryTabs(
                  selected: _category,
                  onSelected: (value) => setState(() => _category = value),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: _PatientSelector(
                  value: patient,
                  isOpen: _isPatientListOpen,
                  onToggle: () => setState(
                    () => _isPatientListOpen = !_isPatientListOpen,
                  ),
                ),
              ),
              if (_isPatientListOpen)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: _PatientList(
                    patients: patients,
                    selected: patient,
                    onSelected: (value) => setState(() {
                      _patientName = value;
                      _isPatientListOpen = false;
                    }),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: visible.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xxxl,
                        ),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.xl),
                        itemBuilder: (context, index) =>
                            _ResultCard(result: visible[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Semua / Laboratorium / MCU / Radiologi strip.
class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onSelected});

  final ExamCategory? selected;
  final ValueChanged<ExamCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        boxShadow: AppElevation.level2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: ColoredBox(
          color: AppColors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Tab(
                  label: 'Semua',
                  isSelected: selected == null,
                  onTap: () => onSelected(null),
                ),
                for (final category in ExamCategory.values)
                  _Tab(
                    label: category.label,
                    isSelected: selected == category,
                    onTap: () => onSelected(category),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
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
      color: isSelected ? const Color(0xFF4BAEE2) : AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.inputText.copyWith(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
              color: isSelected ? AppColors.white : AppColors.textPrimary,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        boxShadow: const [
          BoxShadow(
            color: Color(0x803F4153),
            offset: Offset(0, 4),
            blurRadius: 10.4,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: InkWell(
          key: const Key('resultPatientSelector'),
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 26,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: AppMotion.fast,
                  child: const Icon(
                    Icons.expand_more,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: AppElevation.level2,
      ),
      child: ColoredBox(
        color: AppColors.white,
        child: Column(
          children: [
            for (final patient in patients)
              InkWell(
                onTap: () => onSelected(patient.name),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              patient.medicalRecordNumber,
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (patient.name == selected)
                        const Icon(
                          Icons.check,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        boxShadow: AppElevation.level2,
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: InkWell(
          onTap: () =>
              context.push('${AppRoutes.examResults}/${result.id}'),
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryPill(label: result.category.label),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  result.title,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MetaLine(
                  icon: Icons.calendar_month,
                  text: DateFormat(
                    'EEEE, dd MMMM yyyy',
                    'id_ID',
                  ).format(result.date),
                ),
                const SizedBox(height: AppSpacing.xs),
                _MetaLine(
                  icon: Icons.account_circle,
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
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: AppTypography.bodySm.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
        Icon(icon, size: 13, color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySm.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
          const Icon(
            Icons.folder_off_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Belum ada hasil pemeriksaan', style: AppTypography.bodyMd),
        ],
      ),
    );
  }
}
