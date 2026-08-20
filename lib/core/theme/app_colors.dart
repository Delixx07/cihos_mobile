import 'package:flutter/material.dart';

/// Design tokens for colors, based on the Ciputra Hospital Surabaya mockups.
///
/// The slate family ([accent], [accentSoft]) carries most surfaces, exactly as
/// the designs specify. What the mockups lacked was tonal depth: every panel
/// sat within a few percent of the same lightness, so nothing looked nearer or
/// further than anything else. The extra steps below fill that range without
/// changing the hues the hospital approved.
///
/// Semantic colours are tuned for contrast on white: the original green and
/// amber were too light to read at 12sp, which matters on a screen that tells
/// patients whether an appointment is confirmed or cancelled.
abstract final class AppColors {
  // Brand — the navy of the Ciputra Hospital wordmark.
  static const primary = Color(0xFF1B3A6B);
  static const primaryDark = Color(0xFF12294D);
  static const primaryLight = Color(0xFF3D5F94);
  static const primarySurface = Color(0xFFE9EEF6);

  /// The slate used for buttons, the registration card, and body copy.
  static const accent = Color(0xFF3F4153);
  static const accentDark = Color(0xFF2E3040);
  static const accentLight = Color(0xFF5C5E70);

  /// A slightly softer slate the later frames use for panels and field fills.
  static const accentSoft = Color(0xFF464960);

  /// One step lighter again, for nested surfaces inside a slate panel — a
  /// selected row, or a card sitting on another card.
  static const accentMuted = Color(0xFF5A5D75);

  /// A pale slate wash for resting states and disabled fills on white.
  static const accentWash = Color(0xFFEEEFF4);

  /// Notification rows.
  static const mint = Color(0xFFC7E8E8);

  /// The pale lavender the designs pair with [accentSoft] — badge fills and
  /// label text sitting on the slate panels.
  static const lavender = Color(0xFFDDDFF3);

  /// Link text, as on "Tandai semua telah dibaca".
  static const link = Color(0xFF0077B6);

  /// Bottom navigation bar.
  static const navBar = Color(0xFFDFE3E9);

  // Neutrals
  static const textPrimary = Color(0xFF3F4153);
  static const textSecondary = Color(0xFF6B6D7C);
  static const textTertiary = Color(0xFF9A9AA5);

  /// Text on the dark accent card.
  static const onAccent = Color(0xFFFFFFFF);
  static const onAccentMuted = Color(0xFFD5D2DC);

  static const border = Color(0xFFE2E2E8);
  static const divider = Color(0xFFEFEFF3);
  static const white = Color(0xFFFFFFFF);

  /// Page background — a photo sits over this at 46% opacity.
  static const background = Color(0xFFFFFFFF);

  /// Input field fill inside the dark card, and the light button face.
  static const surface = Color(0xFFF6F7F9);

  // Semantic — darkened from the mockups so 12sp label text stays legible.
  static const success = Color(0xFF11833F);
  static const successSurface = Color(0xFFE4F5EA);
  static const warning = Color(0xFFB26B00);
  static const warningSurface = Color(0xFFFDF1DD);
  static const danger = Color(0xFFB02A1E);
  static const dangerSurface = Color(0xFFFAE7E5);
  static const info = Color(0xFF1B3A6B);
  static const infoSurface = Color(0xFFE9EEF6);
}
