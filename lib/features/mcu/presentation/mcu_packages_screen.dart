import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/social_media_buttons.dart';

/// One purchasable check-up package.
class McuPackage {
  const McuPackage({
    required this.coverage,
    required this.tier,
    required this.price,
    required this.groupName,
    this.description =
        'Pemeriksaan kesehatan komprehensif mencakup pemeriksaan fisik, laboratorium darah lengkap, dan evaluasi medis dokter spesialis.',
    this.benefits = const [
      'Pemeriksaan Fisik & Tanda Vital',
      'Hematologi Darah Lengkap',
      'Profil Lipid & Kolesterol',
      'Tes Fungsi Hati & Ginjal',
      'Gula Darah Puasa & 2 Jam PP',
      'Rontgen Thorax & EKG Jantung',
      'Konsultasi Dokter Umum / MCU',
    ],
  });

  final String coverage;
  final String tier;
  final int price;
  final String groupName;
  final String description;
  final List<String> benefits;
}

/// A named group of packages, e.g. "Paket Khusus".
class McuGroup {
  const McuGroup({required this.name, required this.packages});

  final String name;
  final List<McuPackage> packages;
}

/// The MCU catalogue, grouped by package family, styled with modern design language
/// matching the Promo Screen and hospital brand gradient.
class McuPackagesScreen extends StatefulWidget {
  const McuPackagesScreen({super.key});

  @override
  State<McuPackagesScreen> createState() => _McuPackagesScreenState();
}

