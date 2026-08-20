import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_motion.dart';

/// The rounded button used across the app, carrying the drop shadow the design
/// specifies and dipping slightly under the finger.
///
/// Defaults to the 161x44 footprint from the mockups; pass [expand] to let it
/// fill the available width instead.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
    this.isLoading = false,
    this.background = AppColors.accent,
    this.foreground = AppColors.surface,
  });

  /// Light face — used for actions inside the dark auth card.
  const AppButton.light({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
    this.isLoading = false,
  }) : background = AppColors.surface,
       foreground = AppColors.accent;

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final bool isLoading;
  final Color background;
  final Color foreground;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed != value) setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return Listener(
      // Listener observes the gesture without competing for it, so the
      // button's own tap handling stays intact.
      onPointerDown: isEnabled ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: _buildButton(isEnabled),
    );
  }

  Widget _buildButton(bool isEnabled) {
    return AnimatedScale(
      scale: _isPressed && isEnabled ? 0.96 : 1,
      duration: AppMotion.instant,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: isEnabled ? 1 : 0.7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: isEnabled && !_isPressed
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            width: widget.expand ? double.infinity : AppSizes.buttonWidth,
            height: AppSizes.buttonHeight,
            child: FilledButton(
              onPressed: isEnabled ? widget.onPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: widget.background,
                foregroundColor: widget.foreground,
              ),
              child: _ButtonContent(
                label: widget.label,
                isLoading: widget.isLoading,
                foreground: widget.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    required this.foreground,
  });

  final String label;
  final bool isLoading;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: foreground,
              ),
            )
          : Text(label, key: ValueKey(label)),
    );
  }
}
