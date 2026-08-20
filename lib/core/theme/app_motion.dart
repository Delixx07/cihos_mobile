import 'package:flutter/animation.dart';

/// Durations and curves, so motion feels like one system rather than a set of
/// unrelated guesses.
///
/// The scale follows a simple rule: the further something travels and the more
/// of the screen it occupies, the longer it takes. Small feedback is nearly
/// instant; a full page change is the slowest thing in the app.
abstract final class AppMotion {
  /// Press feedback and colour changes — should feel immediate.
  static const instant = Duration(milliseconds: 110);

  /// Chips, toggles, and small reveals.
  static const fast = Duration(milliseconds: 180);

  /// The default: cards settling, sheets sliding, list items staggering in.
  static const normal = Duration(milliseconds: 280);

  /// Page transitions and anything crossing the whole screen.
  static const slow = Duration(milliseconds: 380);

  /// Decelerating: things entering the screen. Fast at first, gentle landing.
  static const enter = Curves.easeOutCubic;

  /// Accelerating: things leaving. The mirror of [enter].
  static const exit = Curves.easeInCubic;

  /// Symmetric, for changes that stay on screen — a colour or size shift.
  static const standard = Curves.easeInOutCubic;

  /// A slight overshoot for elements that should feel physical when they
  /// arrive, such as a success mark or a badge popping in.
  static const spring = Curves.easeOutBack;

  /// How far a page slides during a transition, as a fraction of its size.
  /// Small on purpose: large travel reads as sluggish at these durations.
  static const pageSlide = 0.03;

  /// Delay between consecutive items in a staggered list reveal.
  static const stagger = Duration(milliseconds: 55);
}
