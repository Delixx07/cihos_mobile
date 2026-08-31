/// Which shelf of the health-news screen an article belongs to.
enum ArticleShelf { latest, others, reading }

/// Rich health article domain model.
class HealthArticle {
  const HealthArticle({
    required this.id,
    required this.title,
    required this.date,
    this.shelf = ArticleShelf.latest,
    this.imageAsset,
    this.category = 'Kesehatan Umum',
    this.author = 'Tim Medis Ciputra Hospital',
    this.authorRole = 'Dokter Spesialis & Konsultan',
    this.readTime = '3 menit baca',
    this.summary,
    this.content = const [],
    this.tags = const [],
  });

  final String id;
  final String title;
  final DateTime date;
  final ArticleShelf shelf;
  final String? imageAsset;
  final String category;
  final String author;
  final String authorRole;
  final String readTime;
  final String? summary;
  final List<String> content;
  final List<String> tags;
}
