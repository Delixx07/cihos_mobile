import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../schedule/data/schedule_repository.dart';
import '../../schedule/domain/scheduled_appointment.dart';
import '../domain/past_appointment.dart';

final _defaultPastVisits = [
  PastAppointment(
    id: 'h1',
    patientName: 'Alex Chandra',
    doctorName: 'dr. Edwin Hadinata, Sp.PD',
    specialty: 'Penyakit Dalam',
    startsAt: DateTime(2025, 2, 10, 10, 0),
    endsAt: DateTime(2025, 2, 10, 10, 15),
    outcome: VisitOutcome.completed,
    kind: VisitKind.appointment,
  ),
  PastAppointment(
    id: 'h2',
    patientName: 'Alex Chandra',
    doctorName: 'dr. Maria Angela, Sp.OG',
    specialty: 'Kebidanan & Kandungan',
    startsAt: DateTime(2025, 1, 20, 14, 0),
    endsAt: DateTime(2025, 1, 20, 14, 15),
    outcome: VisitOutcome.cancelled,
    kind: VisitKind.appointment,
  ),
  PastAppointment(
    id: 'h3',
    patientName: 'Alex Chandra',
    doctorName: 'dr. Edwin Hadinata, Sp.PD',
    specialty: 'Penyakit Dalam',
    startsAt: DateTime(2025, 1, 5, 11, 0),
    endsAt: DateTime(2025, 1, 5, 11, 15),
    outcome: VisitOutcome.completed,
    kind: VisitKind.videoCall,
  ),
];

/// Finished visits derived dynamically from the live appointments API:
/// Shows appointments where the date has passed or are marked finished/cancelled.
/// Falls back to default past visits for offline / mock modes.
final pastAppointmentsProvider = Provider<List<PastAppointment>>((ref) {
  final historyScheduled = ref.watch(historyAppointmentsProvider);

  if (historyScheduled.isNotEmpty) {
    return historyScheduled.map((s) {
      return PastAppointment(
        id: s.id.isNotEmpty ? s.id : s.bookingCode,
        patientName: s.patientName,
        doctorName: s.doctorName,
        specialty: s.specialty,
        startsAt: s.startsAt,
        endsAt: s.endsAt,
        outcome: s.status == AppointmentStatus.cancelled
            ? VisitOutcome.cancelled
            : VisitOutcome.completed,
        kind: VisitKind.appointment,
      );
    }).toList();
  }

  return _defaultPastVisits;
});
