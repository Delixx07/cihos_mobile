import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/past_appointment.dart';

/// Finished visits, newest first. Stand-in until the records API exists.
final pastAppointmentsProvider = Provider<List<PastAppointment>>((ref) {
  return [
    PastAppointment(
      id: 'h1',
      patientName: 'NADILA',
      doctorName: 'dr. Edwin Hadinata, Sp.PD',
      specialty: 'Penyakit Dalam',
      startsAt: DateTime(2025, 2, 13, 12, 0),
      endsAt: DateTime(2025, 2, 13, 12, 15),
      outcome: VisitOutcome.completed,
    ),
    PastAppointment(
      id: 'h2',
      patientName: 'PUTRI',
      doctorName: 'dr. Lestari Wibowo, Sp.A',
      specialty: 'Anak',
      startsAt: DateTime(2025, 1, 28, 9, 20),
      endsAt: DateTime(2025, 1, 28, 9, 35),
      outcome: VisitOutcome.completed,
    ),
    PastAppointment(
      id: 'h3',
      patientName: 'NADILA',
      doctorName: 'dr. Bagus Prakoso, Sp.KK',
      specialty: 'Kulit dan Kelamin',
      startsAt: DateTime(2025, 1, 15, 16, 0),
      endsAt: DateTime(2025, 1, 15, 16, 15),
      outcome: VisitOutcome.cancelled,
      kind: VisitKind.videoCall,
    ),
    PastAppointment(
      id: 'h4',
      patientName: 'BAYU',
      doctorName: 'dr. Sinta Maharani, Sp.JP',
      specialty: 'Jantung dan Pembuluh Darah',
      startsAt: DateTime(2024, 12, 9, 10, 40),
      endsAt: DateTime(2024, 12, 9, 10, 55),
      outcome: VisitOutcome.completed,
    ),
  ];
});
