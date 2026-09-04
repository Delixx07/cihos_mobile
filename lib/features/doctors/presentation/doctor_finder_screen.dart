import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/pressable.dart';
import '../../booking/widgets/specialty_picker_sheet.dart';
import '../data/catalog_repository.dart';
import '../domain/clinic.dart';
import '../domain/doctor.dart';

/// Doctor Discovery / Finder Screen.
/// Uses the same header, search, and filter mechanics as the Booking flow,
/// but presents doctors in a 2-column card discovery grid.
class DoctorFinderScreen extends ConsumerStatefulWidget {
  const DoctorFinderScreen({super.key});

  @override
  ConsumerState<DoctorFinderScreen> createState() => _DoctorFinderScreenState();
}

class _DoctorFinderScreenState extends ConsumerState<DoctorFinderScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  String _query = '';
  Clinic? _selectedClinic;

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

  Future<void> _pickClinicFilter() async {
    final picked = await showModalBottomSheet<Clinic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpecialtyPickerSheet(
        selected: _selectedClinic,
        title: 'Filter Berdasarkan Klinik',
        searchHint: 'Cari Klinik / Spesialisasi...',
        hasClearOption: true,
      ),
    );

    if (picked != null) {
      setState(() {
        if (picked.code.isEmpty) {
          _selectedClinic = null;
        } else {
          _selectedClinic = picked;
        }
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedClinic = null;
    });
  }

  void _openDoctorDetail(Doctor doctor) {
    context.push('${AppRoutes.doctorSchedule}/${doctor.id}', extra: doctor);
  }

  String _resolveClinicName(Doctor doctor, List<Clinic> clinics) {
    if (doctor.unitCode != null && doctor.unitCode!.isNotEmpty) {
      final matched = clinics.cast<Clinic?>().firstWhere(
        (c) => c?.code.toUpperCase() == doctor.unitCode!.toUpperCase(),
        orElse: () => null,
      );
      if (matched != null) return matched.displayName;
    }
    return doctor.specialty;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUnitCode = _selectedClinic?.code;
    final doctorsAsync = ref.watch(liveDoctorsProvider(effectiveUnitCode));
    final clinicsAsync = ref.watch(clinicsProvider);
    final clinics = clinicsAsync.valueOrNull ?? const <Clinic>[];

    final matches = doctorsAsync.maybeWhen(
      data: (doctors) {
        return doctors.where((d) {
          // Filter by clinic if selected locally
          if (_selectedClinic != null && _selectedClinic!.code.isNotEmpty) {
            final cCode = _selectedClinic!.code.toLowerCase();
            final cName = _selectedClinic!.displayName.toLowerCase();
            final dUnit = (d.unitCode ?? '').toLowerCase();
            final dSpec = d.specialty.toLowerCase();

            final matchUnit = dUnit == cCode;
            final matchSpec = dSpec.contains(cName) || cName.contains(dSpec);
            if (!matchUnit && !matchSpec) return false;
          }

          // Filter by query
          if (_query.trim().isNotEmpty) {
            final q = _query.toLowerCase();
            final matchName = d.name.toLowerCase().contains(q);
            final matchSpec = d.specialty.toLowerCase().contains(q);
            if (!matchName && !matchSpec) return false;
          }

          return true;
        }).toList();
      },
      orElse: () => const <Doctor>[],
    );

    final hasActiveFilter = _selectedClinic != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Header Linear Gradient (0% #003366 to 100% #0047AB)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: hasActiveFilter ? 270 : 220,
            child: const DecoratedBox(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.sm,
                    AppSpacing.xxl,
                    AppSpacing.md,
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
                            constraints: const BoxConstraints(),
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
                              'Cari Dokter',
                              style: AppTypography.headingMd.copyWith(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Search & Filter Row
                      Row(
                        children: [
                          Expanded(
                            child: _SearchBar(
                              controller: _searchController,
                              focusNode: _searchFocus,
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              onClear: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Filter Clinic Button
                          _FilterButton(
                            isActive: hasActiveFilter,
                            onTap: _pickClinicFilter,
                          ),
                        ],
                      ),

                      // Active Filter Chip Display
                      if (hasActiveFilter) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_hospital_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 180),
                                    child: Text(
                                      _selectedClinic!.displayName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: _clearFilter,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _clearFilter,
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                foregroundColor: const Color(0xFFFFB4AB),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text(
                                'Hapus Filter',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Main Curved Surface Content Panel
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      ref.invalidate(liveDoctorsProvider(effectiveUnitCode));
                      await ref.read(
                        liveDoctorsProvider(effectiveUnitCode).future,
                      );
                    },
                    child: AsyncView(
                      value: doctorsAsync,
                      onRetry: () => ref.invalidate(
                        liveDoctorsProvider(effectiveUnitCode),
                      ),
                      isEmpty: (_) => matches.isEmpty,
                      emptyTitle: _query.isEmpty && !hasActiveFilter
                          ? 'Belum ada dokter tersedia'
                          : 'Dokter tidak ditemukan',
                      emptyMessage: hasActiveFilter
                          ? 'Tidak ada dokter yang tersedia untuk klinik "${_selectedClinic?.displayName}". Coba pilih klinik lain atau hapus filter.'
                          : (_query.isEmpty
                              ? 'Silakan coba beberapa saat lagi.'
                              : 'Tidak ada dokter yang cocok dengan "$_query".'),
                      builder: (_) => CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // 2-Column Grid of Doctor Cards
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xxl,
                              AppSpacing.lg,
                              AppSpacing.xxl,
                              AppSpacing.xxxl,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.02,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final doctor = matches[index];
                                  final clinicName =
                                      _resolveClinicName(doctor, clinics);
                                  return _DoctorGridCard(
                                    key: Key('doctorCard_${doctor.id}'),
                                    doctor: doctor,
                                    clinicName: clinicName,
                                    onTap: () => _openDoctorDetail(doctor),
                                  );
                                },
                                childCount: matches.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('doctorClinicFilterButton'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentSoft : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.accentSoft : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: isActive ? AppColors.white : AppColors.accentSoft,
              ),
              if (isActive)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBBF24),
                      shape: BoxShape.circle,
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
      height: 48,
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
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'Cari nama dokter atau spesialis...',
                hintStyle: AppTypography.bodySm.copyWith(
                  fontSize: 13.5,
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
              icon: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.textTertiary,
              ),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// A modern 2-column card matching the requested design layout.
class _DoctorGridCard extends StatelessWidget {
  const _DoctorGridCard({
    super.key,
    required this.doctor,
    required this.clinicName,
    required this.onTap,
  });

  final Doctor doctor;
  final String clinicName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Section: Avatar + Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF1F5F9),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: doctor.photoAsset != null
                            ? Image.asset(
                                doctor.photoAsset!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorBuilder: (context, error, stackTrace) =>
                                    const _AvatarPlaceholder(),
                              )
                            : const _AvatarPlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Doctor Name
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          doctor.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Middle: Doctor Specialist
                Text(
                  doctor.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0284C7),
                    height: 1.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Bottom Row: Clinic Info (left) & Navigation Action Icon (right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Clinic info (replacing rating)
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          clinicName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Arrow Action Badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 14,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 26,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
