import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/health_article.dart';
import '../../../../core/widgets/image_placeholder.dart';

/// A modern, clean, and simple card in the "Info Kesehatan" list.
class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, this.onTap});

  final HealthArticle article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail with smooth rounded corners
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 94,
                  child: _buildThumbnail(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clean Category & Date metadata line (no colored container)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            article.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy', 'id_ID').format(article.date),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Title
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (article.summary != null &&
                        article.summary!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        article.summary!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.5,
                          height: 1.25,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Bottom metadata: Read Time & Read action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 11.5,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              article.readTime,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Baca',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 9.5,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildThumbnail() {
    final image = article.imageAsset;
    if (image == null || image.trim().isEmpty) {
      return const _ThumbnailPlaceholder();
    }
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.surface,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => const _ThumbnailPlaceholder(),
      );
    }
    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const _ThumbnailPlaceholder(),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ImagePlaceholder(icon: Icons.article_outlined);
  }
}
