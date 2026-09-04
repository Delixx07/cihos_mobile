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
    this.likes = 0,
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
  final int likes;
  final String? summary;
  final List<String> content;
  final List<String> tags;

  HealthArticle copyWith({
    String? id,
    String? title,
    DateTime? date,
    ArticleShelf? shelf,
    String? imageAsset,
    String? category,
    String? author,
    String? authorRole,
    String? readTime,
    int? likes,
    String? summary,
    List<String>? content,
    List<String>? tags,
  }) {
    return HealthArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      shelf: shelf ?? this.shelf,
      imageAsset: imageAsset ?? this.imageAsset,
      category: category ?? this.category,
      author: author ?? this.author,
      authorRole: authorRole ?? this.authorRole,
      readTime: readTime ?? this.readTime,
      likes: likes ?? this.likes,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      tags: tags ?? this.tags,
    );
  }
}
