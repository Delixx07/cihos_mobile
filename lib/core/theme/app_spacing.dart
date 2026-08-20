/// Design tokens for spacing and corner radii, on a 4pt scale.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Horizontal inset of the dark registration card (29px each side of 393).
  static const cardH = 29.0;
}

abstract final class AppRadius {
  /// Badges and other small chips. The Figma values ranged 3-5px, which reads
  /// as an unintentional corner; 8px is the smallest radius that looks chosen.
  static const xs = 8.0;

  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;

  /// Bottom sheets and the large hero panels.
  static const xxl = 28.0;

  static const pill = 999.0;

  /// Buttons in the mockups.
  static const button = 8.0;

  /// Input fields inside the registration card.
  static const field = 11.0;

  /// The dark registration card itself.
  static const card = 47.0;
}

/// Fixed component sizes lifted straight from the Figma frames.
abstract final class AppSizes {
  /// Design canvas width; used to scale positions onto real screens.
  static const designWidth = 393.0;
  static const designHeight = 852.0;

  static const buttonWidth = 161.0;
  static const buttonHeight = 44.0;

  static const fieldWidth = 253.0;
  static const fieldHeight = 40.0;
}
