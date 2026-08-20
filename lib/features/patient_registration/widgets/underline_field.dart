import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// A bold label over an underlined input — the field style used throughout
/// patient registration.
class UnderlineField extends StatelessWidget {
  const UnderlineField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.validator,
    this.helper,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final String? Function(String?)? validator;

  /// Explanatory copy shown under the field, as on the medical record number.
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            validator: validator,
            style: AppTypography.inputText,
            decoration: _underlineDecoration(hint),
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              helper!,
              style: AppTypography.bodySm.copyWith(
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The dropdown counterpart to [UnderlineField].
class UnderlineDropdown extends StatelessWidget {
  const UnderlineDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            validator: validator,
            style: AppTypography.inputText,
            icon: const Icon(Icons.expand_more, color: AppColors.textPrimary),
            decoration: _underlineDecoration(hint),
            hint: Text(hint, style: _hintStyle),
            items: [
              for (final option in options)
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// A read-only field that opens a date picker.
class UnderlineDateField extends StatelessWidget {
  const UnderlineDateField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String hint;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? Function(DateTime?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: FormField<DateTime>(
        initialValue: value,
        validator: validator,
        builder: (field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(label),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: value ?? DateTime(now.year - 25),
                    firstDate: DateTime(1900),
                    lastDate: now,
                  );

                  if (picked != null) {
                    field.didChange(picked);
                    onChanged(picked);
                  }
                },
                child: InputDecorator(
                  decoration: _underlineDecoration('').copyWith(
                    errorText: field.errorText,
                  ),
                  child: Text(
                    value == null
                        ? hint
                        : '${value!.day.toString().padLeft(2, '0')}/'
                              '${value!.month.toString().padLeft(2, '0')}/'
                              '${value!.year}',
                    style: value == null
                        ? _hintStyle
                        : AppTypography.inputText,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.inputText.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

TextStyle get _hintStyle => AppTypography.inputText.copyWith(
  color: AppColors.textPrimary.withValues(alpha: 0.65),
);

InputDecoration _underlineDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: _hintStyle,
    filled: false,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    border: _border(),
    enabledBorder: _border(),
    focusedBorder: _border(color: AppColors.accent, width: 1.5),
    errorBorder: _border(color: AppColors.danger),
    focusedErrorBorder: _border(color: AppColors.danger, width: 1.5),
  );
}

UnderlineInputBorder _border({
  Color color = const Color(0x803F4153),
  double width = 1,
}) {
  return UnderlineInputBorder(
    borderSide: BorderSide(color: color, width: width),
  );
}
