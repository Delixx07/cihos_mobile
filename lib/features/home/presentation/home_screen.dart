import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/textured_background.dart';
import '../domain/health_article.dart';
import 'widgets/article_card.dart';
import 'widgets/consultation_card.dart';
import 'widgets/home_header.dart';
import 'widgets/promo_carousel.dart';
import 'widgets/queue_monitor_card.dart';
import 'widgets/service_grid.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/social_media_buttons.dart';
import '../../schedule/data/schedule_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Which patient's consultations are shown. Null means everyone.
  String? _patientFilter;

  List<ServiceItem> _services(BuildContext context) => [
    ServiceItem(
      label: 'Video Call Dokter',
      icon: Icons.video_call_outlined,
      imageAsset: 'assets/images/artwork/videoCall.png',
      onTap: () => context.push(AppRoutes.videoCallSearch),
    ),
    ServiceItem(
      label: 'Dokter',
      icon: Icons.groups_2_outlined,
      imageAsset: 'assets/images/artwork/medicalTeam.png',
      onTap: () => context.push(AppRoutes.doctorFinder),
    ),
    ServiceItem(
      label: 'Janji Temu Dokter',
      icon: Icons.event_available_outlined,
      imageAsset: 'assets/images/artwork/medicalAppointment.png',
      onTap: () => context.push(AppRoutes.appointmentSearch),
    ),
    ServiceItem(
      label: 'Hasil Pemeriksaan',
      icon: Icons.description_outlined,
      imageAsset: 'assets/images/artwork/healthReport.png',
      onTap: () => context.push(AppRoutes.examResults),
    ),
    ServiceItem(
      label: 'Medical Check Up',
      icon: Icons.medical_services_outlined,
      imageAsset: 'assets/images/artwork/medical.png',
      onTap: () => context.push(AppRoutes.mcuPackages),
    ),
    ServiceItem(
      label: 'Promo',
      icon: Icons.local_offer_outlined,
      imageAsset: 'assets/images/artwork/sales.png',
      onTap: () => context.push(AppRoutes.promo),
    ),
  ];

  static final _articles = [
    HealthArticle(
      id: 'a1',
      title: 'Indonesia Running Series 2025 Berlangsung di 4 Kota!',
      date: DateTime(2025, 2, 1),
      category: 'Event & Olahraga',
      author: 'dr. Antonius Wijaya, Sp.KO',
      authorRole: 'Spesialis Kedokteran Olahraga',
      readTime: '4 menit baca',
      imageAsset: 'assets/images/info kesehatan/runner 3.png',
      summary:
          'Ajang lari bergengsi Indonesia Running Series 2025 resmi bergulir di 4 kota besar dengan standar medis internasional.',
      tags: const ['Lari', 'Olahraga', 'Event 2025', 'Kardiovaskular'],
      content: const [
        'Indonesia Running Series (IRS) 2025 kembali menyapa para pegiat lari Tanah Air. Event marathon tahun ini diselenggarakan di empat kota strategis dengan rute pemandangan kota dan pengawasan medis ketat.',
        'dr. Antonius Wijaya, Sp.KO mengingatkan pentingnya persiapan fisik minimal 8 hingga 12 minggu sebelum race day. Pelari dianjurkan menjalani medical check up berkala dan evaluasi jantung sebelum menempuh kategori Half Marathon atau Full Marathon.',
        'Ciputra Hospital turut berpartisipasi menghadirkan Medical Recovery Booth, Tim Medis Siaga, serta layanan pemeriksaan Cardiopulmonary Exercise Testing (CPET) untuk memastikan kebugaran para pelari tetap optimal dan aman sebelum berkompetisi.',
      ],
    ),
    HealthArticle(
      id: 'o4',
      title: 'Eating Clean, Cara Simpel Untuk Lebih Sehat',
      date: DateTime(2025, 2, 1),
      category: 'Gaya Hidup',
      author: 'dr. Siti Rahma, Sp.GK',
      readTime: '3 menit baca',
      imageAsset: 'assets/images/promo/gmcu.jpg',
      summary:
          'Prinsip pola makan eating clean berfokus pada bahan makanan segar alami utuh tanpa banyak proses pengawetan.',
      tags: const ['Eating Clean', 'Gaya Hidup', 'Sehat'],
      content: const [
        'Mengurangi konsumsi ultra-processed food, minyak jenuh, dan gula tambahan membawa dampak positif langsung terhadap vitalitas dan fungsi pencernaan.',
      ],
    ),
    HealthArticle(
      id: 'r1',
      title: '7 Manfaat Minum Teh Tawar, Si Pahit yang Kaya Nutrisi',
      date: DateTime(2025, 2, 1),
      category: 'Gaya Hidup',
      author: 'dr. Edwin Hadinata, Sp.PD',
      readTime: '3 menit baca',
      imageAsset: 'assets/images/artwork/mcu.png',
      summary:
          'Teh tawar tanpa gula mengandung antioksidan polifenol tinggi yang melindungi pembuluh darah dan meningkatkan metabolisme.',
      tags: const ['Teh Tawar', 'Antioksidan', 'Metabolisme'],
      content: const [
        'Kandungan katekin dalam teh hijau dan teh hitam murni tanpa pemanis membantu menetralkan radikal bebas serta mendukung kesehatan kardiovaskular.',
      ],
    ),
    HealthArticle(
      id: 'r2',
      title: 'Lokasi Jerawat Jadi Indikasi Masalah Kesehatan, Benarkah?',
      date: DateTime(2025, 2, 1),
      category: 'Kulit & Estetika',
      author: 'dr. Cynthia Dewi, Sp.DVE',
      readTime: '4 menit baca',
      imageAsset: 'assets/images/promo/hair skin.png',
      summary:
          'Face mapping sering mengaitkan letak jerawat dengan fungsi organ dalam, namun faktor kebersihan dan hormonal tetap menjadi pemicu utama.',
      tags: const ['Jerawat', 'Kulit', 'Dermatologi'],
      content: const [
        'Jerawat di area T-zone sering berkaitan dengan produksi sebum berlebih, sementara area rahang dan dagu kerap dipicu oleh fluktuasi hormon estrogen/progesteron.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final upcomingList = ref.watch(upcomingAppointmentsProvider);
    final now = DateTime.now();
    final activeUpcomingList = upcomingList
        .where((a) => a.endsAt.isAfter(now))
        .toList();

    final appointmentPatients = activeUpcomingList
        .map((a) => a.patientName)
        .where((n) => n.trim().isNotEmpty && n.toLowerCase() != 'pasien')
        .toSet()
        .toList();

    final activeAppointment = _patientFilter == null
        ? activeUpcomingList.firstOrNull
        : (activeUpcomingList
                .where((a) =>
                    a.patientName.toLowerCase() ==
                    _patientFilter!.toLowerCase())
                .firstOrNull ??
            activeUpcomingList.firstOrNull);

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: AppTab.home),
      body: TexturedBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref.refresh(appointmentsProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    const HomeHeader(),
                    const SizedBox(height: AppSpacing.md),
                    const PromoCarousel(),
                    const SizedBox(height: AppSpacing.xxl),
                    ServiceGrid(items: _services(context)),
                    const SizedBox(height: AppSpacing.xxl),
                    QueueMonitorCard(
                      onTap: () => context.push(AppRoutes.queueMonitor),
                    ),
                    if (activeAppointment != null) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Konsultasi Anda',
                            style: AppTypography.headingMd.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (appointmentPatients.length > 1) ...[
                        _PatientFilter(
                          patients: appointmentPatients,
                          selected: _patientFilter,
                          onChanged: (value) =>
                              setState(() => _patientFilter = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      ConsultationCard(
                        patientName: activeAppointment.patientName,
                        scheduledAt: activeAppointment.startsAt,
                        endsAt: activeAppointment.endsAt,
                        bookingCode: activeAppointment.bookingCode,
                        doctorName: activeAppointment.doctorName,
                        specialty: activeAppointment.specialty,
                        hospital: activeAppointment.hospital,
                        onDetailTap: () => context.push(
                          '${AppRoutes.appointments}/${activeAppointment.id.isNotEmpty ? activeAppointment.id : activeAppointment.bookingCode}',
                          extra: activeAppointment,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxxl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Info Kesehatan',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.headingMd.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          key: const Key('moreArticles'),
                          onTap: () => context.push(AppRoutes.healthNews),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lihat Semua',
                                  style: AppTypography.bodySm.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final article in _articles) ...[
                      Pressable(
                        scale: 0.98,
                        child: ArticleCard(
                          article: article,
                          onTap: () => context.push(
                            '${AppRoutes.healthNews}/${article.id}',
                            extra: article,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
              const Positioned(
                right: 0,
                bottom: 24,
                child: CollapsibleSocialSidebar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dynamic per-patient filter chips above the consultation card.
class _PatientFilter extends StatelessWidget {
  const _PatientFilter({
    required this.patients,
    required this.selected,
    required this.onChanged,
  });

  final List<String> patients;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Semua',
            isSelected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final name in patients) ...[
            const SizedBox(width: AppSpacing.md),
            _FilterChip(
              label: name,
              isSelected: selected?.toLowerCase() == name.toLowerCase(),
              onTap: () => onChanged(name),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        boxShadow: AppElevation.level2,
      ),
      child: Material(
        color: isSelected ? AppColors.accentSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
