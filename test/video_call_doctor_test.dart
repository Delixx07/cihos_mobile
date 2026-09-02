import 'package:cihos_mobile/core/theme/app_theme.dart';
import 'package:cihos_mobile/features/booking/domain/booking.dart';
import 'package:cihos_mobile/features/doctors/data/catalog_repository.dart';
import 'package:cihos_mobile/features/doctors/domain/doctor.dart';
import 'package:cihos_mobile/features/doctors/presentation/doctor_list_screen.dart';
import 'package:cihos_mobile/features/doctors/presentation/widgets/doctor_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_catalog_repository.dart';

void main() {
  group('Doctor Video Call Support', () {
    test('Doctor.fromJson from API includes videoCall in methods', () {
      final json = {
        'paramedic_id': 101,
        'name': 'dr. Budi Santoso, Sp.A',
        'specialty': 'Anak',
        'paramedic_code': 'D240101',
        'unit_code': 'SU-001',
      };

      final doctor = Doctor.fromJson(json);

      expect(doctor.id, '101');
      expect(doctor.name, 'dr. Budi Santoso, Sp.A');
      expect(doctor.supports(ConsultationMethod.videoCall), isTrue);
      expect(doctor.supports(ConsultationMethod.appointment), isTrue);
      expect(
        doctor.methods,
        containsAll([
          ConsultationMethod.appointment,
          ConsultationMethod.videoCall,
        ]),
      );
    });

    test('Doctor default constructor includes videoCall in methods', () {
      const doctor = Doctor(
        id: '1',
        name: 'dr. Test',
        specialty: 'Umum',
      );

      expect(doctor.supports(ConsultationMethod.videoCall), isTrue);
      expect(doctor.supports(ConsultationMethod.appointment), isTrue);
    });

    testWidgets('DoctorListScreen with kind videoCall displays doctors and Video Call action button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeCatalogRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const DoctorListScreen(kind: BookingKind.videoCall),
          ),
        ),
      );

      // Settle async loading of doctors
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify screen title
      expect(find.text('Buat Video Call'), findsOneWidget);

      // Verify that doctors from FakeCatalogRepository are visible (not filtered out)
      expect(find.byType(DoctorCard), findsNWidgets(FakeCatalogRepository.doctorList.length));
      expect(find.text('dr. Edwin Hadinata, Sp.PD'), findsOneWidget);
      expect(find.text('dr. Sinta Maharani, Sp.JP'), findsOneWidget);
      expect(find.text('dr. Bagus Prakoso, Sp.KK'), findsOneWidget);

      // Verify Video Call action button is present on doctor cards
      expect(find.text('Video Call'), findsWidgets);
    });
  });
}
