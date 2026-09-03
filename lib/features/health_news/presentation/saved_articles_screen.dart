import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/textured_background.dart';
import '../data/health_news_repository.dart';
import '../data/saved_articles_repository.dart';
import '../domain/health_article.dart';

/// Screen displaying the patient's favorite health articles ("Favorit Saya").
class SavedArticlesScreen extends ConsumerWidget {
  const SavedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedArticles = ref.watch(savedArticlesProvider);

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Favorit Saya',
                            style: AppTypography.headingLg.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${savedArticles.length} artikel difavoritkan',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Content List or Empty State
              Expanded(
                child: savedArticles.isEmpty
                    ? _EmptySavedArticles(
                        onExplore: () => context.push(AppRoutes.healthNews),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.md,
                          AppSpacing.xl,
                          AppSpacing.xxxl,
                        ),
                        itemCount: savedArticles.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final article = savedArticles[index];
                          return Pressable(
                            scale: 0.98,
                            child: _SavedArticleCard(
                              article: article,
                              onTap: () => context.push(
                                '${AppRoutes.healthNews}/${article.id}',
                                extra: article,
                              ),
                              onRemove: () async {
                                await ref
                                    .read(savedArticleIdsProvider.notifier)
                                    .remove(article.id);
                                await ref
                                    .read(healthArticlesProvider.notifier)
                                    .toggleLike(article.id, false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Artikel "${article.title}" dihapus dari Favorit Saya.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'Batal',
                                        textColor: AppColors.link,
                                        onPressed: () {
                                          ref
                                              .read(
                                                savedArticleIdsProvider
                                                    .notifier,
                                              )
                                              .add(article.id);
                                          ref
                                              .read(
                                                healthArticlesProvider
                                                    .notifier,
                                              )
                                              .toggleLike(article.id, true);
                                        },
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
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

class _SavedArticleCard extends StatelessWidget {
  const _SavedArticleCard({
    required this.article,
    required this.onTap,
    required this.onRemove,
  });

  final HealthArticle article;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('dd MMM yyyy', 'id_ID').format(article.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentSoft.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 105,
                  height: 90,
                  child: () {
                    final img = article.imageAsset;
                    if (img == null || img.trim().isEmpty) {
                      return const ImagePlaceholder(icon: Icons.article_outlined);
                    }
                    if (img.startsWith('http://') || img.startsWith('https://')) {
                      return CachedNetworkImage(
                        imageUrl: img,
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
                        errorWidget: (context, url, error) =>
                            const ImagePlaceholder(icon: Icons.article_outlined),
                      );
                    }
                    return Image.asset(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ImagePlaceholder(icon: Icons.article_outlined),
                    );
                  }(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date & Category & Bookmark button
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$formattedDate • ${article.category}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onRemove,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFE11D48),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Title
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Read More Link
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Baca Selengkapnya',
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: AppColors.primary,
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
}

class _EmptySavedArticles extends StatelessWidget {
  const _EmptySavedArticles({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE11D48).withValues(alpha: 0.12),
                    AppColors.accentSoft.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 44,
                color: Color(0xFFE11D48),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Belum Ada Favorit Tersimpan',
              textAlign: TextAlign.center,
              style: AppTypography.headingMd.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'Ketuk ikon hati pada artikel kesehatan untuk menyimpannya ke Favorit Saya.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 220,
              child: AppButton(
                label: 'Jelajahi Info Kesehatan',
                expand: true,
                height: 48,
                borderRadius: 24,
                onPressed: onExplore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
