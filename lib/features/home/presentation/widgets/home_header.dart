import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/hospital_logo.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../notifications/application/notifications_controller.dart';

/// Logo, greeting, notification bell, and the emergency shortcut.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final unread = ref.watch(unreadNotificationCountProvider);
    final firstName = user?.fullName.split(' ').first ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HospitalLogo.small(),
            const Spacer(),
            _BellButton(
              unread: unread,
              onTap: () => context.push(AppRoutes.notifications),
            ),
            const SizedBox(width: AppSpacing.md),
            const _EmergencyChip(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Halo, $firstName!', style: AppTypography.titleMd.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        )),
      ],
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifikasi',
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.danger,
        label: Text('$unread'),
        child: const Icon(
          Icons.notifications,
          size: 26,
          color: AppColors.accentSoft,
        ),
      ),
    );
  }
}

class _EmergencyChip extends StatelessWidget {
  const _EmergencyChip();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFD8D8),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: () => context.push(AppRoutes.emergency),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emergency,
                size: 16,
                color: Color(0xFFE74949),
              ),
              SizedBox(width: 5),
              Text(
                'IGD',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE74949),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
