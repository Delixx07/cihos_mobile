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
import '../data/history_repository.dart';
import '../domain/past_appointment.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/staggered_entrance.dart';

/// "Riwayat Jadwal Temu" — finished visits, each rebookable in one tap.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(pastAppointmentsProvider);

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: AppTab.history),
      body: TexturedBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                ),
                child: _TitlePill(),
              ),
              Expanded(
                child: visits.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          0,
                          AppSpacing.xxl,
                          AppSpacing.xxxl,
                        ),
                        itemCount: visits.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.lg),
                        itemBuilder: (context, index) => StaggeredEntrance(
                          index: index,
                          child: Pressable(
                            scale: 0.98,
                            child: _VisitCard(visit: visits[index]),
                          ),
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

/// The slate pill the design puts the screen title inside.
class _TitlePill extends StatelessWidget {
  const _TitlePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppElevation.level2,
      ),
      child: Container(
        height: 59,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          'Riwayat Jadwal Temu',
          style: AppTypography.headingLg.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

/// One finished visit: doctor, when it happened, and a rebook shortcut.
class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit});

  final PastAppointment visit;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(visit.startsAt);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppElevation.level2,
      ),
      child: Container(
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
                Expanded(
                  child: Text(
                    visit.kind.label,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                _OutcomeChip(outcome: visit.outcome),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  visit.kind == VisitKind.videoCall
                      ? Icons.videocam
                      : Icons.person,
                  size: 23,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.doctorName,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentSoft,
                        ),
                      ),
                      Text(
                        visit.specialty,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              date,
              style: AppTypography.bodySm.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accentSoft,
              ),
            ),
            Text(
              visit.timeRange,
              style: AppTypography.bodySm.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    visit.patientName,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentSoft,
                    ),
                  ),
                ),
                _RebookButton(visit: visit),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Selesai" / "Dibatalkan" badge in the card's top-right corner.
class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({required this.outcome});

  final VisitOutcome outcome;

  @override
  Widget build(BuildContext context) {
    // Status carries meaning, so it carries colour: a cancelled visit should
    // not look identical to a completed one at a glance.
    final (background, foreground) = switch (outcome) {
      VisitOutcome.completed => (
        AppColors.successSurface,
        AppColors.success,
      ),
      VisitOutcome.cancelled => (AppColors.dangerSurface, AppColors.danger),
      VisitOutcome.missed => (AppColors.warningSurface, AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        outcome.label,
        style: AppTypography.bodySm.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

/// Drops the user back into the booking flow, pre-set to the same kind.
class _RebookButton extends StatelessWidget {
  const _RebookButton({required this.visit});

  final PastAppointment visit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        key: Key('rebook_${visit.id}'),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        // Each search route carries its own kind, so the path is the choice.
        onTap: () => context.push(
          visit.kind == VisitKind.videoCall
              ? AppRoutes.videoCallSearch
              : AppRoutes.appointmentSearch,
        ),
        child: Container(
          height: 21,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Buat Janji Ulang',
            style: AppTypography.bodySm.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.lavender,
            ),
          ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Illustrations.emptySchedule(size: 160),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Belum ada riwayat kunjungan',
            style: AppTypography.bodySm.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.accentSoft,
            ),
          ),
        ],
      ),
    );
  }
}
