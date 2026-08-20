import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/booking.dart';
import 'practice_calendar.dart';

/// What the filter sheet hands back when it closes.
class SearchFilter {
  const SearchFilter({this.specialty, this.date});

  final String? specialty;
  final DateTime? date;
}

/// The specialty-and-date filter over the doctor search results.
class SearchFilterSheet extends StatefulWidget {
  const SearchFilterSheet({
    super.key,
    required this.kind,
    this.specialty,
    this.date,
  });

  final BookingKind kind;
  final String? specialty;
  final DateTime? date;

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late String? _specialty = widget.specialty;
  late DateTime? _date = widget.date;

  /// The design shows a short list up front, with the rest behind a link.
  bool _showAllSpecialties = false;
  bool _isCalendarOpen = false;

  static const _visibleCount = 10;

  @override
  Widget build(BuildContext context) {
    final all = BookingOptions.specialties;
    final visible = _showAllSpecialties
        ? all
        : all.take(_visibleCount).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter',
                      style: AppTypography.headingMd.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Spesialis',
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (all.length > _visibleCount)
                        TextButton(
                          onPressed: () => setState(
                            () => _showAllSpecialties = !_showAllSpecialties,
                          ),
                          child: Text(
                            _showAllSpecialties
                                ? 'Lihat Lebih Sedikit'
                                : 'Lihat Lainnya',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 13,
                              color: AppColors.link,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final specialty in visible)
                        _SpecialtyChip(
                          label: specialty,
                          isSelected: specialty == _specialty,
                          onTap: () => setState(
                            () => _specialty =
                                specialty == _specialty ? null : specialty,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Tanggal',
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    key: const Key('filterDateRow'),
                    onTap: () => setState(
                      () => _isCalendarOpen = !_isCalendarOpen,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _date == null
                                  ? 'Pilih Tanggal'
                                  : DateFormat(
                                      'EEEE, d MMMM yyyy',
                                      'id_ID',
                                    ).format(_date!),
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 15,
                                color: _date == null
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isCalendarOpen) ...[
                    const SizedBox(height: AppSpacing.md),
                    PracticeCalendar(
                      kind: widget.kind,
                      selected: _date,
                      onSelected: (value) => setState(() => _date = value),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _specialty = null;
                      _date = null;
                    }),
                    child: Text(
                      'Hapus',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Tampilkan Hasil Pencarian',
                      expand: true,
                      background: AppColors.accentSoft,
                      onPressed: () => Navigator.of(context).pop(
                        SearchFilter(specialty: _specialty, date: _date),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({
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
      color: isSelected ? AppColors.accentSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
