import 'package:flutter_test/flutter_test.dart';
import 'package:cihos_mobile/core/router/app_routes.dart';

void main() {
  group('AppRoutes.appointmentDetail', () {
    // Real appointment numbers from the hospital carry slashes; left raw they
    // read as extra path segments and go_router matches no route at all.
    const appointmentNo = 'OPA/20260901/00009';

    test('encodes slashes into a single path segment', () {
      final path = AppRoutes.appointmentDetail(appointmentNo);

      expect(path, '/appointments/OPA%2F20260901%2F00009');
      // One segment after the parent, which is what ':id' can match.
      expect(path.split('/').length, 3);
    });

    test('round-trips back to the original appointment number', () {
      final path = AppRoutes.appointmentDetail(appointmentNo);
      final id = path.substring('${AppRoutes.appointments}/'.length);

      expect(Uri.decodeComponent(id), appointmentNo);
    });

    test('leaves a plain numeric id usable', () {
      expect(AppRoutes.appointmentDetail('42'), '/appointments/42');
    });
  });
}
