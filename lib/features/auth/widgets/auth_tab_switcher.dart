import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

enum AuthTabType { login, register }

/// Modern pill-shaped tab switcher (Masuk | Daftar) matching the reference design.
class AuthTabSwitcher extends StatelessWidget {
  const AuthTabSwitcher({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    this.loginKey,
    this.registerKey,
  });

  final AuthTabType currentTab;
  final ValueChanged<AuthTabType> onTabChanged;
  final Key? loginKey;
  final Key? registerKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          // Tab 1: Masuk
          Expanded(
            child: _TabButton(
              key: loginKey,
              label: 'Masuk',
              isActive: currentTab == AuthTabType.login,
              onTap: () => onTabChanged(AuthTabType.login),
            ),
          ),
          // Tab 2: Daftar
          Expanded(
            child: _TabButton(
              key: registerKey,
              label: 'Daftar',
              isActive: currentTab == AuthTabType.register,
              onTap: () => onTabChanged(AuthTabType.register),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.primaryGradient : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
