import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/hospital_logo.dart';
import '../../../core/widgets/textured_background.dart';
import '../application/auth_controller.dart';

/// Splash screen — prominently presents the animated hospital logo upon startup.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.85,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.9, curve: Curves.easeOutBack),
    ),
  );

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Restores a stored session while the splash plays, then routes on.
  Future<void> _bootstrap() async {
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
              scale: _scale,
              child: const HospitalLogo.splash(),
            ),
          ),
        ),
      ),
    );
  }
}
