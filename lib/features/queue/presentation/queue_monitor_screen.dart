import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/app_back_button.dart';

/// Live queue position for today's appointment.
class QueueMonitorScreen extends StatefulWidget {
  const QueueMonitorScreen({super.key, this.hasQueue = true});

  /// Whether the patient has an appointment today. The design covers both
  /// states, and there is no backend yet to decide.
  final bool hasQueue;

  @override
  State<QueueMonitorScreen> createState() => _QueueMonitorScreenState();
}

class _QueueMonitorScreenState extends State<QueueMonitorScreen>
    with SingleTickerProviderStateMixin {
  DateTime _lastUpdated = DateTime(2025, 2, 13, 8, 54);
  bool _isRefreshing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      _lastUpdated = DateTime.now();
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.45,
            child: Image.asset(
              'assets/images/cek antrean.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surface,
                child: const Center(
                  child: Icon(
                    Icons.queue_outlined,
                    size: 64,
                    color: AppColors.accentSoft,
                  ),
                ),
              ),
            ),
          ),

          // Gradient Overlay to make text readable
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    AppColors.surface.withValues(alpha: 0.8),
                    AppColors.surface,
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: screenHeight * 0.10),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitor Antrean',
                          style: AppTypography.headingLg.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            shadows: [
                              const Shadow(
                                color: Colors.black45,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Pantau status antrean Anda secara real-time',
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 14,
                            color: AppColors.white.withValues(alpha: 0.9),
                            shadows: [
                              const Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

                // Toggle Tab Bar
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x15000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x30000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.textPrimary.withValues(alpha: 0.6),
                      labelStyle: AppTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: AppTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Klinik'),
                        Tab(text: 'Farmasi'),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

                // The Content Sheet
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                    ),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        widget.hasQueue
                            ? _QueueBody(
                                lastUpdated: _lastUpdated,
                                isRefreshing: _isRefreshing,
                                onRefresh: _refresh,
                                type: 'Klinik',
                              )
                            : const _EmptyQueue(type: 'Klinik'),
                        widget.hasQueue
                            ? _QueueBody(
                                lastUpdated: _lastUpdated,
                                isRefreshing: _isRefreshing,
                                onRefresh: _refresh,
                                type: 'Farmasi',
                              )
                            : const _EmptyQueue(type: 'Farmasi'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Standard Dark Back Button sitting cleanly at top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: AppBackButton(
                // Making it more visible against potentially bright backgrounds
                color: AppColors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueBody extends StatelessWidget {
  const _QueueBody({
    required this.lastUpdated,
    required this.isRefreshing,
    required this.onRefresh,
    required this.type,
  });

  final DateTime lastUpdated;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final String type;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      children: [
        const _PatientChip(name: 'NADILA'),
        const SizedBox(height: AppSpacing.xxl),
        _QueueCard(
          lastUpdated: lastUpdated,
          isRefreshing: isRefreshing,
          onRefresh: onRefresh,
          type: type,
        ),
        const SizedBox(height: AppSpacing.xxl),
        const _NoticeCard(),
      ],
    );
  }
}

/// A modern, gradient-based advisory card
class _NoticeCard extends StatelessWidget {
  const _NoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.link.withValues(alpha: 0.15),
            AppColors.link.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.link.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.link.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppColors.link,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Penting Untuk Diketahui',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.link,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final line in const [
            'Tekan REFRESH untuk informasi status antrean terbaru.',
            'Harap melakukan check in sebelum jam praktek berakhir.',
            'Check in gagal bila dilakukan setelah jam praktek selesai.',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.link.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12.5,
                        height: 1.3,
                        color: AppColors.textPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PatientChip extends StatelessWidget {
  const _PatientChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDDDFF3), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_outline,
              size: 16,
              color: AppColors.accentSoft,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              name,
              style: AppTypography.inputText.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.accentSoft,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.lastUpdated,
    required this.isRefreshing,
    required this.onRefresh,
    required this.type,
  });

  final DateTime lastUpdated;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(
                label: 'No. Antrean',
                value: '2',
                valueColor: AppColors.link,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type,
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _Stat(label: 'Di Depan Anda', value: '1', suffix: 'Orang'),
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 4),
            child: Text(
              '1 Orang belum check in',
              style: AppTypography.bodySm.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Stat(
                  label: 'Terakhir Diupdate',
                  value: DateFormat('HH.mm').format(lastUpdated),
                ),
              ),
              _RefreshButton(isRefreshing: isRefreshing, onTap: onRefresh),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Divider(color: Color(0xFFE5E7EB), height: 1),
          ),
          Text(
            type == 'Farmasi' ? 'Apoteker Pengurus' : 'dr. Edwin Hadinata, Sp.PD',
            style: AppTypography.titleMd.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.accentSoft,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _IconLine(
            icon: type == 'Farmasi' ? Icons.medication_outlined : Icons.medical_services_outlined,
            text: type == 'Farmasi' ? 'Farmasi Reguler' : 'Penyakit Dalam',
          ),
          const _IconLine(
            icon: Icons.location_on,
            text: 'Ciputra Hospital Surabaya',
          ),
          const _IconLine(
            icon: Icons.calendar_today,
            text: 'Rabu, 13 Februari 2025  12:00 - 12:15 WIB',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.suffix,
    this.valueColor = AppColors.accentSoft,
  });

  final String label;
  final String value;
  final String? suffix;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.titleMd.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: AppTypography.headingLg.copyWith(
                fontSize: 36,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  suffix!,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.isRefreshing, required this.onTap});

  final bool isRefreshing;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isRefreshing ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDDFF3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: isRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.accentSoft,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.accentSoft,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Refresh',
                      style: AppTypography.inputText.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentSoft,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.accentSoft.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: AppColors.accentSoft),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySm.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when there is no appointment queued for today.
class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.type});
  
  final String type;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            'Tidak ada antrean $type hari ini',
            textAlign: TextAlign.center,
            style: AppTypography.headingMd.copyWith(
              color: AppColors.accentSoft,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Antrean $type akan tampil apabila Anda Memiliki '
            'jadwal hari ini.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Illustrations.emptySchedule(size: 220),
        ],
      ),
    );
  }
}
