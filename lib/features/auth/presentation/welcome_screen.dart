import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hospital_logo.dart';
import '../../../core/widgets/textured_background.dart';
import '../application/auth_controller.dart';

/// Splash screen — the wordmark fades in above "MOBILE APPS", then hands off
/// to patient registration.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Restores a stored session while the splash plays, then routes on.
  ///
  /// Both run concurrently so a returning patient does not wait for the
  /// network on top of the splash: whichever finishes last decides when the
  /// app moves on.
  Future<void> _bootstrap() async {
    // Providers cannot be modified while the first frame is building, so let
    // that frame finish before touching auth state.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final restore = ref.read(authControllerProvider.notifier).restoreSession();
    await Future.wait([
      restore,
      Future<void>.delayed(const Duration(milliseconds: 2200)),
    ]);

    if (!mounted) return;
    context.go(
      ref.read(authControllerProvider).isSignedIn
          ? AppRoutes.home
          : AppRoutes.onboarding,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TexturedBackground(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(_fade),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HospitalLogo.splash(),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('MOBILE APPS', style: AppTypography.splashTagline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