class _McuPackagesScreenState extends State<McuPackagesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  McuPackage? _selectedPackage;

  static const _categories = [
    'Paket Khusus',
    'Paket Lengkap',
    'Paket Medium',
  ];

  static const _groups = [
    McuGroup(
      name: 'Paket Khusus',
      packages: [
        McuPackage(
          coverage: 'Paket 100%',
          tier: 'PNS GOL II',
          price: 895000,
          groupName: 'Paket Khusus',
        ),
        McuPackage(
          coverage: 'Paket 100%',
          tier: 'PNS GOL III',
          price: 895000,
          groupName: 'Paket Khusus',
        ),
        McuPackage(
          coverage: 'Paket 100%',
          tier: 'PNS GOL IV',
          price: 895000,
          groupName: 'Paket Khusus',
        ),
        McuPackage(
          coverage: 'Paket 100%',
          tier: 'Umum',
          price: 895000,
          groupName: 'Paket Khusus',
        ),
      ],
    ),
    McuGroup(
      name: 'Paket Lengkap',
      packages: [
        McuPackage(
          coverage: 'Paket 100%',
          tier: 'PNS GOL II',
          price: 1250000,
          groupName: 'Paket Lengkap',
          benefits: [
            'Semua Item Pemeriksaan Fisik & TTV',
            'Laboratorium Darah & Urine Lengkap',
            'Profil Lemak, Kolesterol, Asam Urat',
            'Pemeriksaan Fungsi Ginjal & Hati Lengkap',
            'Rontgen Dada (Thorax AP)',
            'Elektrokardiografi (EKG) Rekam Jantung',
            'USG Abdomen Atas & Bawah',
            'Konsultasi Dokter Spesialis Penyakit Dalam',
          ],
        ),
        McuPackage(
          coverage: 'Paket 100%',
          tier: 'PNS GOL III',
          price: 1250000,
          groupName: 'Paket Lengkap',
          benefits: [
            'Semua Item Pemeriksaan Fisik & TTV',
            'Laboratorium Darah & Urine Lengkap',
            'Profil Lemak, Kolesterol, Asam Urat',
            'Pemeriksaan Fungsi Ginjal & Hati Lengkap',
            'Rontgen Dada (Thorax AP)',
            'Elektrokardiografi (EKG) Rekam Jantung',
            'USG Abdomen Atas & Bawah',
            'Konsultasi Dokter Spesialis Penyakit Dalam',
          ],
        ),
      ],
    ),
    McuGroup(
      name: 'Paket Medium',
      packages: [
        McuPackage(
          coverage: 'Paket 100%',
          tier: 'PNS GOL II',
          price: 650000,
          groupName: 'Paket Medium',
          benefits: [
            'Pemeriksaan Fisik & TTV Dokter',
            'Darah Lengkap & Urine Rutin',
            'Gula Darah Puasa & Kolesterol Total',
            'Fungsi Ginjal (Ureum & Kreatinin)',
            'Rontgen Thorax',
            'Konsultasi Hasil MCU',
          ],
        ),
        McuPackage(
          coverage: 'Paket 100%',
          tier: 'Umum',
          price: 650000,
          groupName: 'Paket Medium',
          benefits: [
            'Pemeriksaan Fisik & TTV Dokter',
            'Darah Lengkap & Urine Rutin',
            'Gula Darah Puasa & Kolesterol Total',
            'Fungsi Ginjal (Ureum & Kreatinin)',
            'Rontgen Thorax',
            'Konsultasi Hasil MCU',
          ],
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<McuPackage> _getAllPackages() {
    final List<McuPackage> all = [];
    for (final group in _groups) {
      all.addAll(group.packages);
    }
    return all;
  }

  List<McuPackage> _getFilteredPackages() {
    return _getAllPackages().where((p) {
      final matchesCategory = _selectedCategory == null ||
          p.groupName.toLowerCase() == _selectedCategory!.toLowerCase();
      final matchesQuery = _query.isEmpty ||
          p.tier.toLowerCase().contains(_query.toLowerCase()) ||
          p.coverage.toLowerCase().contains(_query.toLowerCase()) ||
          p.groupName.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _showPackageDetail(BuildContext context, McuPackage package) {
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
                    // Badge Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF2FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            package.groupName,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            package.coverage,
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Title
                    Text(
                      'MCU ${package.tier}',
                      style: AppTypography.headingMd.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      package.description,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Price Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF1F6FD),
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4E3F7)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Biaya Paket',
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rupiah.format(package.price),
                                style: AppTypography.headingMd.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.health_and_safety_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Benefits Header
                    Text(
                      'Pemeriksaan yang Termasuk:',
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Benefit Items
                    for (final benefit in package.benefits)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF2E7D32),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                benefit,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSpacing.lg),

                    // Preparation note
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFF57F17),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Persiapan: Disarankan berpuasa selama 10–12 jam sebelum pemeriksaan laboratorium, hanya diperbolehkan minum air putih.',
                              style: AppTypography.caption.copyWith(
                                color: const Color(0xFF5D4037),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Action Button
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      AppSocialLinks.openUrl(
                        '${AppSocialLinks.whatsappUrl}?text=Halo%20Ciputra%20Hospital,%20saya%20ingin%20jadwalkan%20pemeriksaan%20MCU%20${package.tier}%20(${package.groupName})',
                        context: context,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 3,
                      shadowColor: AppColors.primary.withValues(alpha: 0.35),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Jadwalkan MCU via WhatsApp',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
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
    final filtered = _getFilteredPackages();

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
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
                            'Paket MCU',
                            style: AppTypography.headingMd.copyWith(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

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
                        hintText: 'Cari paket MCU (PNS, Umum, Lengkap)...',
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
                child: filtered.isEmpty
                    ? const _EmptyMcuState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          AppSpacing.xl,
                          AppSpacing.xxl,
                          AppSpacing.xxxl,
                        ),
                        children: [
                          // Hero Visual Banner
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFEAF2FC),
                                  Color(0xFFF5F9FF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFD6E6F9),
                              ),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/artwork/mcu.png',
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.medical_services_outlined,
                                    size: 50,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pemeriksaan Berkala',
                                        style: AppTypography.headingMd.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Deteksi dini potensi risiko kesehatan Anda dengan paket MCU Ciputra Hospital.',
                                        style: AppTypography.bodySm.copyWith(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Packages List
                          for (final package in filtered)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                              child: _McuModernCard(
                                package: package,
                                isSelected: package == _selectedPackage,
                                onTap: () {
                                  setState(() => _selectedPackage = package);
                                  _showPackageDetail(context, package);
                                },
                              ),
                            ),
                        ],
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
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _McuModernCard extends StatelessWidget {
  const _McuModernCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  final McuPackage package;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Material(
      color: AppColors.white,
      elevation: isSelected ? 4 : 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE9EDF4),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF2FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      package.tier,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          package.coverage,
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                'Paket MCU ${package.tier}',
                style: AppTypography.headingMd.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Brief list of benefits (first 2)
              for (int i = 0; i < 2 && i < package.benefits.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          package.benefits[i],
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: Color(0xFFEEF2F6)),
              const SizedBox(height: AppSpacing.md),

              // Bottom Price & Action Button Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Biaya',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            rupiah.format(package.price),
                            style: AppTypography.headingMd.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pilih Paket',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMcuState extends StatelessWidget {
  const _EmptyMcuState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Paket MCU Tidak Ditemukan',
              style: AppTypography.headingMd.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba gunakan kata kunci pencarian lain atau pilih kategori Semua.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
