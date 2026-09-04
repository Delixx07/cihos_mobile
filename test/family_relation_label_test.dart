import 'package:flutter_test/flutter_test.dart';
import 'package:cihos_mobile/features/booking/data/patient_repository.dart';

void main() {
  group('relation labels', () {
    test('specific relations are sent as relation_label', () {
      // `relation` only accepts Keluarga/Orang Lain, so these travel in the
      // separate relation_label column the backend added.
      for (final relation in ['Ibu', 'Ayah', 'Anak', 'Istri', 'Suami']) {
        expect(
          PatientRepository.isSpecificRelation(relation),
          isTrue,
          reason: '$relation should be preserved',
        );
      }
    });

    test('the coarse grouping values are not treated as labels', () {
      // Sending these as relation_label would just duplicate `relation`.
      expect(PatientRepository.isSpecificRelation('Keluarga'), isFalse);
      expect(PatientRepository.isSpecificRelation('Orang Lain'), isFalse);
      expect(PatientRepository.isSpecificRelation('keluarga'), isFalse);
    });

    test('empty or missing relations are not preserved', () {
      expect(PatientRepository.isSpecificRelation(null), isFalse);
      expect(PatientRepository.isSpecificRelation(''), isFalse);
      expect(PatientRepository.isSpecificRelation('   '), isFalse);
    });
  });
}
