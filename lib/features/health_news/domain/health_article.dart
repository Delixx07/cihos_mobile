/// Which shelf of the health-news screen an article belongs to.
enum ArticleShelf { latest, others, reading }

/// One health article.
class HealthArticle {
  const HealthArticle({
    required this.id,
    required this.title,
    required this.date,
    required this.shelf,
    this.imageAsset,
  });

  final String id;
  final String title;
  final DateTime date;
  final ArticleShelf shelf;

  /// Null until the cover image is exported.
  final String? imageAsset;
}
