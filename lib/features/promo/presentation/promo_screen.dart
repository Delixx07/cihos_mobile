import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/social_media_buttons.dart';

/// Searchable list of current hospital promotions styled to match ExamResultsScreen.
class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory; // null means 'Semua'

  static const _categories = ['MCU', 'MRI', 'Kulit & Rambut', 'DWCC'];

  List<_PromoItem> _dynamicPromos = [];

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  Future<void> _fetchPromotions() async {
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
      final res = await dio.get('${AppConfig.cmsBaseUrl}/api/promotions');
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data is Map ? res.data['data'] : null;
        if (list is List && list.isNotEmpty) {
          final items = <_PromoItem>[];
          for (final raw in list) {
            if (raw is Map) {
              items.add(_PromoItem(
                id: raw['id']?.toString() ?? '',
                title: raw['title']?.toString() ?? '',
                category: raw['category']?.toString() ?? 'Umum',
                validity: raw['validity']?.toString() ?? 'Berlaku',
                keywords: '${raw['title']} ${raw['category']} ${raw['description']}'.toLowerCase(),
                asset: 'assets/images/promo/gmcu.jpg',
                imageUrl: raw['image_url']?.toString(),
                description: raw['description']?.toString() ?? '',
              ));
            }
          }
          if (items.isNotEmpty && mounted) {
            setState(() {
              _dynamicPromos = items;
            });
          }
        }
      }
    } catch (_) {
      // Fallback
    }
  }

  static const _promos = [
    _PromoItem(
      id: 'p1',
      title: 'Paket MRI Screening Otak & Tulang Belakang',
      category: 'MRI',
      validity: 'Berlaku s/d 31 Desember 2026',
      keywords: 'mri screening scan radiologi pemeriksaan otak saraf mri',
      asset: 'assets/images/promo/mri screening.jpg',
      description:
          'Pemeriksaan Magnetic Resonance Imaging (MRI) resolusi tinggi untuk deteksi dini kelainan saraf, pembuluh darah, dan struktur otak tanpa radiasi.',
    ),
    _PromoItem(
      id: 'p2',
      title: 'Paket General Medical Check Up (GMCU)',
      category: 'MCU',
      validity: 'Berlaku s/d 31 Desember 2026',
      keywords: 'general medical check up gmcu mcu kesehatan darah paket',
      asset: 'assets/images/promo/gmcu.jpg',
      description:
          'Pemeriksaan kesehatan menyeluruh meliputi tes fungsi hati, ginjal, profil lipid, gula darah, rekam jantung (EKG), dan konsultasi dokter umum.',
    ),
    _PromoItem(
      id: 'p3',
      title: 'Diabetes & Wound Care Center (DWCC)',
      category: 'DWCC',
      validity: 'Berlaku s/d 31 Desember 2026',
      keywords: 'diabetes wound care center dwcc spesialis gula luka',
      asset: 'assets/images/promo/dwcc.jpg',
      description:
          'Layanan terpadu perawatan luka diabetes komprehensif bersama tim dokter spesialis dan perawat bersertifikasi modern wound dressing.',
    ),
    _PromoItem(
      id: 'p4',
      title: 'Hair & Skin Aesthetic Care Clinic',
      category: 'Kulit & Rambut',
      validity: 'Berlaku s/d 31 Desember 2026',
      keywords: 'hair skin klinik kulit rambut kecantikan estetika wajah',
      asset: 'assets/images/promo/hair skin.png',
      description:
          'Perawatan kesehatan kulit wajah dan terapi pertumbuhan rambut bersama dokter spesialis dermatologi terpercaya.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_PromoItem> _getFilteredPromos() {
    final source = _dynamicPromos.isNotEmpty ? _dynamicPromos : _promos;
    return source.where((p) {
      final matchesCategory = _selectedCategory == null ||
          p.category.toLowerCase() == _selectedCategory!.toLowerCase();
      final matchesQuery = _query.isEmpty ||
          p.title.toLowerCase().contains(_query.toLowerCase()) ||
          p.keywords.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _showPromoDetail(BuildContext context, _PromoItem promo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    // Banner Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: promo.imageUrl != null && promo.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: promo.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) => Image.asset(
                                promo.asset,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Image.asset(
                              promo.asset,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _CategoryBadge(category: promo.category),
                    const SizedBox(height: 8),
                    Text(
                      promo.title,
                      style: AppTypography.headingMd.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      promo.validity,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Deskripsi Layanan',
                      style: AppTypography.bodyStrong.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      promo.description,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 13.5,
                        height: 1.55,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Tanya CS via WhatsApp',
                      expand: true,
                      onPressed: () {
                        Navigator.of(context).pop();
                        AppSocialLinks.openUrl(
                          AppSocialLinks.whatsappUrl,
                          context: context,
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    final matches = _getFilteredPromos();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Header Linear Gradient (0% #003366 to 100% #0047AB) extending behind the curve
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF003366), // 0%
                    Color(0xFF0047AB), // 100%
                  ],
                ),
              ),
            ),
          ),

          // Foreground Content
          Column(
            children: [
              // Header Controls
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.sm,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // App Bar Row
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Kembali',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Promo Spesial',
                          style: AppTypography.headingMd.copyWith(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Search Bar inside Header
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _query = val),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.16),
                      hintText: 'Cari promo (MCU, MRI, Kulit, dll)...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1.2,
                        ),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Category Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TabPill(
                          label: 'Semua',
                          isSelected: _selectedCategory == null,
                          onTap: () => setState(() => _selectedCategory = null),
                        ),
                        for (final cat in _categories)
                          _TabPill(
                            label: cat,
                            isSelected: _selectedCategory == cat,
                            onTap: () => setState(() => _selectedCategory = cat),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Curved Surface Content Panel
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: matches.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.xl,
                        AppSpacing.xxl,
                        AppSpacing.xxxl,
                      ),
                      itemCount: matches.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, index) => _PromoCard(
                        promo: matches[index],
                        onTap: () => _showPromoDetail(context, matches[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    ],
  ),
);
}
}

class _PromoItem {
  const _PromoItem({
    required this.id,
    required this.title,
    required this.category,
    required this.validity,
    required this.keywords,
    required this.asset,
    this.imageUrl,
    required this.description,
  });

  final String id;
  final String title;
  final String category;
  final String validity;
  final String keywords;
  final String asset;
  final String? imageUrl;
  final String description;
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected
            ? AppColors.white
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryDark : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.promo,
    required this.onTap,
  });

  final _PromoItem promo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: _CategoryBadge(category: promo.category),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  promo.title,
                  style: AppTypography.headingSm.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: promo.imageUrl != null && promo.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: promo.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 140,
                            color: AppColors.surface,
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            promo.asset,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          promo.asset,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 140,
                            color: AppColors.surface,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MetaLine(
                  icon: Icons.calendar_today_outlined,
                  text: promo.validity,
                ),
                const SizedBox(height: AppSpacing.xs),
                const _MetaLine(
                  icon: Icons.local_hospital_outlined,
                  text: 'Ciputra Hospital Surabaya',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final (bg, color, icon) = switch (category.toLowerCase()) {
      'mcu' => (
          const Color(0xFFEDE9FE),
          const Color(0xFF7C3AED),
          Icons.health_and_safety_outlined,
        ),
      'mri' => (
          const Color(0xFFE0F2FE),
          const Color(0xFF0047AB),
          Icons.biotech_outlined,
        ),
      'dwcc' => (
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
          Icons.healing_outlined,
        ),
      _ => (
          const Color(0xFFCCFBF1),
          const Color(0xFF0D9488),
          Icons.spa_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              category,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Promo tidak ditemukan',
            style: AppTypography.bodyMd.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba ubah kata kunci atau pilih kategori lain.',
            style: AppTypography.bodySm.copyWith(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
