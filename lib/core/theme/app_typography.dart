import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles taken from the Figma CSS export.
///
/// Kumbh Sans carries headings and body copy; Inter is used only for button
/// labels, matching the component library the design pulled buttons from.
abstract final class AppTypography {
  static TextStyle _kumbh(
    double size,
    FontWeight weight, {
    double? lineHeight,
    Color color = AppColors.textPrimary,
  }) => GoogleFonts.kumbhSans(
    fontSize: size,
    fontWeight: weight,
    // Figma gives line-height in px; Flutter wants a multiplier.
    height: lineHeight == null ? null : lineHeight / size,
    color: color,
  );

  // Splash: "MOBILE APPS" — 24px/30px, weight 600.
  static TextStyle get splashTagline =>
      _kumbh(24, FontWeight.w600, lineHeight: 30);

  // Screen titles: "Registrasi Pasien" — 24px/30px, weight 700.
  static TextStyle get headingLg => _kumbh(24, FontWeight.w700, lineHeight: 30);

  // Card title: "Pendaftaran Pasien Baru" — 20px/25px, weight 700, white.
  static TextStyle get headingMd =>
      _kumbh(20, FontWeight.w700, lineHeight: 25, color: AppColors.onAccent);

  static TextStyle get headingSm => _kumbh(18, FontWeight.w600, lineHeight: 23);

  // Field labels inside the dark card — 15px/19px, weight 400, white.
  static TextStyle get fieldLabel =>
      _kumbh(15, FontWeight.w400, lineHeight: 19, color: AppColors.onAccent);

  // Input text and placeholders — 15px/19px, weight 400.
  static TextStyle get inputText => _kumbh(15, FontWeight.w400, lineHeight: 19);

  // Supporting copy: the welcome paragraph — 13px/16px, weight 700.
  static TextStyle get bodyStrong =>
      _kumbh(13, FontWeight.w700, lineHeight: 16);

  static TextStyle get bodyLg => _kumbh(16, FontWeight.w400, lineHeight: 24);
  static TextStyle get bodyMd => _kumbh(14, FontWeight.w400, lineHeight: 21);
  static TextStyle get bodySm => _kumbh(12, FontWeight.w400, lineHeight: 18);

  static TextStyle get titleLg => _kumbh(16, FontWeight.w600, lineHeight: 23);
  static TextStyle get titleMd => _kumbh(14, FontWeight.w600, lineHeight: 20);

  /// Button labels — Inter 14px, weight 600, 140% line height.
  static TextStyle get button =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle get labelLg => _kumbh(14, FontWeight.w600, lineHeight: 20);
  static TextStyle get labelMd => _kumbh(12, FontWeight.w500, lineHeight: 17);

  static TextStyle get caption => _kumbh(
    12,
    FontWeight.w400,
    lineHeight: 17,
    color: AppColors.textSecondary,
  );
}
