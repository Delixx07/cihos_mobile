import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/textured_background.dart';

/// Entry point for checking a queue by medical record number — clinic or
/// pharmacy.
class CheckQueueScreen extends StatelessWidget {
  const CheckQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: TexturedBackground(
        child: Stack(
          children: [
            // Image positioned safely below the back button area, extending downwards
            Positioned(
              top: topPadding + 92,
              left: 0,
              right: 0,
              height: screenHeight * 0.50,
              child: Image.asset(
                'assets/images/cek antrean.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(
                      Icons.queue_outlined,
                      size: 64,
                      color: AppColors.accentSoft,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Dark Blue Panel with extended height to clearly overlap and cover the bottom of the image
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: screenHeight * 0.38,
                decoration: const BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      offset: Offset(0, -6),
                      blurRadius: 24,
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xxxl,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Cek Antrian',
                        textAlign: TextAlign.center,
                        style: AppTypography.headingLg.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Cek status antrian berdasarkan nomor rekam medis Anda.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 13.5,
                          height: 1.4,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Expanded(
                            child: _QueueMenuCard(
                              label: 'Klinik',
                              icon: Icons.local_hospital_outlined,
                              onTap: () => context.push(AppRoutes.queueMonitor),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: _QueueMenuCard(
                              label: 'Farmasi',
                              icon: Icons.medication_outlined,
                              onTap: () => context.push(AppRoutes.queueMonitor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Standard Dark Back Button sitting cleanly at top in clear area
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child: AppBackButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueMenuCard extends StatelessWidget {
  const _QueueMenuCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
