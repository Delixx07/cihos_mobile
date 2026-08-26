import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/async_view.dart';
import '../../doctors/data/catalog_repository.dart';
import '../../doctors/domain/clinic.dart';

/// The searchable specialty list, opened from the booking search panel or doctor filter.
///
/// Pops the chosen clinic, or an empty clinic / null when cleared or dismissed.
class SpecialtyPickerSheet extends ConsumerStatefulWidget {
  const SpecialtyPickerSheet({
    super.key,
    this.selected,
    this.title = 'Pilih Spesialisasi / Klinik',
    this.searchHint = 'Cari Spesialisasi atau Klinik',
    this.hasClearOption = false,
  });

  final Clinic? selected;
  final String title;
  final String searchHint;
  final bool hasClearOption;

  @override
  ConsumerState<SpecialtyPickerSheet> createState() =>
      _SpecialtyPickerSheetState();
}

class _SpecialtyPickerSheetState extends ConsumerState<SpecialtyPickerSheet> {
  final _searchController = TextEditingController();

  late final Clinic? _selected = widget.selected;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clinicsAsync = ref.watch(clinicsProvider);
    final matches = clinicsAsync.maybeWhen(
      data: (clinics) => clinics
          .where(
            (c) => c.displayName.toLowerCase().contains(_query.toLowerCase()) ||
                c.name.toLowerCase().contains(_query.toLowerCase()),
          )
          .toList(),
      orElse: () => const <Clinic>[],
    );

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
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.headingMd.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.hasClearOption && _selected != null)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(const Clinic(code: '', name: '')),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: AppColors.danger,
                      ),
                      child: const Text(
                        'Hapus Filter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: AppTypography.bodySm.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
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
                value: clinicsAsync,
                onRetry: () => ref.invalidate(clinicsProvider),
                isEmpty: (_) => matches.isEmpty,
                emptyTitle: 'Spesialisasi tidak ditemukan',
                builder: (_) => ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  itemCount: matches.length + (widget.hasClearOption ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (widget.hasClearOption && index == 0) {
                      final isAllSelected = _selected == null || _selected.code.isEmpty;
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(const Clinic(code: '', name: '')),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Semua Klinik & Spesialisasi',
                                  style: AppTypography.bodySm.copyWith(
                                    fontSize: 15,
                                    fontWeight: isAllSelected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: isAllSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isAllSelected)
                                const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    final clinic = matches[widget.hasClearOption ? index - 1 : index];
                    final isSelected = clinic.code == _selected?.code && clinic.code.isNotEmpty;
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(clinic),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                clinic.displayName,
                                style: AppTypography.bodySm.copyWith(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                size: 18,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
