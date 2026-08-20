import 'package:flutter/material.dart';

/// Layered shadows for depth.
///
/// The Figma export uses a single hard `0 4px 4px rgba(0,0,0,0.25)` on every
/// surface, which reads as a dated drop shadow rather than elevation. These
/// stack a tight contact shadow under a wider, softer ambient one — the way
/// real light falls — so cards lift off the page instead of sitting on a grey
/// smudge.
abstract final class AppElevation {
  /// Chips, badges, and other small surfaces that barely lift.
  static const level1 = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D1B2340),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x0A1B2340),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];

  /// The default for cards in a list.
  static const level2 = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F1B2340),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x141B2340),
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: -4,
    ),
  ];

  /// Panels and hero surfaces that anchor a screen.
  static const level3 = <BoxShadow>[
    BoxShadow(
      color: Color(0x121B2340),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x1A1B2340),
      offset: Offset(0, 12),
      blurRadius: 28,
      spreadRadius: -6,
    ),
  ];

  /// Bottom sheets and dialogs, which float above everything.
  static const level4 = <BoxShadow>[
    BoxShadow(
      color: Color(0x141B2340),
      offset: Offset(0, -2),
      blurRadius: 8,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x241B2340),
      offset: Offset(0, -8),
      blurRadius: 32,
      spreadRadius: -8,
    ),
  ];

  /// A pressed card settles closer to the page.
  static const pressed = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F1B2340),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: -1,
    ),
  ];
}
