import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../data/catalog_repository.dart';
import '../domain/doctor.dart';
import 'widgets/doctor_card.dart';
import 'widgets/doctor_profile_sheet.dart';

/// Modern search screen for doctors with live search, filters, and profile view.
class DoctorListScreen extends ConsumerStatefulWidget {
  const DoctorListScreen({super.key, this.initialUnitCode});

  final String? initialUnitCode;

  @override
  ConsumerState<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends ConsumerState<DoctorListScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _openProfile(Doctor doctor) async {
    final chosen = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorProfileSheet(doctor: doctor),
    );

    if ((chosen ?? false) && mounted) _book(doctor);
  }

  void _book(Doctor doctor) {
    context.push('${AppRoutes.doctorSchedule}/${doctor.id}', extra: doctor);
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(liveDoctorsProvider(widget.initialUnitCode));
    final matches = doctorsAsync.maybeWhen(
      data: (doctors) {
        if (_query.trim().isEmpty) return doctors;
        final q = _query.toLowerCase();
        return doctors.where((d) {
          return d.name.toLowerCase().contains(q) ||
              d.specialty.toLowerCase().contains(q);
        }).toList();
      },
      orElse: () => const <Doctor>[],
    );

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Cari Dokter'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: _SearchBar(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accentSoft,
                  onRefresh: () async {
                    ref.invalidate(liveDoctorsProvider(widget.initialUnitCode));
                    await ref.read(
                      liveDoctorsProvider(widget.initialUnitCode).future,
                    );
                  },
                  child: AsyncView(
                    value: doctorsAsync,
                    onRetry: () =>
                        ref.invalidate(liveDoctorsProvider(widget.initialUnitCode)),
                    isEmpty: (_) => matches.isEmpty,
                    emptyTitle: _query.isEmpty
                        ? 'Belum ada dokter tersedia'
                        : 'Dokter tidak ditemukan',
                    emptyMessage: _query.isEmpty
                        ? 'Silakan coba beberapa saat lagi.'
                        : 'Tidak ada dokter yang cocok dengan "$_query". Coba kata kunci lain.',
                    builder: (_) => _Results(
                      matches: matches,
                      totalCount: matches.length,
                      onProfileTap: _openProfile,
                      onBookTap: _book,
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 22,
            color: AppColors.accentSoft,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              key: const Key('doctorSearch'),
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: AppTypography.inputText.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'Cari nama dokter atau spesialis...',
                hintStyle: AppTypography.bodySm.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.matches,
    required this.totalCount,
    required this.onProfileTap,
    required this.onBookTap,
  });

  final List<Doctor> matches;
  final int totalCount;
  final ValueChanged<Doctor> onProfileTap;
  final ValueChanged<Doctor> onBookTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      itemCount: matches.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Dokter',
                  style: AppTypography.headingMd.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$totalCount Dokter Ditemukan',
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        final doctor = matches[index - 1];
        return DoctorCard(
          doctor: doctor,
          onProfileTap: () => onProfileTap(doctor),
          onBookTap: () => onBookTap(doctor),
        );
      },
    );
  }
}
