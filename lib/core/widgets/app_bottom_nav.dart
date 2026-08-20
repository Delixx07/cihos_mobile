import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// The five-tab bar along the bottom of the main screens.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current});

  final AppTab current;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.navBar,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      // SafeArea wraps the row rather than sitting inside a fixed-height box,
      // so the gesture inset is added to the bar instead of eating into it.
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final tab in AppTab.values)
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    isActive: tab == current,
                    onTap: () {
                      if (tab != current) context.go(tab.route);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AppTab {
  home(label: 'Beranda', icon: Icons.home, route: AppRoutes.home),
  appointments(
    label: 'Jadwal Temu',
    icon: Icons.calendar_month,
    route: AppRoutes.appointments,
  ),
  health(
    label: 'Sehat-mu',
    icon: Icons.favorite_outline,
    route: AppRoutes.health,
  ),
  history(label: 'Riwayat', icon: Icons.history, route: AppRoutes.history),
  profile(label: 'Profil', icon: Icons.person_outline, route: AppRoutes.profile);

  const AppTab({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final AppTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The design marks the active tab with a short rule above the icon.
    final color = isActive
        ? AppColors.accentSoft
        : AppColors.accentSoft.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: AppMotion.fast,
            height: 3,
            width: isActive ? 28 : 0,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 5),
          Icon(tab.icon, size: 23, color: color),
          const SizedBox(height: 3),
          Text(
            tab.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
