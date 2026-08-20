class HealthArticle {
  const HealthArticle({
    required this.id,
    required this.title,
    required this.date,
    this.imageAsset,
  });

  final String id;
  final String title;
  final DateTime date;

  /// Null until the article images are exported from Figma.
  final String? imageAsset;
}
