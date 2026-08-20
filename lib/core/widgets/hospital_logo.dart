import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The Ciputra Hospital Surabaya wordmark.
///
/// Sizes are a fraction of the screen width rather than the fixed pixel values
/// the 393px Figma canvas produced — those render noticeably small on a real
/// 411dp-plus phone, where the mark should still be the anchor of the page.
/// All variants share the same 1.88:1 box, so a width fixes the height.
class HospitalLogo extends StatelessWidget {
  const HospitalLogo({super.key, required this.width})
    : _widthFactor = null,
      _maxWidth = null;

  /// Splash and onboarding — the mark carries the whole screen.
  const HospitalLogo.splash({super.key})
    : width = null,
      _widthFactor = 0.62,
      _maxWidth = 320;

  /// Above a form: large enough to read as branding, not a favicon.
  const HospitalLogo.medium({super.key})
    : width = null,
      _widthFactor = 0.46,
      _maxWidth = 220;

  /// Inline in a header or app bar.
  const HospitalLogo.small({super.key})
    : width = null,
      _widthFactor = 0.30,
      _maxWidth = 140;

  /// An explicit width, when the caller needs to pin the footprint.
  final double? width;

  final double? _widthFactor;
  final double? _maxWidth;

  static const _aspectRatio = 308 / 164;
  static const _logoPath = 'assets/images/Logo Ciputra Hospital Blue.png';

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final resolved =
        width ??
        (screen * _widthFactor!).clamp(0.0, _maxWidth!).toDouble();

    return SizedBox(
      width: resolved,
      height: resolved / _aspectRatio,
      child: Image.asset(
        _logoPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _LogoPlaceholder(width: resolved),
      ),
    );
  }
}

/// Stands in at the logo's exact footprint until the asset is exported, so
/// layouts read true in the meantime.
class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final scale = width / 308;

    return FittedBox(
      fit: BoxFit.contain,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_hospital_outlined,
            size: 44 * scale,
            color: AppColors.primary,
          ),
          SizedBox(height: 6 * scale),
          Text(
            'CIPUTRA HOSPITAL',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 30 * scale,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          Text(
            'SURABAYA',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 13 * scale,
              letterSpacing: 4 * scale,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Enhancing Life',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18 * scale,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
