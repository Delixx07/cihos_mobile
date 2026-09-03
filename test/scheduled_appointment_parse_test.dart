import 'package:flutter_test/flutter_test.dart';
import 'package:cihos_mobile/features/schedule/domain/scheduled_appointment.dart';

/// One entry exactly as GET /api/app/appointments returns it. `doctor` and
/// `specialty` arrive as plain strings, not nested objects.
Map<String, dynamic> apiAppointment() => {
      'appointment_no': 'OPA/20260909/00003',
      'registration_no': null,
      'ticket_no': null,
      'date': '2026-09-09',
      'time': '16:00',
      'doctor': 'dr. Liem Audi Natalino, SpJP(K), FIHA, FAPSC',
      'specialty': 'PENYAKIT JANTUNG DAN PEMBULUH DARAH',
      'clinic_code': 'SU-015',
      'status': 'Booked',
      'token': 'LIUYAK96',
      'created_at': '2026-09-01T14:35:11+07:00',
    };

void main() {
  group('ScheduledAppointment.fromJson', () {
    test('reads the doctor name sent as a plain string', () {
      final appointment = ScheduledAppointment.fromJson(apiAppointment());

      expect(
        appointment.doctorName,
        'dr. Liem Audi Natalino, SpJP(K), FIHA, FAPSC',
      );
      // The old parser fell through to this placeholder.
      expect(appointment.doctorName, isNot('Dokter'));
    });

    test('still reads a doctor sent as a nested object', () {
      final appointment = ScheduledAppointment.fromJson({
        ...apiAppointment(),
        'doctor': {'name': 'dr. Budi, Sp.PD'},
      });

      expect(appointment.doctorName, 'dr. Budi, Sp.PD');
    });

    test('keeps the placeholder when no doctor is sent at all', () {
      final json = apiAppointment()..remove('doctor');

      expect(ScheduledAppointment.fromJson(json).doctorName, 'Dokter');
    });

    test('reads specialty and the check-in token', () {
      final appointment = ScheduledAppointment.fromJson(apiAppointment());

      expect(appointment.specialty, 'PENYAKIT JANTUNG DAN PEMBULUH DARAH');
      expect(appointment.checkInToken, 'LIUYAK96');
    });

    test('a cancelled appointment carries no check-in token', () {
      final appointment = ScheduledAppointment.fromJson({
        ...apiAppointment(),
        'status': 'Cancelled',
        'token': null,
      });

      expect(appointment.checkInToken, isNull);
      expect(appointment.status, AppointmentStatus.cancelled);
    });
  });
}
