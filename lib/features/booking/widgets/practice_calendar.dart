import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/booking.dart';
import '../../../core/theme/app_elevation.dart';

/// Month grid for picking a telemedicine date, with a legend separating days
/// the doctor practises from days they do not.
class PracticeCalendar extends StatefulWidget {
  const PracticeCalendar({
    super.key,
    required this.kind,
    required this.selected,
    required this.onSelected,
  });

  /// Decides how far ahead days stay bookable.
  final BookingKind kind;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  State<PracticeCalendar> createState() => _PracticeCalendarState();
}

class _PracticeCalendarState extends State<PracticeCalendar> {
  late DateTime _visibleMonth = DateTime(
    widget.selected?.year ?? DateTime.now().year,
    widget.selected?.month ?? DateTime.now().month,
  );

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.level2,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthHeader(
              month: _visibleMonth,
              onPrevious: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
            ),
            const SizedBox(height: AppSpacing.md),
            const _WeekdayRow(),
            const SizedBox(height: AppSpacing.sm),
            _DayGrid(
              month: _visibleMonth,
              kind: widget.kind,
              selected: widget.selected,
              onSelected: widget.onSelected,
            ),
            const SizedBox(height: AppSpacing.md),
            const _Legend(),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              Text(
                DateFormat('MMMM', 'id_ID').format(month),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.45,
                ),
              ),
              Text(
                '${month.year}',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.75,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Bulan sebelumnya',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          tooltip: 'Bulan berikutnya',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  static const _labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in _labels)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.39,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.kind,
    required this.selected,
    required this.onSelected,
  });

  final DateTime month;
  final BookingKind kind;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // Monday-first grid, so Monday contributes no leading blanks.
    final leadingBlanks = firstOfMonth.weekday - DateTime.monday;
    final cellCount = leadingBlanks + daysInMonth;
    final rowCount = (cellCount / 7).ceil();

    return Column(
      children: [
        for (var row = 0; row < rowCount; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: _cellFor(row * 7 + column - leadingBlanks),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cellFor(int dayOffset) {
    if (dayOffset < 0 || dayOffset >= DateTime(month.year, month.month + 1, 0).day) {
      return const SizedBox(height: 30);
    }

    final day = DateTime(month.year, month.month, dayOffset + 1);
    final isPractising =
        BookingOptions.isPractisingDay(day) &&
        BookingOptions.isBookable(day, kind);
    final isSelected =
        selected != null &&
        selected!.year == day.year &&
        selected!.month == day.month &&
        selected!.day == day.day;

    return _DayCell(
      day: day.day,
      isPractising: isPractising,
      isSelected: isSelected,
      onTap: isPractising ? () => onSelected(day) : null,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isPractising,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final bool isPractising;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.white
        : isPractising
        ? AppColors.textPrimary
        : Colors.black.withValues(alpha: 0.3);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : null,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.45,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _LegendDot(color: AppColors.textPrimary, label: 'Praktek'),
        const SizedBox(width: AppSpacing.xl),
        _LegendDot(
          color: Colors.black.withValues(alpha: 0.3),
          label: 'Tidak Praktek',
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.24,
          ),
        ),
      ],
    );
  }
}
