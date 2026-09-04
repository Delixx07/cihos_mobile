import 'package:flutter_test/flutter_test.dart';
import 'package:cihos_mobile/core/network/api_exception.dart';
import 'package:cihos_mobile/features/booking/data/booking_repository.dart';
import 'package:cihos_mobile/features/booking/domain/booking.dart';

Booking booking({
  String? relation,
  String? medicalNo,
  String? name,
  int? familyId,
}) =>
    Booking(
      kind: BookingKind.appointment,
      doctorId: '292',
      paramedicCode: 'D240146',
      unitCode: 'SU-015',
      operationalTimeCode: 'OT-010',
      date: DateTime(2026, 9, 16),
      patientName: name,
      patientMedicalRecordNumber: medicalNo,
      patientFamilyId: familyId,
      patientRelation: relation,
    );

void main() {
  group('booking for a family member', () {
    test('a relative with no hospital record is refused before sending', () {
      // The API cannot register a relative as a new patient; guessing once
      // created duplicate records for people who were already registered.
      expect(
        () => BookingRepository.familyPayload(
          booking(relation: 'Anak', medicalNo: null, name: 'PUTRI'),
          'Keluarga',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'family_not_registered',
          ),
        ),
      );
    });

    test('a temporary APP- number does not count as a hospital record', () {
      expect(
        () => BookingRepository.familyPayload(
          booking(relation: 'Anak', medicalNo: 'APP-000007', name: 'PUTRI'),
          'Keluarga',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('a relative with a real MRN is sent as the family block', () {
      final family = BookingRepository.familyPayload(
        booking(relation: 'Anak', medicalNo: '00-02-03-73', name: 'PUTRI'),
        'Keluarga',
      );

      expect(family, isNotNull);
      expect(family!['medical_no'], '00-02-03-73');
      expect(family['name'], 'PUTRI');
    });

    test('a saved relative sends family_id instead of their details', () {
      // The server already holds their verified record; re-sending the
      // details risks disagreeing with it.
      expect(
        BookingRepository.familyPayload(
          booking(relation: 'Anak', medicalNo: '00-02-03-73', familyId: 2),
          'Keluarga',
        ),
        isNull,
      );
    });

    test('booking for yourself sends no family block at all', () {
      // Identity comes from the bearer token; a family block here would file
      // the appointment under the wrong person.
      expect(
        BookingRepository.familyPayload(
          booking(relation: 'Diri Sendiri', medicalNo: '00-02-03-72'),
          'Pribadi',
        ),
        isNull,
      );
    });
  });
}
