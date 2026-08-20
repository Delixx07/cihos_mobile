import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../booking/domain/booking.dart';
import '../../domain/doctor.dart';
import 'consultation_method_card.dart';

/// "Buat Appointment?" — pick a consultation method for [doctor].
///
/// Pops the chosen [BookingKind], or null when dismissed. Only the methods the
/// doctor actually offers are listed.
class AppointmentMethodSheet extends StatefulWidget {
  const AppointmentMethodSheet({super.key, required this.doctor});

  final Doctor doctor;

  @override
  State<AppointmentMethodSheet> createState() => _AppointmentMethodSheetState();
}

class _AppointmentMethodSheetState extends State<AppointmentMethodSheet> {
  late BookingKind _selected = _available.first;

  List<BookingKind> get _available => [
    if (widget.doctor.supports(ConsultationMethod.appointment))
      BookingKind.appointment,
    if (widget.doctor.supports(ConsultationMethod.videoCall))
      BookingKind.videoCall,
  ];

  @override
  Widget build(BuildContext context) {
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
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Buat Appointment?',
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
            const SizedBox(height: AppSpacing.md),
            for (final kind in _available) ...[
              ConsultationMethodCard(
                key: Key('method_${kind.name}'),
                kind: kind,
                isSelected: kind == _selected,
                onSelect: () => setState(() => _selected = kind),
                onConfirm: () => Navigator.of(context).pop(kind),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}
