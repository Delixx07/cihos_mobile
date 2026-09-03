import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/social_media_buttons.dart';
import '../data/saved_articles_repository.dart';
import '../domain/health_article.dart';

/// Modern, immersive health article detail reader screen.
/// Fetches complete, untruncated content from the CMS API.
class HealthArticleDetailScreen extends ConsumerStatefulWidget {
  const HealthArticleDetailScreen({super.key, required this.article});

  final HealthArticle article;

  @override
  ConsumerState<HealthArticleDetailScreen> createState() =>
      _HealthArticleDetailScreenState();
}

class _HealthArticleDetailScreenState
    extends ConsumerState<HealthArticleDetailScreen> {
  late HealthArticle _article;
  bool _isLoadingFullContent = false;

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    _loadFullArticle();
  }

  Future<void> _loadFullArticle() async {
    setState(() => _isLoadingFullContent = true);
    try {
      final dio = Dio(
        BaseOptions(
          headers: {
            'Accept': 'application/json',
            if (AppConfig.cmsApiKey.isNotEmpty) 'X-Api-Key': AppConfig.cmsApiKey,
          },
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final res = await dio.get('${AppConfig.cmsBaseUrl}/api/articles/${widget.article.id}');
      if (res.statusCode == 200 && res.data != null && mounted) {
        final dynamic body = res.data;
        final raw = body is Map ? (body['data'] ?? body['article'] ?? body) : null;
        if (raw is Map) {
          final rawContent = raw['content']?.toString() ?? '';
          final rawSummary = raw['summary']?.toString() ?? '';

          final cleanParagraphs = _parseHtmlToParagraphs(
            rawContent.trim().isNotEmpty ? rawContent : rawSummary,
          );

          final rawImg = raw['image_url'] ?? raw['image'] ?? raw['thumbnail'];
          final resolvedImg = AppConfig.resolveCmsImageUrl(rawImg) ?? _article.imageAsset;

          setState(() {
            _article = HealthArticle(
              id: raw['id']?.toString() ?? _article.id,
              title: raw['title']?.toString() ?? _article.title,
              date: raw['published_at'] != null
                  ? DateTime.tryParse(raw['published_at'].toString()) ?? _article.date
                  : _article.date,
              shelf: _article.shelf,
              category: raw['category']?.toString() ?? _article.category,
              author: raw['author']?.toString() ?? _article.author,
              authorRole: raw['author_role']?.toString() ?? _article.authorRole,
              readTime: raw['read_time']?.toString() ?? _article.readTime,
              imageAsset: resolvedImg,
              summary: rawSummary.trim().isNotEmpty ? rawSummary : _article.summary,
              content: cleanParagraphs.isNotEmpty ? cleanParagraphs : _article.content,
              tags: (raw['tags'] is List)
                  ? (raw['tags'] as List).map((t) => t.toString()).toList()
                  : _article.tags,
            );
            _isLoadingFullContent = false;
          });
          return;
        }
      }
    } catch (_) {
      // Keep initial article data
    }
    if (mounted) {
      setState(() => _isLoadingFullContent = false);
    }
  }

  static List<String> _parseHtmlToParagraphs(String html) {
    if (html.trim().isEmpty) return [];

    var text = html
        .replaceAll(RegExp(r'</p>|<br\s*/?>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    return text
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  Future<void> _toggleBookmark(BuildContext context, WidgetRef ref) async {
    final isNowSaved = await ref
        .read(savedArticleIdsProvider.notifier)
        .toggle(_article.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowSaved
                ? 'Artikel berhasil disimpan ke Bacaan Saya'
                : 'Artikel dihapus dari Bacaan Saya',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareArticle(BuildContext context) {
    AppSocialLinks.openUrl(
      'https://wa.me/?text=${Uri.encodeComponent('Baca artikel kesehatan menarik: ${_article.title}\n\nInfo selengkapnya di Ciputra Hospital Mobile.')}',
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBookmarked = ref.watch(savedArticleIdsProvider).contains(_article.id);
    final formattedDate =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_article.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsing Hero Header with Image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: isBookmarked
                      ? 'Hapus dari Bacaan Saya'
                      : 'Simpan ke Bacaan Saya',
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isBookmarked ? Colors.amber : Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _toggleBookmark(context, ref),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'Bagikan Artikel',
                  icon: const Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => _shareArticle(context),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover Image
                  if (_article.imageAsset != null &&
                      (_article.imageAsset!.startsWith('http://') ||
                          _article.imageAsset!.startsWith('https://')))
                    CachedNetworkImage(
                      imageUrl: _article.imageAsset!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white70,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.article_outlined,
                            size: 64,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    )
                  else if (_article.imageAsset != null)
                    Image.asset(
                      _article.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.article_outlined,
                            size: 64,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: Colors.white70,
                        ),
                      ),
                    ),

                  // Gradient Dark Overlay for readable text
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),

                  // Subtle frosted pill on image
                  Positioned(
                    bottom: 16,
                    left: AppSpacing.xl,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _article.readTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Article Body Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxxl * 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clean Category & Date Header (No colored container box)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _article.category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Main Article Title
                  Text(
                    _article.title,
                    style: AppTypography.headingLg.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Author & Medical Reviewer Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentSoft.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _article.author,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySm.copyWith(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 15,
                                    color: Color(0xFF0284C7),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _article.authorRole,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Main Article Content - Clean plain text paragraphs (No blue box container)
                  if (_article.content.isNotEmpty)
                    for (int i = 0; i < _article.content.length; i++) ...[
                      Text(
                        _article.content[i],
                        style: AppTypography.bodyMd.copyWith(
                          fontSize: 15,
                          height: 1.75,
                          color: AppColors.textPrimary.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ]
                  else if (_article.summary != null && _article.summary!.trim().isNotEmpty)
                    Text(
                      _article.summary!.trim(),
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 15,
                        height: 1.75,
                        color: AppColors.textPrimary.withValues(alpha: 0.92),
                      ),
                    )
                  else
                    Text(
                      'Informasi kesehatan terkini disajikan secara akurat oleh tim medis profesional Ciputra Hospital guna memberikan edukasi preventif bagi masyarakat.',
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 15,
                        height: 1.75,
                        color: AppColors.textPrimary,
                      ),
                    ),

                  if (_isLoadingFullContent) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Tags Section
                  if (_article.tags.isNotEmpty) ...[
                    const Text(
                      'Topik Terkait:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in _article.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Hospital Medical Consultation Banner
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x29003366),
                          offset: Offset(0, 6),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.health_and_safety_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            const Expanded(
                              child: Text(
                                'Ingin Konsultasi Lebih Lanjut?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Buat janji temu dengan dokter spesialis di Ciputra Hospital sekarang juga secara praktis.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton.light(
                          label: 'Buat Janji Dokter',
                          expand: true,
                          onPressed: () => context.push(AppRoutes.doctors),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
