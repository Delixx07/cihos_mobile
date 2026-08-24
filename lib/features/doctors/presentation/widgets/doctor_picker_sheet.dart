import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/illustrations.dart';
import '../../data/doctor_repository.dart';
import '../../domain/doctor.dart';

/// The searchable doctor list. Pops the chosen doctor, or null when
/// dismissed.
class DoctorPickerSheet extends ConsumerStatefulWidget {
  const DoctorPickerSheet({
    super.key,
    this.unitCode,
    this.selectedId,
  });

  final String? unitCode;
  final String? selectedId;

  @override
  ConsumerState<DoctorPickerSheet> createState() => _DoctorPickerSheetState();
}

class _DoctorPickerSheetState extends ConsumerState<DoctorPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  late String? _selectedId = widget.selectedId;
  String _query = '';
  Doctor? _selectedDoctor;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorQuery = DoctorQuery(unitCode: widget.unitCode, query: _query);
    final doctorsAsync = ref.watch(doctorSearchProvider(doctorQuery));

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
                      'Pilih Dokter',
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
            Center(child: Illustrations.wellness(size: 88)),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'Dokter mana yang ingin Anda temui?',
                style: AppTypography.inputText.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: AppTypography.bodySm.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Cari Dokter',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: AppColors.surface,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AsyncView(
                value: doctorsAsync,
                onRetry: () => ref.invalidate(doctorSearchProvider(doctorQuery)),
                isEmpty: (matches) => matches.isEmpty,
                emptyTitle: 'Dokter tidak ditemukan',
                builder: (matches) => ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final doctor = matches[index];
                    return InkWell(
                      onTap: () => setState(() {
                        _selectedId = doctor.id;
                        _selectedDoctor = doctor;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor.name,
                                    style: AppTypography.bodySm.copyWith(
                                      fontSize: 15,
                                      fontWeight: doctor.id == _selectedId
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    doctor.specialty,
                                    style: AppTypography.bodySm.copyWith(
                                      fontSize: 12,
                                      color: AppColors.textPrimary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (doctor.id == _selectedId)
                              const Icon(
                                Icons.check,
                                size: 18,
                                color: AppColors.accentSoft,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppButton(
                label: 'Tampilkan Hasil Pencarian',
                expand: true,
                background: AppColors.accentSoft,
                onPressed: () => Navigator.of(context).pop(_selectedDoctor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
