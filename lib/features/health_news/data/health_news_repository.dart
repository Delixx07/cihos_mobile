import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../domain/health_article.dart';

class HealthArticlesNotifier extends StateNotifier<List<HealthArticle>> {
  HealthArticlesNotifier() : super(_fallbackArticles) {
    fetchFromCms();
  }

  Future<void> fetchFromCms() async {
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
      final res = await dio.get('${AppConfig.cmsBaseUrl}/api/articles');
      if (res.statusCode == 200 && res.data != null) {
        final dynamic body = res.data;
        final list = body is Map
            ? (body['data'] is List
                ? body['data']
                : (body['articles'] is List ? body['articles'] : null))
            : (body is List ? body : null);

        if (list is List && list.isNotEmpty) {
          final items = <HealthArticle>[];
          final latestThreshold = (list.length > 3) ? (list.length / 2).ceil() : list.length;

          for (var i = 0; i < list.length; i++) {
            final raw = list[i];
            if (raw is Map) {
              final contentStr =
                  raw['content']?.toString() ?? raw['summary']?.toString() ?? '';
              final cleanParagraphs = _parseHtmlToParagraphs(contentStr);

              final rawImg = raw['image_url'] ??
                  raw['image'] ??
                  raw['thumbnail'] ??
                  raw['cover'];
              final resolvedImg = AppConfig.resolveCmsImageUrl(rawImg);

              final rawDate = raw['published_at'] ??
                  raw['created_at'] ??
                  raw['date'];
              final date = rawDate != null
                  ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
                  : DateTime.now();

              final shelf = i < latestThreshold
                  ? ArticleShelf.latest
                  : ArticleShelf.others;

              items.add(HealthArticle(
                id: raw['id']?.toString() ?? 'cms_$i',
                title: raw['title']?.toString() ?? '',
                date: date,
                shelf: shelf,
                category: raw['category']?.toString() ?? 'Kesehatan Umum',
                author: raw['author']?.toString() ?? 'dr. Ciputra Hospital',
                authorRole: raw['author_role']?.toString() ?? 'Dokter Spesialis',
                readTime: raw['read_time']?.toString() ?? '3 menit baca',
                likes: (raw['likes'] as num?)?.toInt() ?? 0,
                imageAsset: resolvedImg,
                summary: raw['summary']?.toString(),
                content: cleanParagraphs.isNotEmpty
                    ? cleanParagraphs
                    : [raw['summary']?.toString() ?? ''],
                tags: (raw['tags'] is List)
                    ? (raw['tags'] as List).map((t) => t.toString()).toList()
                    : (raw['tags'] is String
                        ? (raw['tags'] as String)
                            .split(',')
                            .map((t) => t.trim())
                            .where((t) => t.isNotEmpty)
                            .toList()
                        : []),
              ));
            }
          }
          if (items.isNotEmpty) {
            state = items;
          }
        }
      }
    } catch (_) {
      // Fallback to static articles
    }
  }

  Future<int?> toggleLike(String articleId, bool isLiked) async {
    // 1. Optimistic update
    state = [
      for (final a in state)
        if (a.id == articleId)
          a.copyWith(likes: isLiked ? a.likes + 1 : (a.likes > 0 ? a.likes - 1 : 0))
        else
          a
    ];

    // 2. Call backend API
    try {
      final dio = Dio(
        BaseOptions(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (AppConfig.cmsApiKey.isNotEmpty) 'X-Api-Key': AppConfig.cmsApiKey,
          },
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final res = await dio.post(
        '${AppConfig.cmsBaseUrl}/api/articles/$articleId/like',
        data: {'action': isLiked ? 'like' : 'unlike'},
      );
      if (res.statusCode == 200 && res.data != null && res.data['likes'] != null) {
        final newLikes = (res.data['likes'] as num).toInt();
        state = [
          for (final a in state)
            if (a.id == articleId)
              a.copyWith(likes: newLikes)
            else
              a
        ];
        return newLikes;
      }
    } catch (_) {}
    return null;
  }
}

final healthArticlesProvider =
    StateNotifierProvider<HealthArticlesNotifier, List<HealthArticle>>((ref) {
  return HealthArticlesNotifier();
});

