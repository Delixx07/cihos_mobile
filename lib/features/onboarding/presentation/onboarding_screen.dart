import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/textured_background.dart';
import '../../auth/widgets/auth_artwork.dart';

/// Onboarding / Welcome Screen with prominent Ciputra Hospital logo and layout from reference.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(_fadeAnimation);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: TexturedBackground(
        child: Stack(
          children: [
            // Top Artwork with Large Ciputra Hospital Logo & Registration Illustration
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.58,
              child: AuthArtwork(
                height: screenHeight * 0.58,
                showLogo: true,
                isLargeLogo: true,
                showIllustration: true,
              ),
            ),

            // Bottom Curved White Content Card (layout from reference)
            Positioned.fill(
              top: screenHeight * 0.60,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A003366),
                          blurRadius: 24,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          AppSpacing.xl,
                          AppSpacing.xxl,
                          AppSpacing.xl,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title & Subtitle
                            Text(
                              'Selamat Datang!',
                              textAlign: TextAlign.center,
                              style: AppTypography.headingLg.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Kesehatan Anda dan keluarga adalah prioritas kami. '
                              'Masuk atau buat akun baru untuk mengakses layanan Ciputra Hospital.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMd.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Primary Gradient Button: Buat Akun
                            AppButton(
                              key: const Key('onboardingRegister'),
                              label: 'Buat Akun',
                              expand: true,
                              height: 52,
                              borderRadius: 26,
                              onPressed: () => context.go(AppRoutes.register),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Secondary Button: Masuk
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: () => context.go(AppRoutes.login),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFDDE6F2),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: Text(
                                  'Masuk',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
