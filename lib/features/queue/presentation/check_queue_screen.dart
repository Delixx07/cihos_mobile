import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/hero_panel_screen.dart';

/// Entry point for checking a queue by medical record number — clinic or
/// pharmacy.
class CheckQueueScreen extends StatelessWidget {
  const CheckQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HeroPanelScreen(
      heroAsset: 'assets/images/cek_antri.jpg',
      title: 'Cek Antrian',
      subtitle: 'Cek status antrian berdasarkan nomor rekam medis anda.',
      children: [
        HeroPanelAction(
          label: 'Klinik',
          onTap: () => context.push(AppRoutes.queueMonitor),
        ),
        HeroPanelAction(
          label: 'Farmasi',
          onTap: () => context.push(AppRoutes.queueMonitor),
        ),
      ],
    );
  }
}
