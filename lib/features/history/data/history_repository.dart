import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../schedule/data/schedule_repository.dart';
import '../../schedule/domain/scheduled_appointment.dart';
import '../domain/past_appointment.dart';

/// Finished visits derived dynamically from the live appointments API:
/// Shows appointments where the date has passed or are marked finished/cancelled.
final pastAppointmentsProvider = Provider<List<PastAppointment>>((ref) {
  final historyScheduled = ref.watch(historyAppointmentsProvider);

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
});
