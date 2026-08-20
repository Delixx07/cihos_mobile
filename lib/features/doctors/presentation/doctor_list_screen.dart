import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../data/doctor_repository.dart';
import '../domain/doctor.dart';
import 'widgets/doctor_card.dart';
import 'widgets/doctor_profile_sheet.dart';
import '../../../core/theme/app_elevation.dart';

/// Search across every doctor, with live name suggestions.
class DoctorListScreen extends ConsumerStatefulWidget {
  const DoctorListScreen({super.key});

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
    // The suggestion list only shows while the field has focus.
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
    context.push('${AppRoutes.doctorSchedule}/${doctor.id}');
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(doctorsProvider);
    final matches = doctors
        .where((d) => d.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    // Suggestions appear over the list while the patient is still typing.
    final showSuggestions = _searchFocus.hasFocus && matches.isNotEmpty;

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Cari Dokter'),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: _SearchBar(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Stack(
                  children: [
                    _Results(
                      matches: matches,
                      onProfileTap: _openProfile,
                      onBookTap: _book,
                    ),
                    if (showSuggestions)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                        ),
                        child: _Suggestions(
                          doctors: matches,
                          onTap: (doctor) {
                            _searchController.text = doctor.name;
                            setState(() => _query = doctor.name);
                            _searchFocus.unfocus();
                          },
                        ),
                      ),
                  ],
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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: AppColors.white),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              key: const Key('doctorSearch'),
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: AppTypography.bodySm.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
              cursorColor: AppColors.white,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'Cari Dokter',
                hintStyle: AppTypography.bodySm.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dropdown of matching names that hovers under the search bar.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.doctors, required this.onTap});

  final List<Doctor> doctors;
  final ValueChanged<Doctor> onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          boxShadow: AppElevation.level2,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          constraints: const BoxConstraints(maxHeight: 180),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: doctors.length,
            itemBuilder: (context, index) => InkWell(
              onTap: () => onTap(doctors[index]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 5,
                ),
                child: Text(
                  doctors[index].name,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDDDFF3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.matches,
    required this.onProfileTap,
    required this.onBookTap,
  });

  final List<Doctor> matches;
  final ValueChanged<Doctor> onProfileTap;
  final ValueChanged<Doctor> onBookTap;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Text('Dokter tidak ditemukan', style: AppTypography.bodyMd),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      itemCount: matches.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'Pilih Dokter',
            style: AppTypography.inputText.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
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
