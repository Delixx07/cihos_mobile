import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/image_placeholder.dart';

/// The swipeable promo banner below the greeting, loaded dynamically from Laravel CMS API.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController();
  int _page = 0;

  static const _fallbackSlides = [
    'assets/images/banner/cihos1.jpg',
    'assets/images/promo/gmcu.jpg',
    'assets/images/promo/hair skin.png',
    'assets/images/promo/mri screening.jpg',
  ];

  List<String> _bannerUrls = [];

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  Future<void> _fetchPromotions() async {
    try {
      final dio = Dio(
        BaseOptions(
          headers: {
            'Accept': 'application/json',
            'X-Api-Key': AppConfig.cmsApiKey.isNotEmpty
                ? AppConfig.cmsApiKey
                : AppConfig.apiKey,
          },
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final response = await dio.get('${AppConfig.cmsBaseUrl}/api/promotions');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic body = response.data;
        final data = body is Map
            ? (body['data'] is List
                ? body['data']
                : (body['promotions'] is List ? body['promotions'] : null))
            : (body is List ? body : null);

        if (data is List && data.isNotEmpty) {
          final urls = <String>[];
          for (final item in data) {
            if (item is Map) {
              final raw = item['image_url'] ??
                  item['image'] ??
                  item['banner_url'] ??
                  item['banner'] ??
                  item['thumbnail'];
              final resolved = AppConfig.resolveCmsImageUrl(raw);
              if (resolved != null && resolved.isNotEmpty) {
                urls.add(resolved);
              }
            }
          }
          if (urls.isNotEmpty && mounted) {
            setState(() {
              _bannerUrls = urls;
            });
            return;
          }
        }
      }
    } catch (_) {
      // Fallback silently to bundled asset slides
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _bannerUrls.isNotEmpty ? _bannerUrls : _fallbackSlides;
    final isNetwork = _bannerUrls.isNotEmpty;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentSoft.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: isNetwork
                    ? CachedNetworkImage(
                        imageUrl: slides[index],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: AppColors.white,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          _fallbackSlides[index % _fallbackSlides.length],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : Image.asset(
                        slides[index],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const ImagePlaceholder(
                          icon: Icons.local_offer_outlined,
                          iconSize: 34,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: AppMotion.fast,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: i == _page ? 20 : 6,
                decoration: BoxDecoration(
                  color: i == _page
                      ? AppColors.primary
                      : AppColors.accentSoft.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
