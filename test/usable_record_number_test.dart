import 'package:flutter_test/flutter_test.dart';
import 'package:cihos_mobile/features/booking/data/patient_repository.dart';

void main() {
  group('PatientRepository.isUsableRecordNumber', () {
    test('accepts a real MEDINFRAS record number', () {
      expect(PatientRepository.isUsableRecordNumber('00-02-03-73'), isTrue);
    });

    test('rejects the temporary number issued at sign-up', () {
      // APP-XXXXXX only becomes a real MRN after the first booking.
      expect(PatientRepository.isUsableRecordNumber('APP-000005'), isFalse);
    });

    test('rejects numbers invented by the removed /patient/* flow', () {
      // Generated from a timestamp; the hospital never issued it.
      expect(PatientRepository.isUsableRecordNumber('RM-610877'), isFalse);
    });

    test('rejects empty or missing numbers', () {
      expect(PatientRepository.isUsableRecordNumber(null), isFalse);
      expect(PatientRepository.isUsableRecordNumber(''), isFalse);
      expect(PatientRepository.isUsableRecordNumber('   '), isFalse);
    });
  });
}
