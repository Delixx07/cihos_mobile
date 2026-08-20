import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/health_article.dart';

/// Stand-in article feed until the CMS exists.
final healthArticlesProvider = Provider<List<HealthArticle>>((ref) {
  return [
    // Berita Terbaru.
    HealthArticle(
      id: 'n1',
      title: 'Ketahui 7 Penyebab Badan Meriang dan Cara Menjaga Tubuh Tetap '
          'Sehat',
      date: DateTime(2025, 1, 11),
      shelf: ArticleShelf.latest,
    ),
    HealthArticle(
      id: 'n2',
      title: 'Menu Buka Puasa Sehat Agar Tubuh Tetap Bugar',
      date: DateTime(2025, 3, 10),
      shelf: ArticleShelf.latest,
    ),
    HealthArticle(
      id: 'n3',
      title: 'Tiga Aspek Kesehatan yang Wajib Diperhatikan Perempuan',
      date: DateTime(2025, 3, 7),
      shelf: ArticleShelf.latest,
    ),
    HealthArticle(
      id: 'n4',
      title: 'Ini Evaluasi-Saran Ahli Gizi Terkait Program Makan Bergizi '
          'Gratis',
      date: DateTime(2025, 1, 11),
      shelf: ArticleShelf.latest,
    ),

    // Lainnya.
    HealthArticle(
      id: 'o1',
      title: 'Ini Cara Menghilangkan Kesemutan di Tangan',
      date: DateTime(2025, 3, 11),
      shelf: ArticleShelf.others,
    ),
    HealthArticle(
      id: 'o2',
      title: 'Ini Jenis Makanan yang Merupakan Sumber Karbohidrat',
      date: DateTime(2025, 3, 11),
      shelf: ArticleShelf.others,
    ),
    HealthArticle(
      id: 'o3',
      title: 'Ketahui Ciri-Ciri Bayi Sehat dalam Kandungan Usia 8 Bulan',
      date: DateTime(2025, 3, 11),
      shelf: ArticleShelf.others,
    ),
    HealthArticle(
      id: 'o4',
      title: 'Eating Clean, Cara Simpel Untuk Lebih Sehat',
      date: DateTime(2025, 3, 11),
      shelf: ArticleShelf.others,
    ),

    // Bacaan Anda.
    HealthArticle(
      id: 'r1',
      title: '7 Manfaat Minum Teh Tawar, Si Pahit yang Kaya Nutrisi',
      date: DateTime(2025, 2, 1),
      shelf: ArticleShelf.reading,
    ),
    HealthArticle(
      id: 'r2',
      title: 'Lokasi Jerawat Jadi Indikasi Masalah Kesehatan, Benarkah?',
      date: DateTime(2025, 2, 1),
      shelf: ArticleShelf.reading,
    ),
  ];
});

/// Articles on one shelf, in feed order.
final articlesByShelfProvider =
    Provider.family<List<HealthArticle>, ArticleShelf>((ref, shelf) {
      return ref
          .watch(healthArticlesProvider)
          .where((a) => a.shelf == shelf)
          .toList();
    });
