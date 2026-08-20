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
    'assets/images/Logo Ciputra Hospital Blue.png',
    'assets/images/illust_registration.png',
    'assets/images/bg_texture.png',
  ];

  // Every other path the widgets reference. Each has a fallback, so a missing
  // file degrades rather than breaks.
  const optional = [
    'assets/images/videoCall.png',
    'assets/images/medicalTeam.png',
    'assets/images/medicalAppointment.png',
    'assets/images/healthReport.png',
    'assets/images/medical.png',
    'assets/images/sales.png',
    'assets/images/promo_1.jpg',
    'assets/images/promo_2.jpg',
    'assets/images/promo_3.jpg',
    'assets/images/promo_4.png',
    'assets/images/runner.png',
    'assets/images/eating-clean.jpg',
    'assets/images/teh-tawar.jpg',
    'assets/images/jerawat.jpg',
    'assets/images/qr.png',
    'assets/images/emergency_hero.jpg.png',
    'assets/images/avatar.jpg',
    'assets/images/doctor.png',
    'assets/images/cek_antri.jpg',
    'assets/images/dr_edwin.jpg',
    'assets/images/hasil_radiologi.jpg',
    'assets/images/hasil_lab.jpg',
    'assets/images/mcu_illustration.png',
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
