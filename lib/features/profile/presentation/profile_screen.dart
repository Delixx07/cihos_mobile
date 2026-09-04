import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/social_media_buttons.dart';
import '../../auth/application/auth_controller.dart';
import 'edit_profile_screen.dart';
import 'widgets/change_password_sheet.dart';
import 'widgets/faq_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _pushNotificationsEnabled = true;

  void _showSocialMediaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Media Sosial Resmi',
                style: AppTypography.headingMd.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Terhubung dengan Ciputra Hospital Surabaya melalui kanal resmi kami:',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialMediaCard(
                    title: 'WhatsApp',
                    subtitle: 'Customer Care',
                    button: WhatsAppIconButton(size: 36),
                  ),
                  SizedBox(width: AppSpacing.lg),
                  _SocialMediaCard(
                    title: 'Instagram',
                    subtitle: '@ciputrahospital',
                    button: InstagramIconButton(size: 36),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Kebijakan Privasi & Ketentuan',
                style: AppTypography.headingMd.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      '1. Perlindungan Data Rekam Medis\n'
                      'Ciputra Hospital Surabaya berkomitmen menjaga kerahasiaan seluruh informasi medis dan data pribadi pasien sesuai dengan peraturan perundang-undangan yang berlaku di Indonesia.\n\n'
                      '2. Keamanan Akun\n'
                      'Pengguna bertanggung jawab penuh atas kerahasiaan kata sandi dan aktivitas yang dilakukan melalui akun terdaftar.\n\n'
                      '3. Penggunaan Data\n'
                      'Data kontak hanya digunakan untuk konfirmasi janji temu dokter, pembaruan jadwal klinik, hasil pemeriksaan laboratorium/radiologi, dan informasi layanan kesehatan penting.\n\n'
                      '4. Hak Pasien\n'
                      'Pasien memiliki hak untuk mengakses ringkasan riwayat medis serta memperbarui informasi profil kapan saja melalui aplikasi.',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 13.5,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final fullName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : 'Pengguna';
    final photoUrl = user?.photoUrl;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      bottomNavigationBar: const AppBottomNav(current: AppTab.profile),
      body: Column(
        children: [
          // Header with linear gradient (0% #003366 to 100% #0047AB)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Top-right organic curved accent
                Positioned(
                  top: -70,
                  right: -60,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryLight.withValues(alpha: 0.5),
                          AppColors.primaryDark.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Bar: Back Button (Left) & Gear/Settings Button for Edit Profile (Right)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'Kembali',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  context.go(AppRoutes.home);
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Edit Profil',
                              icon: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 2),

                        // Center Avatar with thick white border
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _buildAvatar(photoUrl),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // User Name
                        Text(
                          fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email != null && user!.email.isNotEmpty
                              ? user.email
                              : 'Pasien Ciputra Hospital',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main White Card Content
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: Offset(0, -6),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    // Group 1: Sosial Media, Notifikasi, Janji Temu Saya
                    _ProfileMenuRow(
                      icon: Icons.share_outlined,
                      iconColor: AppColors.accentSoft,
                      title: 'Sosial Media',
                      onTap: () => _showSocialMediaSheet(context),
                    ),
                    _ProfileSwitchRow(
                      icon: Icons.notifications_active_outlined,
                      iconColor: AppColors.accentSoft,
                      title: 'Notifikasi',
                      value: _pushNotificationsEnabled,
                      onChanged: (val) {
                        setState(() => _pushNotificationsEnabled = val);
                      },
                    ),
                    _ProfileMenuRow(
                      icon: Icons.calendar_month_outlined,
                      iconColor: AppColors.accentSoft,
                      title: 'Janji Temu Saya',
                      onTap: () => context.go(AppRoutes.appointments),
                    ),
                    _ProfileMenuRow(
                      icon: Icons.favorite_outline_rounded,
                      iconColor: const Color(0xFFE11D48),
                      title: 'Favorit Saya',
                      onTap: () => context.push(AppRoutes.savedArticles),
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 20, thickness: 1, color: AppColors.divider),
                    const SizedBox(height: 8),

                    // Group 2: Privasi, Keamanan, Bantuan
                    _ProfileMenuRow(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppColors.accentSoft,
                      title: 'Privasi',
                      onTap: () => _showPrivacySheet(context),
                    ),
                    _ProfileMenuRow(
                      icon: Icons.shield_outlined,
                      iconColor: AppColors.accentSoft,
                      title: 'Keamanan',
                      onTap: () => ChangePasswordSheet.show(context),
                    ),
                    _ProfileMenuRow(
                      icon: Icons.help_outline_rounded,
                      iconColor: AppColors.accentSoft,
                      title: 'Bantuan',
                      onTap: () => FaqSheet.show(context),
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 20, thickness: 1, color: AppColors.divider),
                    const SizedBox(height: 8),

                    // Group 3: Logout (Red accent)
                    _ProfileMenuRow(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.danger,
                      title: 'Log out',
                      titleColor: AppColors.danger,
                      tooltip: 'Keluar',
                      onTap: () {
                        ref.read(authControllerProvider.notifier).signOut();
                        context.go(AppRoutes.onboarding);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final file = File(photoUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        );
      } else if (photoUrl.startsWith('http')) {
        return Image.network(
          photoUrl,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.person, size: 48, color: AppColors.textTertiary),
        );
      }
    }
    return Image.asset(
      'assets/images/avatar.jpg',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.person, size: 48, color: AppColors.textTertiary),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.tooltip,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip ?? title,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? AppColors.textPrimary,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: titleColor?.withValues(alpha: 0.5) ??
                      const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSwitchRow extends StatelessWidget {
  const _ProfileSwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 7,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Switch(
                value: value,
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFFA7F3D0),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialMediaCard extends StatelessWidget {
  const _SocialMediaCard({
    required this.title,
    required this.subtitle,
    required this.button,
  });

  final String title;
  final String subtitle;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          button,
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
