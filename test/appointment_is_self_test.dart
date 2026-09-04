import 'package:flutter_test/flutter_test.dart';
import 'package:cihos_mobile/features/schedule/domain/scheduled_appointment.dart';

/// Entries exactly as GET /api/app/appointments returns them, taken from the
/// test server. Note there is no `relation` field at all — whose appointment
/// it is can only be told from `medical_no`.
Map<String, dynamic> appointment({
  required String medicalNo,
  required String patientName,
}) => {
  'appointment_no': 'OPA/20260916/00002',
  'date': '2026-09-16',
  'time': '16:00',
  'doctor': 'dr. Liem Audi Natalino, SpJP(K), FIHA, FAPSC',
  'specialty': 'PENYAKIT JANTUNG DAN PEMBULUH DARAH',
  'clinic_code': 'SU-015',
  'status': 'Booked',
  'medical_no': medicalNo,
  'patient_name': patientName,
};

void main() {
  const accountMrn = '00-02-03-72';

  group('whose appointment is this', () {
    test('a booking under the account MRN is the patient themselves', () {
      final appt = ScheduledAppointment.fromJson(
        appointment(medicalNo: accountMrn, patientName: 'Uji Integrasi'),
        accountMedicalNo: accountMrn,
      );

      expect(appt.isSelf, isTrue);
    });

    test('a booking under a relative MRN is someone else', () {
      // This is the case that was broken: with no relation field, every
      // family booking was read as the account holder's own.
      final appt = ScheduledAppointment.fromJson(
        appointment(medicalNo: '00-02-03-73', patientName: 'tesit1 tesit1'),
        accountMedicalNo: accountMrn,
      );

      expect(appt.isSelf, isFalse);
      expect(appt.patientName, 'tesit1 tesit1');
    });

    test('an explicit is_self flag still wins', () {
      final appt = ScheduledAppointment.fromJson({
        ...appointment(medicalNo: '00-02-03-73', patientName: 'Lain'),
        'is_self': true,
      }, accountMedicalNo: accountMrn);

      expect(appt.isSelf, isTrue);
    });

    test('falls back to the relation text when no MRN is available', () {
      // Older shapes and other endpoints still send a relation instead.
      final withRelation = ScheduledAppointment.fromJson({
        'appointment_no': 'OPA/1',
        'relation_to_patient': 'Keluarga',
      }, accountMedicalNo: accountMrn);

      expect(withRelation.isSelf, isFalse);
    });

    test('an unknown account MRN does not force everything to "others"', () {
      // Before the first booking the account holds no real MRN; treating each
      // appointment as someone else's would empty the "Saya Sendiri" filter.
      final appt = ScheduledAppointment.fromJson(
        appointment(medicalNo: accountMrn, patientName: 'Uji Integrasi'),
        accountMedicalNo: null,
      );

      expect(appt.isSelf, isTrue);
    });
  });
}
