import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/booking.dart';

/// Month grid for picking a booking date with vibrant modern styling & practice day indicators.
class PracticeCalendar extends StatefulWidget {
  const PracticeCalendar({
    super.key,
    required this.kind,
    required this.selected,
    required this.onSelected,
    this.practisingDates,
  });

  final BookingKind kind;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;
  final Set<DateTime>? practisingDates;

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
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
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
            practisingDates: widget.practisingDates,
            onSelected: widget.onSelected,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          const _Legend(),
        ],
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(month),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Bulan sebelumnya',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
                iconSize: 20,
                color: AppColors.textPrimary,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Bulan berikutnya',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
                iconSize: 20,
                color: AppColors.textPrimary,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final label in _labels)
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.kind,
    required this.selected,
    required this.onSelected,
    this.practisingDates,
  });

  final DateTime month;
  final BookingKind kind;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;
  final Set<DateTime>? practisingDates;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final leadingBlanks = firstOfMonth.weekday - DateTime.monday;
    final cellCount = leadingBlanks + daysInMonth;
    final rowCount = (cellCount / 7).ceil();

    return Column(
      children: [
        for (var row = 0; row < rowCount; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
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
    if (dayOffset < 0 ||
        dayOffset >= DateTime(month.year, month.month + 1, 0).day) {
      return const SizedBox(height: 36);
    }

    final day = DateTime(month.year, month.month, dayOffset + 1);
    final isPractising = practisingDates != null
        ? practisingDates!.any((d) =>
            d.year == day.year && d.month == day.month && d.day == day.day)
        : (BookingOptions.isPractisingDay(day) &&
            BookingOptions.isBookable(day, kind));
    final isSelected = selected != null &&
        selected!.year == day.year &&
        selected!.month == day.month &&
        selected!.day == day.day;

    final now = DateTime.now();
    final isToday = now.year == day.year &&
        now.month == day.month &&
        now.day == day.day;

    return _DayCell(
      day: day.day,
      isPractising: isPractising,
      isSelected: isSelected,
      isToday: isToday,
      onTap: isPractising ? () => onSelected(day) : null,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isPractising,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final bool isPractising;
  final bool isSelected;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isPractising
              ? const Color(0xFFF0FDF4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: const Color(0xFF0D9488), width: 1.5)
              : (isPractising
                  ? Border.all(color: const Color(0xFFBBF7D0), width: 1)
                  : null),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isPractising ? FontWeight.w700 : FontWeight.w400,
            color: isPractising
                ? const Color(0xFF065F46)
                : const Color(0xFF94A3B8),
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
    return const Row(
      children: [
        _LegendDot(
          color: Color(0xFF059669),
          label: 'Tersedia',
          isBox: true,
        ),
        SizedBox(width: AppSpacing.lg),
        _LegendDot(
          color: Color(0xFF0D9488),
          label: 'Dipilih',
          isGradient: true,
        ),
        SizedBox(width: AppSpacing.lg),
        _LegendDot(
          color: Color(0xFFCBD5E1),
          label: 'Tidak Praktek',
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.isBox = false,
    this.isGradient = false,
  });

  final Color color;
  final String label;
  final bool isBox;
  final bool isGradient;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isBox ? const Color(0xFFDCFCE7) : color,
            border: isBox
                ? Border.all(color: const Color(0xFF059669), width: 1.5)
                : null,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
