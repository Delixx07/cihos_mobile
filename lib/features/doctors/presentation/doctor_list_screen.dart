import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/async_view.dart';
import '../../booking/domain/booking.dart';
import '../../booking/widgets/specialty_picker_sheet.dart';
import '../data/catalog_repository.dart';
import '../domain/clinic.dart';
import '../domain/doctor.dart';
import 'widgets/doctor_card.dart';
import 'widgets/doctor_profile_sheet.dart';

/// Modern doctor list screen used for:
/// 1. "Buat Janji Temu" (kind: BookingKind.appointment)
/// 2. "Buat Video Call" (kind: BookingKind.videoCall)
/// 3. "Cari Dokter" (kind: null)
///
/// Features search bar, clinic filter button & chips, and direct 1-click booking without method prompt.
class DoctorListScreen extends ConsumerStatefulWidget {
  const DoctorListScreen({
    super.key,
    this.kind,
    this.initialUnitCode,
    this.isAddingAnother = false,
  });

  final BookingKind? kind;
  final String? initialUnitCode;
  final bool? isAddingAnother;

  @override
  ConsumerState<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends ConsumerState<DoctorListScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  String _query = '';
  Clinic? _selectedClinic;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
    if (widget.initialUnitCode != null && widget.initialUnitCode!.isNotEmpty) {
      _selectedClinic = Clinic(
        code: widget.initialUnitCode!,
        name: widget.initialUnitCode!,
      );
    }
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

  Future<void> _openProfile(Doctor doctor) async {
    final chosen = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorProfileSheet(doctor: doctor),
    );

    if ((chosen ?? false) && mounted) {
      _handleBookAction(doctor);
    }
  }

  Future<void> _handleBookAction(Doctor doctor) async {
    // 1. Jika alur dari Buat Janji Temu atau Buat Video Call:
    // Langsung navigasi ke pemilihan jadwal TANPA menanyakan metode lagi!
    if (widget.kind != null) {
      context.push(
        AppRoutes.bookingSchedule,
        extra: Booking(
          kind: widget.kind!,
          doctorId: doctor.id,
          doctorName: doctor.name,
          paramedicCode: doctor.code,
          specialty: _selectedClinic?.displayName ?? doctor.specialty,
          unitCode: _selectedClinic?.code ?? doctor.unitCode,
        ),
      );
      return;
    }

    // 2. Jika alur dari Cari Dokter biasa:
    // Navigasi ke halaman Profil & Jadwal Dokter
    context.push('${AppRoutes.doctorSchedule}/${doctor.id}', extra: doctor);
  }

  @override
  Widget build(BuildContext context) {
    final screenTitle = switch (widget.kind) {
      BookingKind.appointment => 'Buat Janji Temu',
      BookingKind.videoCall => 'Buat Video Call',
      null => 'Cari Dokter',
    };

    final effectiveUnitCode = _selectedClinic?.code ?? widget.initialUnitCode;
    final doctorsAsync = ref.watch(liveDoctorsProvider(effectiveUnitCode));

    final matches = doctorsAsync.maybeWhen(
      data: (doctors) {
        return doctors.where((d) {
          // Filter by kind (for video call, show supported)
          if (widget.kind == BookingKind.videoCall &&
              !d.supports(ConsultationMethod.videoCall)) {
            return false;
          }

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
                              screenTitle,
                              style: AppTypography.headingMd.copyWith(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.isAddingAnother == true) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add_task_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Tambah Janji Temu',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => context.pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  foregroundColor: const Color(0xFFFFB4AB),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text(
                                  'Batal Tambah',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),

                      // Search & Filter Row
                      Row(
                        children: [
                    Expanded(
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
                                    constraints: const BoxConstraints(maxWidth: 180),
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
                                        color: Colors.white.withValues(alpha: 0.25),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                      onRetry: () =>
                          ref.invalidate(liveDoctorsProvider(effectiveUnitCode)),
                      isEmpty: (_) => matches.isEmpty,
                      emptyTitle: _query.isEmpty && !hasActiveFilter
                          ? 'Belum ada dokter tersedia'
                          : 'Dokter tidak ditemukan',
                      emptyMessage: hasActiveFilter
                          ? 'Tidak ada dokter yang tersedia untuk klinik "${_selectedClinic?.displayName}". Coba pilih klinik lain atau hapus filter.'
                          : (_query.isEmpty
                              ? 'Silakan coba beberapa saat lagi.'
                              : 'Tidak ada dokter yang cocok dengan "$_query".'),
                      builder: (_) => _Results(
                        matches: matches,
                        totalCount: matches.length,
                        kind: widget.kind,
                        onProfileTap: _openProfile,
                        onBookTap: _handleBookAction,
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
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive ? AppColors.accentSoft : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.accentSoft
              : AppColors.border,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 22,
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
              tooltip: 'Tutup',
              icon: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
    required this.kind,
    required this.onProfileTap,
    required this.onBookTap,
  });

  final List<Doctor> matches;
  final int totalCount;
  final BookingKind? kind;
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
                Flexible(
                  child: Text(
                    'Daftar Dokter',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headingMd.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
          kind: kind,
          onProfileTap: () => onProfileTap(doctor),
          onBookTap: () => onBookTap(doctor),
        );
      },
    );
  }
}
