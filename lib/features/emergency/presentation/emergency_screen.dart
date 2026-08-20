import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hero_panel_screen.dart';

/// Emergency department contact screen.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const _phone = '031-21021911';

  @override
  Widget build(BuildContext context) {
    return const HeroPanelScreen(
      heroAsset: 'assets/images/emergency_hero.jpg.png',
      title: 'Gawat Darurat',
      subtitle:
          'Dapatkan bantuan gawat darurat medis dari Ciputra Hospital Surabaya',
      children: [_CallCard(phone: _phone)],
    );
  }
}

class _CallCard extends StatelessWidget {
  const _CallCard({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(-1, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Color(0x17000000),
            offset: Offset(-2, 26),
            blurRadius: 26,
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          // Dialling needs url_launcher; copying the number keeps the action
          // useful without pulling in a plugin yet.
          onTap: () async {
            await Clipboard.setData(const ClipboardData(text: '03121021911'));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nomor IGD disalin.')),
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hubungi Kami',
                        style: AppTypography.headingSm.copyWith(
                          fontSize: 18,
                          color: AppColors.accentSoft,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_hospital,
                            size: 22,
                            color: AppColors.accentSoft,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                phone,
                                style: AppTypography.headingLg.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accentSoft,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.phone_in_talk,
                  size: 44,
                  color: AppColors.accentSoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
