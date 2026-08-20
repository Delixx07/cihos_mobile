import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../data/health_news_repository.dart';
import '../domain/health_article.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../core/widgets/staggered_entrance.dart';

/// The health-news feed: two swipeable shelves over a list of saved reads.
class HealthNewsScreen extends ConsumerWidget {
  const HealthNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(articlesByShelfProvider(ArticleShelf.latest));
    final others = ref.watch(articlesByShelfProvider(ArticleShelf.others));
    final reading = ref.watch(articlesByShelfProvider(ArticleShelf.reading));

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Info Kesehatan'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  children: [
                    const _ShelfTitle('Berita Terbaru'),
                    _Carousel(articles: latest),
                    const SizedBox(height: AppSpacing.xl),
                    const _ShelfTitle('Lainnya'),
                    _Carousel(articles: others),
                    const SizedBox(height: AppSpacing.xl),
                    const _ShelfTitle('Bacaan Anda'),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          for (final article in reading) ...[
                            Pressable(
                              scale: 0.98,
                              child: _ReadingRow(article: article),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
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
}

class _ShelfTitle extends StatelessWidget {
  const _ShelfTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Text(
        text,
        style: AppTypography.headingSm.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.accentSoft,
        ),
      ),
    );
  }
}

/// A horizontally swipeable strip of article cards.
class _Carousel extends StatelessWidget {
  const _Carousel({required this.articles});

  final List<HealthArticle> articles;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: articles.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xl),
        itemBuilder: (context, index) => StaggeredEntrance(
          index: index,
          child: Pressable(
            scale: 0.97,
            child: _CarouselCard(article: articles[index]),
          ),
        ),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.article});

  final HealthArticle article;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 253,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: SizedBox(
              height: 132,
              width: double.infinity,
              child: _Cover(article: article),
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                boxShadow: AppElevation.level2,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentSoft,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy', 'id_ID').format(article.date),
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentSoft,
                      ),
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
}

/// A saved read: thumbnail left, headline and "Baca Selengkapnya" right.
class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.article});

  final HealthArticle article;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppElevation.level2,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.all(7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: SizedBox(
                width: 138,
                height: 79,
                child: _Cover(article: article),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentSoft,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(article.date),
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentSoft,
                    ),
                  ),
                  Text(
                    'Baca Selengkapnya!',
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The article cover, or a tinted placeholder while the export is missing.
class _Cover extends StatelessWidget {
  const _Cover({required this.article});

  final HealthArticle article;

  @override
  Widget build(BuildContext context) {
    if (article.imageAsset == null) return const _CoverPlaceholder();

    return Image.asset(
      article.imageAsset!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _CoverPlaceholder(),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ImagePlaceholder(icon: Icons.article_outlined, iconSize: 32);
  }
}
