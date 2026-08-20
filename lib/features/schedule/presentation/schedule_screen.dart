import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/textured_background.dart';
import '../data/schedule_repository.dart';
import '../domain/scheduled_appointment.dart';

/// Upcoming appointments, grouped inside one dark panel.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  ScheduleFilter _filter = ScheduleFilter.all;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(scheduledAppointmentsProvider);
    final visible = all.where((a) => switch (_filter) {
      ScheduleFilter.all => true,
      ScheduleFilter.self => a.isSelf,
      ScheduleFilter.others => !a.isSelf,
    }).toList();

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: AppTab.appointments),
      body: TexturedBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.lg,
            ),
            child: _Panel(
              filter: _filter,
              onFilterChanged: (value) => setState(() => _filter = value),
              appointments: visible,
            ),
          ),
        ),
      ),
    );
  }
}

/// The rounded slate panel that holds the whole tab.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.filter,
    required this.onFilterChanged,
    required this.appointments,
  });

  final ScheduleFilter filter;
  final ValueChanged<ScheduleFilter> onFilterChanged;
  final List<ScheduledAppointment> appointments;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Text(
              'Jadwal Temu',
              style: AppTypography.headingLg.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _FilterBar(selected: filter, onChanged: onFilterChanged),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: appointments.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: appointments.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) =>
                          _AppointmentCard(appointment: appointments[index]),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _HistoryButton(),
          ],
        ),
      ),
    );
  }
}

/// Segmented control with a sliding indicator behind the active label.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final ScheduleFilter selected;
  final ValueChanged<ScheduleFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      // A minimum rather than a fixed height, so the row still fits when the
      // platform text scale grows.
      constraints: const BoxConstraints(minHeight: 46),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segment = constraints.maxWidth / ScheduleFilter.values.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: segment * selected.index,
                width: segment,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final option in ScheduleFilter.values)
                    Expanded(
                      child: InkWell(
                        onTap: () => onChanged(option),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        child: Center(
                          child: Text(
                            option.label,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: option == selected
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final ScheduledAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 21,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  appointment.patientName,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '1 Janji Temu',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 17,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'JANJI TEMU 1',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(
                  label: 'KODE BOOKING',
                  value: appointment.bookingCode,
                ),
              ),
              Expanded(
                child: _Field(
                  label: 'JENIS JAMINAN',
                  value: appointment.guaranteeType,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            appointment.doctorName,
            style: AppTypography.inputText.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Flexible(
                child: Text(
                  DateFormat(
                    'EEEE, d MMMM yyyy',
                    'id_ID',
                  ).format(appointment.startsAt),
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(
                  Icons.circle,
                  size: 5,
                  color: AppColors.accentSoft,
                ),
              ),
              Flexible(
                child: Text(
                  appointment.timeRange,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _LinkAction(
                  label: 'Lihat Detail',
                  onTap: () => context.push(
                    '${AppRoutes.appointments}/${appointment.id}',
                  ),
                ),
              ),
              Expanded(
                child: _LinkAction(
                  label: 'QR Janji Temu',
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => _QrDialog(code: appointment.bookingCode),
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

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySm.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySm.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LinkAction extends StatelessWidget {
  const _LinkAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accentSoft,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 14,
            color: AppColors.accentSoft,
          ),
        ],
      ),
    );
  }
}

class _QrDialog extends StatelessWidget {
  const _QrDialog({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Illustrations.qrCode(size: 220),
            const SizedBox(height: AppSpacing.lg),
            Text(
              code,
              style: AppTypography.headingSm.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tunjukkan kode ini di KiosK pendaftaran.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Illustrations.emptySchedule(size: 190),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Anda tidak memiliki jadwal temu\ndokter yang akan datang',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xD9DDDFF3),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryButton extends StatelessWidget {
  const _HistoryButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () => context.go(AppRoutes.history),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          constraints: const BoxConstraints(minHeight: 49),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Lihat Riwayat Janji Temu',
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentSoft,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
