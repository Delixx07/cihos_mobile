import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the asset paths the widgets reference.
///
/// A rename in `assets/images/` would otherwise only show up at runtime as a
/// silent placeholder, so every path the UI asks for is checked here — the
/// required ones must load, and the optional ones are only reported while the
/// exports are still coming in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Without these the app has visible holes, so they are hard requirements.
  const required = [
    'assets/images/logo/Logo Ciputra Hospital Blue.png',
    'assets/images/artwork/illust_registration.png',
    'assets/images/bg_texture.png',
  ];

  // Every other path the widgets reference. Each has a fallback, so a missing
  // file degrades rather than breaks.
  const optional = [
    'assets/images/artwork/videoCall.png',
    'assets/images/artwork/medicalTeam.png',
    'assets/images/artwork/medicalAppointment.png',
    'assets/images/artwork/healthReport.png',
    'assets/images/artwork/medical.png',
    'assets/images/artwork/sales.png',
    'assets/images/artwork/doctor.png',
    'assets/images/artwork/cari dokter.png',
    'assets/images/artwork/mcu.png',
    'assets/images/banner/cihos1.jpg',
    'assets/images/banner/cek antrean.jpg',
    'assets/images/banner/emergency_hero.jpg.png',
    'assets/images/promo/dwcc.jpg',
    'assets/images/promo/gmcu.jpg',
    'assets/images/promo/hair skin.png',
    'assets/images/promo/mri screening.jpg',
    'assets/images/info kesehatan/runner 3.png',
    'assets/images/sehat-mu/asuransi.png',
    'assets/images/sehat-mu/berhenti merokok.png',
    'assets/images/sehat-mu/hitung kalori.png',
    'assets/images/sehat-mu/kalender bmi.png',
    'assets/images/sehat-mu/kalender haid.png',
    'assets/images/sehat-mu/pengingat obat.png',
    'assets/images/sehat-mu/yoga.png',
  ];

  for (final path in required) {
    test('bundles $path', () async {
      final data = await rootBundle.load(path);

      expect(data.lengthInBytes, greaterThan(0));
    });
  }

  test('reports asset paths that have no file yet', () {
    // Checked against the working tree rather than the bundle: the test
    // binding does not ship an AssetManifest.
    final missing = [
      for (final path in [...required, ...optional])
        if (!File(path).existsSync()) path,
    ];

    if (missing.isNotEmpty) {
      // ignore: avoid_print
      print('Assets not yet exported from Figma:\n  ${missing.join('\n  ')}');
    }

    expect(
      missing.where(required.contains),
      isEmpty,
      reason: 'Required assets are missing from assets/images/.',
    );
  });
}
