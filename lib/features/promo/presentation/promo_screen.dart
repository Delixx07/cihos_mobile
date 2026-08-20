import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../../../core/theme/app_elevation.dart';

/// Searchable list of current hospital promotions.
class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _promos = [
    _Promo(
      keywords: 'general medical check up mcu kesehatan',
      asset: 'assets/images/promo_2.jpg',
    ),
    _Promo(
      keywords: 'love your breast screening usg khitanan',
      asset: 'assets/images/promo_1.jpg',
    ),
    _Promo(
      keywords: 'promo spesial konsultasi dokter',
      asset: 'assets/images/promo_3.jpg',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _query.isEmpty
        ? _promos
        : _promos
              .where((p) => p.keywords.contains(_query.toLowerCase()))
              .toList();

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Promo'),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.md,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                ),
                child: Text(
                  'Masukkan kata kunci yang ingin Anda cari, misalnya '
                  'khitanan, MCU, etc.',
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: Text(
                  _query.isEmpty ? 'Lihat Semua Promo' : 'Hasil Pencarian',
                  style: AppTypography.inputText.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: matches.isEmpty
                    ? const _NoResults()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          0,
                          AppSpacing.xxl,
                          AppSpacing.xxxl,
                        ),
                        itemCount: matches.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.xl),
                        itemBuilder: (context, index) =>
                            _PromoTile(promo: matches[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Promo {
  const _Promo({required this.keywords, required this.asset});

  /// Lowercase text the search matches against.
  final String keywords;
  final String asset;
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: AppElevation.level2,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.bodySm.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Cari Kata Kunci',
          hintStyle: AppTypography.bodySm.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary.withValues(alpha: 0.8),
          ),
          suffixIcon: const Icon(
            Icons.search,
            color: AppColors.textPrimary,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  const _PromoTile({required this.promo});

  final _Promo promo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          promo.asset,
          width: 266,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 266,
            height: 300,
            color: AppColors.border,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Promo tidak ditemukan', style: AppTypography.bodyMd),
        ],
      ),
    );
  }
}
