import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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
              likes: (raw['likes'] as num?)?.toInt() ?? _article.likes,
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

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    final isNowSaved = await toggleArticleFavorite(ref, _article.id);
    if (mounted) {
      setState(() {
        _article = _article.copyWith(
          likes: isNowSaved
              ? _article.likes + 1
              : (_article.likes > 0 ? _article.likes - 1 : 0),
        );
      });
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowSaved
                ? 'Artikel ditambahkan ke Favorit'
                : 'Artikel dihapus dari Favorit',
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

  void _openFullScreenImage(BuildContext context) {
    if (_article.imageAsset == null || _article.imageAsset!.trim().isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageViewer(
            imageAsset: _article.imageAsset!,
            heroTag: 'article_detail_image_${_article.id}',
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
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
                      ? 'Hapus dari Favorit'
                      : 'Simpan ke Favorit',
                  icon: Icon(
                    isBookmarked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isBookmarked ? const Color(0xFFE11D48) : Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _toggleFavorite(context, ref),
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
                  // Cover Image with Hero transition & Tap to Fullscreen Zoom
                  GestureDetector(
                    onTap: () => _openFullScreenImage(context),
                    child: Hero(
                      tag: 'article_detail_image_${_article.id}',
                      child: _buildCoverImage(),
                    ),
                  ),

                  // Gradient Dark Overlay for readable text
                  IgnorePointer(
                    child: Container(
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
                  ),

                  // Subtle Zoom Hint Icon (Top Right or Bottom Right)
                  Positioned(
                    top: 56,
                    right: 16,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.zoom_in_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Perbesar',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Subtle frosted pill on image: Live Likes Count
                  Positioned(
                    bottom: 16,
                    left: AppSpacing.xl,
                    child: InkWell(
                      onTap: () => _toggleFavorite(context, ref),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBookmarked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 13,
                              color: isBookmarked
                                  ? const Color(0xFFE11D48)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_article.likes} Suka',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
                  // Clean Category, Date & Likes Header (No colored container box)
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
                      InkWell(
                        onTap: () => _toggleFavorite(context, ref),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBookmarked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 13,
                              color: isBookmarked
                                  ? const Color(0xFFE11D48)
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_article.likes}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isBookmarked
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isBookmarked
                                    ? const Color(0xFFE11D48)
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
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

                  // Author Card (Only Author from API)
                  if (_article.author.trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Penulis',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _article.author.trim(),
                                  style: AppTypography.bodySm.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Main Article Content from Backend API
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    final image = _article.imageAsset;
    if (image != null &&
        (image.startsWith('http://') || image.startsWith('https://'))) {
      return CachedNetworkImage(
        imageUrl: image,
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
      );
    } else if (image != null && image.trim().isNotEmpty) {
      return Image.asset(
        image,
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
      );
    }
    return Container(
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
    );
  }
}

/// Immersive Fullscreen Image Viewer with Pinch-to-Zoom & Double-Tap
class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({
    required this.imageAsset,
    required this.heroTag,
  });

  final String imageAsset;
  final String heroTag;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformationController.value = _zoomAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_animationController.isAnimating) return;

    final currentMatrix = _transformationController.value;
    final isZoomed = currentMatrix.getMaxScaleOnAxis() > 1.05;

    Matrix4 targetMatrix;
    if (!isZoomed) {
      final position = details.localPosition;
      // ignore: deprecated_member_use
      targetMatrix = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        // ignore: deprecated_member_use
        ..scale(2.5);
    } else {
      targetMatrix = Matrix4.identity();
    }

    _zoomAnimation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Zoomable Interactive Image Area
          GestureDetector(
            onDoubleTapDown: _handleDoubleTap,
            onDoubleTap: () {},
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.8,
              maxScale: 4.5,
              clipBehavior: Clip.none,
              child: Center(
                child: Hero(
                  tag: widget.heroTag,
                  child: _buildImage(),
                ),
              ),
            ),
          ),

          // Top Action Bar with Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageAsset.startsWith('http://') ||
        widget.imageAsset.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: widget.imageAsset,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: Colors.white70,
              strokeWidth: 2.5,
            ),
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            Icons.broken_image_rounded,
            size: 64,
            color: Colors.white54,
          ),
        ),
      );
    }
    return Image.asset(
      widget.imageAsset,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 64,
          color: Colors.white54,
        ),
      ),
    );
  }
}