final _fallbackArticles = [
    // Berita Terbaru
    HealthArticle(
      id: 'a1',
      title: 'Indonesia Running Series 2025 Berlangsung di 4 Kota!',
      date: DateTime(2025, 2, 23),
      shelf: ArticleShelf.latest,
      category: 'Event & Olahraga',
      author: 'dr. Antonius Wijaya, Sp.KO',
      authorRole: 'Spesialis Kedokteran Olahraga',
      readTime: '4 menit baca',
      imageAsset: 'assets/images/info kesehatan/runner 3.png',
      summary:
          'Ajang lari bergengsi Indonesia Running Series 2025 siap digelar di 4 kota besar dengan dukungan tim medis dan pos hidrasi standar internasional.',
      tags: const ['Lari', 'Olahraga', 'Event 2025', 'Kardiovaskular'],
      content: const [
        'Ajang lari berskala nasional "Indonesia Running Series 2025" resmi diumumkan dan akan digelar di 4 kota metropolitan utama: Jakarta, Surabaya, Bandung, dan Bali. Mengusung tema "Run for Life & Health", ribuan pelari dari berbagai kategoriâ€”mulai dari 5K, 10K, Half Marathon (21K), hingga Full Marathon (42K)â€”diharapkan turut meramaikan kompetisi ini.',
        'Kesiapan fisik dan pemeriksaan medis berkala merupakan faktor mutlak sebelum mengikuti kompetisi lari jarak jauh. Berdasarkan studi sports medicine, pelari yang melakukan persiapan terstruktur minimal 8-12 minggu sebelumnya memiliki risiko cedera otot dan dehidrasi berat hingga 65% lebih rendah dibandingkan mereka yang tidak mempersiapkan diri.',
        'Tips Menjaga Kondisi Tubuh untuk Pelari:\nâ€¢ Hydration Strategy: Pastikan mengonsumsi air dan elektrolit sebelum, saat, dan sesudah latihan.\nâ€¢ Dynamic Stretching: Lakukan pemanasan dinamis 10â€“15 menit sebelum berlari untuk meningkatkan elastisitas otot.\nâ€¢ Pacing Control: Mulai dengan ritme stabil sesuai denyut jantung target (Heart Rate Zone 2-3).\nâ€¢ Post-Run Recovery: Berikan waktu istirahat yang cukup untuk regenerasi serat otot dan kompensasi energi glikogen.',
        'Ciputra Hospital turut berpartisipasi menghadirkan Medical Recovery Booth, Tim Medis Siaga, serta layanan pemeriksaan Cardiopulmonary Exercise Testing (CPET) untuk memastikan kebugaran para pelari tetap optimal dan aman sebelum berkompetisi.',
      ],
    ),
    HealthArticle(
      id: 'n1',
      title:
          'Ketahui 7 Penyebab Badan Meriang dan Cara Menjaga Tubuh Tetap Sehat',
      date: DateTime(2025, 1, 11),
      shelf: ArticleShelf.latest,
      category: 'Kesehatan Umum',
      author: 'dr. Edwin Hadinata, Sp.PD',
      authorRole: 'Spesialis Penyakit Dalam',
      readTime: '3 menit baca',
      imageAsset: 'assets/images/artwork/medical.png',
      summary:
          'Sensasi meriang atau menggigil sering kali menjadi tanda sistem kekebalan tubuh sedang aktif melawan patogen atau infeksi.',
      tags: ['Meriang', 'Imunitas', 'Penyakit Dalam'],
      content: const [
        'Badan meriang adalah sensasi dingin yang disertai gemetar pada tubuh, meskipun suhu lingkungan terasa normal. Gejala ini sering kali merupakan respons alami tubuh saat menaikkan suhu inti guna melawan bakteri atau virus.',
        'Beberapa penyebab utama badan meriang meliputi infeksi saluran pernapasan (ISPA), kelelahan kronis akibat kurang tidur, perubahan hormon, dehidrasi, anemia, hipoglikemia, hingga efek samping pengobatan tertentu.',
        'Langkah pertama yang dianjurkan adalah beristirahat total, memperbanyak konsumsi air putih hangat, mengonsumsi makanan bernutrisi tinggi vitamin C dan zinc, serta memonitor suhu tubuh menggunakan termometer medis.',
      ],
    ),
    HealthArticle(
      id: 'n2',
      title: 'Menu Buka Puasa Sehat Agar Tubuh Tetap Bugar',
      date: DateTime(2025, 3, 10),
      shelf: ArticleShelf.latest,
      category: 'Nutrisi & Diet',
      author: 'dr. Siti Rahma, Sp.GK',
      authorRole: 'Spesialis Gizi Klinik',
      readTime: '3 menit baca',
      imageAsset: 'assets/images/promo/gmcu.jpg',
      summary:
          'Memilih menu berbuka yang seimbang membantu menstabilkan kadar gula darah dan mengembalikan cairan tubuh setelah berpuasa.',
      tags: ['Puasa', 'Gizi', 'Nutrisi Sehat'],
      content: const [
        'Saat berbuka puasa, tubuh membutuhkan hidrasi dan asupan glukosa alami secara bertahap. Hindari langsung mengonsumsi makanan yang terlalu manis atau berlemak tinggi karena dapat menyebabkan lonjakan insulin mendadak.',
        'Awali berbuka dengan air putih hangat dan 1-3 butir kurma untuk memulihkan energi dengan serat alami. Berikan jeda 15-20 menit sebelum menyantap makanan utama yang kaya protein rendah lemak dan sayuran segar.',
      ],
    ),
    HealthArticle(
      id: 'n3',
      title: 'Tiga Aspek Kesehatan yang Wajib Diperhatikan Perempuan',
      date: DateTime(2025, 3, 7),
      shelf: ArticleShelf.latest,
      category: 'Kesehatan Wanita',
      author: 'dr. Maria Angela, Sp.OG',
      authorRole: 'Spesialis Kebidanan & Kandungan',
      readTime: '4 menit baca',
      imageAsset: 'assets/images/artwork/doctor.png',
      summary:
          'Kesehatan reproduksi, hormonal, dan kepadatan tulang merupakan pilar penting kesehatan wanita sepanjang usia produktif hingga menopause.',
      tags: ['Wanita', 'Reproduksi', 'Hormon'],
      content: const [
        'Kesehatan perempuan memerlukan pendekatan holistik mencakup keseimbangan hormon, kesehatan sistem reproduksi (skrining Pap Smear/HPV berkala), dan pemenuhan kalsium serta vitamin D untuk mencegah osteoporosis dini.',
        'Olahraga angkat beban ringan dan kardio teratur sangat dianjurkan untuk menjaga massa otot dan metabolisme tubuh.',
      ],
    ),
    HealthArticle(
      id: 'n4',
      title:
          'Ini Evaluasi-Saran Ahli Gizi Terkait Program Makan Bergizi Gratis',
      date: DateTime(2025, 1, 11),
      shelf: ArticleShelf.latest,
      category: 'Nutrisi & Anak',
      author: 'dr. Budi Santoso, Sp.A',
      authorRole: 'Spesialis Anak',
      readTime: '3 menit baca',
      imageAsset: 'assets/images/artwork/medicalTeam.png',
      summary:
          'Pentingnya komposisi gizi seimbang antara protein hewani, mikronutrien, dan kebersihan pengolahan makanan untuk tumbuh kembang anak.',
      tags: ['Gizi Anak', 'Nutrisi', 'Pertumbuhan'],
      content: const [
        'Program pemenuhan nutrisi anak usia sekolah memerlukan porsi protein hewani tinggi asam amino esensial seperti telur, ikan, dan susu untuk mendukung perkembangan kognitif dan pencegahan stunting.',
      ],
    ),

    // Lainnya
    HealthArticle(
      id: 'o1',
      title: 'Ini Cara Menghilangkan Kesemutan di Tangan',
      date: DateTime(2025, 3, 11),
      shelf: ArticleShelf.others,
      category: 'Saraf & Otot',
      author: 'dr. Hendra S., Sp.N',
      authorRole: 'Spesialis Neurologi',
      readTime: '3 menit baca',
      imageAsset: 'assets/images/artwork/medical.png',
      summary:
          'Kesemutan (parestesia) pada tangan bisa disebabkan oleh postur tubuh yang salah, tekanan saraf karpal (CTS), atau defisiensi vitamin B kompleks.',
      tags: ['Saraf', 'Kesemutan', 'Neurologi'],
      content: const [
        'Gerakan peregangan pergelangan tangan berkala dan ergonomi saat bekerja di depan komputer sangat efektif mencegah saraf terjepit di pergelangan tangan.',
      ],
    ),
    HealthArticle(
      id: 'o2',
      title: 'Ini Jenis Makanan yang Merupakan Sumber Karbohidrat Kompleks',
      date: DateTime(2025, 3, 11),
      shelf: ArticleShelf.others,
      category: 'Nutrisi & Diet',
      author: 'dr. Siti Rahma, Sp.GK',
      authorRole: 'Spesialis Gizi Klinik',
      readTime: '3 menit baca',
      imageAsset: 'assets/images/promo/gmcu.jpg',
      summary:
          'Karbohidrat kompleks melepaskan energi secara bertahap dan kaya serat sehingga membuat kenyang lebih lama.',
      tags: ['Karbohidrat', 'Diet Sehat', 'Serat'],
      content: const [
        'Beras merah, oatmeal, ubi jalar, quinoa, dan kacang-kacangan adalah contoh karbohidrat kompleks terbaik untuk menjaga kestabilan glukosa darah harian.',
      ],
    ),
    HealthArticle(
      id: 'o3',
      title: 'Ketahui Ciri-Ciri Bayi Sehat dalam Kandungan Usia 8 Bulan',
      date: DateTime(2025, 3, 11),
      shelf: ArticleShelf.others,
      category: 'Kesehatan Ibu & Anak',
      author: 'dr. Maria Angela, Sp.OG',
      authorRole: 'Spesialis Kebidanan & Kandungan',
      readTime: '4 menit baca',
      imageAsset: 'assets/images/artwork/doctor.png',
      summary:
          'Gerakan janin yang teratur, pertambahan berat badan ideal, dan detak jantung janin yang stabil adalah indikator bayi sehat menjelang persalinan.',
      tags: ['Kehamilan', 'Janin', 'Trimester 3'],
      content: const [
        'Memasuki trimester ketiga akhir, hitung tendangan janin setiap hari (minimal 10 gerakan dalam kurun waktu 2 jam) dan lakukan pemeriksaan USG rutin.',
      ],
    ),
    HealthArticle(
      id: 'o4',
      title: 'Eating Clean, Cara Simpel Untuk Lebih Sehat',
      date: DateTime(2025, 3, 11),
      shelf: ArticleShelf.others,
      category: 'Gaya Hidup',
      author: 'dr. Siti Rahma, Sp.GK',
      authorRole: 'Spesialis Gizi Klinik',
      readTime: '3 menit baca',
      imageAsset: 'assets/images/promo/gmcu.jpg',
      summary:
          'Prinsip pola makan eating clean berfokus pada bahan makanan segar alami utuh tanpa banyak proses pengawetan.',
      tags: ['Eating Clean', 'Gaya Hidup', 'Sehat'],
      content: const [
        'Mengurangi konsumsi ultra-processed food, minyak jenuh, dan gula tambahan membawa dampak positif langsung terhadap vitalitas dan fungsi pencernaan.',
      ],
    ),

    // Bacaan Anda
    HealthArticle(
      id: 'r1',
      title: '7 Manfaat Minum Teh Tawar, Si Pahit yang Kaya Nutrisi',
      date: DateTime(2025, 2, 1),
      shelf: ArticleShelf.reading,
      category: 'Gaya Hidup',
      author: 'dr. Edwin Hadinata, Sp.PD',
      authorRole: 'Spesialis Penyakit Dalam',
      readTime: '3 menit baca',
      imageAsset: 'assets/images/artwork/mcu.png',
      summary:
          'Teh tawar tanpa gula mengandung antioksidan polifenol tinggi yang melindungi pembuluh darah dan meningkatkan metabolisme.',
      tags: ['Teh Tawar', 'Antioksidan', 'Metabolisme'],
      content: const [
        'Kandungan katekin dalam teh hijau dan teh hitam murni tanpa pemanis membantu menetralkan radikal bebas serta mendukung kesehatan kardiovaskular.',
      ],
    ),
    HealthArticle(
      id: 'r2',
      title: 'Lokasi Jerawat Jadi Indikasi Masalah Kesehatan, Benarkah?',
      date: DateTime(2025, 2, 1),
      shelf: ArticleShelf.reading,
      category: 'Kulit & Estetika',
      author: 'dr. Cynthia Dewi, Sp.DVE',
      authorRole: 'Spesialis Dermatologi & Venereologi',
      readTime: '4 menit baca',
      imageAsset: 'assets/images/promo/hair skin.png',
      summary:
          'Face mapping sering mengaitkan letak jerawat dengan fungsi organ dalam, namun faktor kebersihan dan hormonal tetap menjadi pemicu utama.',
      tags: ['Jerawat', 'Kulit', 'Dermatologi'],
      content: const [
        'Jerawat di area T-zone sering berkaitan dengan produksi sebum berlebih, sementara area rahang dan dagu kerap dipicu oleh fluktuasi hormon estrogen/progesteron.',
      ],
    ),
];

/// Articles on one shelf, in feed order.
final articlesByShelfProvider =
    Provider.family<List<HealthArticle>, ArticleShelf>((ref, shelf) {
      final all = ref.watch(healthArticlesProvider);
      final matching = all.where((a) => a.shelf == shelf).toList();
      if (matching.isNotEmpty) return matching;
      if (shelf == ArticleShelf.others && all.isNotEmpty) {
        return all;
      }
      return matching;
    });

List<String> _parseHtmlToParagraphs(String html) {
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
