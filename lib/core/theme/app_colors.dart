import 'package:flutter/material.dart';

/// Design tokens for colors across the application, with the dominant brand
/// theme defined by the linear gradient:
/// - 0%: #003366 (Deep Navy Blue)
/// - 100%: #0047AB (Cobalt / Royal Blue)
abstract final class AppColors {
  // Brand Linear Gradient Tokens (0% #003366 -> 100% #0047AB)
  static const gradientStart = Color(0xFF003366);
  static const gradientEnd = Color(0xFF0047AB);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF003366), Color(0xFF0047AB)],
  );

  static const primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF003366), Color(0xFF0047AB)],
  );

  static const primaryGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF003366), Color(0xFF0047AB)],
  );

  // Core Brand Colors
  static const primary = Color(0xFF0047AB);
  static const primaryDark = Color(0xFF003366);
  static const primaryLight = Color(0xFF1E60C6);
  static const primarySurface = Color(0xFFEBF2FA);

  /// The primary action / accent family mapped to the navy & cobalt palette
  static const accent = Color(0xFF003366);
  static const accentDark = Color(0xFF002244);
  static const accentLight = Color(0xFF0047AB);

  /// Panel background and field fills
  static const accentSoft = Color(0xFF003366);

  /// Nested surfaces and highlights
  static const accentMuted = Color(0xFF0047AB);

  /// Pale wash for resting states and disabled fills on white
  static const accentWash = Color(0xFFEBF2FA);

  /// Notification rows and badges
  static const mint = Color(0xFFCBE5FC);

  /// Pale tint for chips and contrast on dark panels
  static const lavender = Color(0xFFD4E3FB);

  /// Link text
  static const link = Color(0xFF0047AB);

  /// Bottom navigation bar
  static const navBar = Color(0xFFE6EEF8);

  // Neutrals
  static const textPrimary = Color(0xFF0F1E36);
  static const textSecondary = Color(0xFF4A5568);
  static const textTertiary = Color(0xFF8C9BAE);

  /// Text on dark accent cards/headers
  static const onAccent = Color(0xFFFFFFFF);
  static const onAccentMuted = Color(0xFFD4E3FB);

  static const border = Color(0xFFDDE6F2);
  static const divider = Color(0xFFE8EFF8);
  static const white = Color(0xFFFFFFFF);

  /// Page background
  static const background = Color(0xFFFFFFFF);

  /// Input field fill inside cards, and light button face
  static const surface = Color(0xFFF4F7FC);

  // Semantic
  static const success = Color(0xFF11833F);
  static const successSurface = Color(0xFFE4F5EA);
  static const warning = Color(0xFFB26B00);
  static const warningSurface = Color(0xFFFDF1DD);
  static const danger = Color(0xFFB02A1E);
  static const dangerSurface = Color(0xFFFAE7E5);
  static const info = Color(0xFF0047AB);
  static const infoSurface = Color(0xFFEBF2FA);
}
