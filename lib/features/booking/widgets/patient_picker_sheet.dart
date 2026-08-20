import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/booking.dart';

/// The dark searchable sheet listing every patient on the account.
///
/// Pops the chosen patient, or null when dismissed.
class PatientPickerSheet extends StatefulWidget {
  const PatientPickerSheet({super.key, this.selected});

  final BookingPatient? selected;

  @override
  State<PatientPickerSheet> createState() => _PatientPickerSheetState();
}

class _PatientPickerSheetState extends State<PatientPickerSheet> {
  final _searchController = TextEditingController();

  late BookingPatient? _selected = widget.selected;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = BookingOptions.patients
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pilih Pasien',
                    style: AppTypography.inputText.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDDDFF3),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  color: const Color(0xFFDDDFF3),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: AppTypography.inputText.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Cari Pasien',
                hintStyle: AppTypography.inputText.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                ),
                filled: true,
                fillColor: const Color(0xFFD9D9D9),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Text(
                        'Pasien tidak ditemukan',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final patient = matches[index];
                        return InkWell(
                          onTap: () => setState(() => _selected = patient),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patient.name,
                                        style: AppTypography.inputText.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      Text(
                                        patient.medicalRecordNumber,
                                        style: AppTypography.inputText.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (patient.name == _selected?.name)
                                  const Icon(
                                    Icons.check,
                                    size: 20,
                                    color: AppColors.white,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.light(
              label: '+ Tambah Pasien Baru',
              expand: true,
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.patientType);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.light(
              label: 'Lanjutkan',
              expand: true,
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }
}
