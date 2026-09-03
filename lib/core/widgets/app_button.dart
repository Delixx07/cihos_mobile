import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_motion.dart';
import '../theme/app_typography.dart';

/// The rounded button used across the app, carrying the linear gradient
/// (0% #003366 to 100% #0047AB) and dipping slightly under the finger.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
    this.isLoading = false,
    this.background,
    this.gradient = AppColors.primaryGradient,
    this.foreground = AppColors.white,
    this.width,
    this.borderRadius,
    this.height,
  });

  /// Light face — used for actions inside the dark auth card.
  const AppButton.light({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
    this.isLoading = false,
    this.width,
    this.borderRadius,
    this.height,
  }) : background = AppColors.white,
       gradient = null,
       foreground = AppColors.primaryDark;

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final bool isLoading;
  final Color? background;
  final Gradient? gradient;
  final Color foreground;
  final double? width;
  final double? borderRadius;
  final double? height;

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
      onPointerDown: isEnabled ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: _buildButton(isEnabled),
    );
  }

  Widget _buildButton(bool isEnabled) {
    final radius = widget.borderRadius ?? AppRadius.button;
    final height = widget.height ?? AppSizes.buttonHeight;

    return AnimatedScale(
      scale: _isPressed && isEnabled ? 0.96 : 1,
      duration: AppMotion.instant,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: isEnabled ? 1 : 0.7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isEnabled ? widget.gradient : null,
            color: widget.gradient == null
                ? (widget.background ?? AppColors.primary)
                : (isEnabled ? null : AppColors.primaryDark),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: isEnabled && !_isPressed
                ? const [
                    BoxShadow(
                      color: Color(0x33003366),
                      offset: Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            width: widget.expand
                ? double.infinity
                : (widget.width ?? AppSizes.buttonWidth),
            height: height,
            child: FilledButton(
              onPressed: isEnabled ? widget.onPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: widget.foreground,
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor:
                    widget.foreground.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
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
          : Text(
              label,
              key: ValueKey(label),
              style: AppTypography.button.copyWith(color: foreground),
            ),
    );
  }
}
