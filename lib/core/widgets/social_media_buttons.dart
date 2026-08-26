import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Centralized social media links and external launcher helpers
class AppSocialLinks {
  const AppSocialLinks._();

  static const String whatsappUrl = 'https://wa.me/628988610008';
  static const String instagramUrl =
      'https://www.instagram.com/ciputrahospitalsurabaya?igsh=NWhnd20yZDRqN3Jr';

  /// Open external URL safely in external browser or application
  static Future<void> openUrl(String urlString, {BuildContext? context}) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka link: $urlString'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

/// A collapsible floating sidebar on the right screen edge for Home screen
class CollapsibleSocialSidebar extends StatefulWidget {
  const CollapsibleSocialSidebar({
    super.key,
    this.whatsappUrl = AppSocialLinks.whatsappUrl,
    this.instagramUrl = AppSocialLinks.instagramUrl,
  });

  final String whatsappUrl;
  final String instagramUrl;

  @override
  State<CollapsibleSocialSidebar> createState() =>
      _CollapsibleSocialSidebarState();
}

class _CollapsibleSocialSidebarState extends State<CollapsibleSocialSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 50) {
            // Swiped right -> collapse / penyetkan ke kanan
            setState(() => _isCollapsed = true);
          } else if (details.primaryVelocity! < -50) {
            // Swiped left -> expand
            setState(() => _isCollapsed = false);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(_isCollapsed ? 12 : 16),
          ),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(-2, 3),
            ),
          ],
        ),
        child: _isCollapsed ? _buildCollapsedHandle() : _buildExpandedContent(),
      ),
    );
  }

  Widget _buildCollapsedHandle() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _isCollapsed = false);
        },
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFE1306C),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 3, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapse button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isCollapsed = true);
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Direct WhatsApp Icon (No inner box container)
          Material(
            color: Colors.transparent,
            child: InkResponse(
              onTap: () =>
                  AppSocialLinks.openUrl(widget.whatsappUrl, context: context),
              radius: 18,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Color(0xFF25D366),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Direct Instagram Icon (No inner box container)
          Material(
            color: Colors.transparent,
            child: InkResponse(
              onTap: () =>
                  AppSocialLinks.openUrl(widget.instagramUrl, context: context),
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF833AB4),
                      Color(0xFFFD1D1D),
                      Color(0xFFFCAF45),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ).createShader(bounds),
                  child: const FaIcon(
                    FontAwesomeIcons.instagram,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone direct icon button for WhatsApp (without surrounding background container)
class WhatsAppIconButton extends StatelessWidget {
  const WhatsAppIconButton({
    super.key,
    this.url = AppSocialLinks.whatsappUrl,
    this.size = 28,
  });

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: () => AppSocialLinks.openUrl(url, context: context),
        radius: size,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: FaIcon(
            FontAwesomeIcons.whatsapp,
            color: const Color(0xFF25D366),
            size: size,
          ),
        ),
      ),
    );
  }
}

/// Standalone direct icon button for Instagram (without surrounding background container)
class InstagramIconButton extends StatelessWidget {
  const InstagramIconButton({
    super.key,
    this.url = AppSocialLinks.instagramUrl,
    this.size = 28,
  });

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: () => AppSocialLinks.openUrl(url, context: context),
        radius: size,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF833AB4),
                Color(0xFFFD1D1D),
                Color(0xFFFCAF45),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ).createShader(bounds),
            child: FaIcon(
              FontAwesomeIcons.instagram,
              color: Colors.white,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}

/// A modern social media contact card providing WhatsApp and Instagram quick actions.
class SocialContactCard extends StatelessWidget {
  const SocialContactCard({
    super.key,
    this.title = 'Pusat Bantuan & Informasi',
    this.subtitle =
        'Punya pertanyaan seputar jadwal dokter, fasilitas, atau layanan rumah sakit? Hubungi & ikuti kami.',
    this.whatsappUrl = AppSocialLinks.whatsappUrl,
    this.instagramUrl = AppSocialLinks.instagramUrl,
  });

  final String title;
  final String subtitle;
  final String whatsappUrl;
  final String instagramUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headingSm.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.bodySm.copyWith(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              // WhatsApp Button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        AppSocialLinks.openUrl(whatsappUrl, context: context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF25D366),
                            Color(0xFF128C7E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF25D366).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Instagram Button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        AppSocialLinks.openUrl(instagramUrl, context: context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF833AB4),
                            Color(0xFFFD1D1D),
                            Color(0xFFFCAF45),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFE1306C).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.instagram,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
