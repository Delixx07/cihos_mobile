import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

/// Wraps any tappable surface so it responds under the finger.
///
/// A tap should feel like it landed on something physical: the surface dips
/// slightly and its shadow settles, then springs back. [AppButton] carries its
/// own version of this; [Pressable] is for cards, tiles, and list rows, which
/// otherwise stay inert.
///
/// It uses [Listener] rather than a gesture recognizer so it observes the
/// pointer without competing for the gesture — whatever [InkWell] or
/// [GestureDetector] sits inside keeps handling the tap.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.duration = AppMotion.instant,
  });

  final Widget child;

  /// Optional: when supplied, [Pressable] handles the tap itself. Leave null
  /// if the child already has its own handler.
  final VoidCallback? onTap;

  /// How far the surface dips. Larger cards want a subtler value.
  final double scale;

  final Duration duration;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed != value) setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final surface = AnimatedScale(
      scale: _isPressed ? widget.scale : 1,
      duration: widget.duration,
      curve: Curves.easeOut,
      child: widget.child,
    );

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: widget.onTap == null
          ? surface
          : GestureDetector(onTap: widget.onTap, child: surface),
    );
  }
}
