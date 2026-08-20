import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Fades a widget in while it rises a few pixels, delayed by its position in
/// the list.
///
/// A screen whose cards all appear at once reads as a static image. Letting
/// them arrive in sequence gives the eye an order to follow and makes the
/// screen feel assembled rather than pasted. The delay is small — the whole
/// list should finish well under half a second.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.offset = 16,
  });

  /// Position in the list; drives the delay before this item animates.
  final int index;

  final Widget child;

  /// How far the item travels upward as it fades in.
  final double offset;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );

  @override
  void initState() {
    super.initState();
    // Cap the delay so a long list does not leave later items waiting.
    final steps = widget.index.clamp(0, 8);
    Future<void>.delayed(AppMotion.stagger * steps, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _animation.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
