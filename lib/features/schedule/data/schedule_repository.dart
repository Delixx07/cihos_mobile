import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/scheduled_appointment.dart';

/// Upcoming appointments across every patient on the account.
///
/// Stand-in data until the backend exists; the empty state is reachable by
/// returning an empty list here.
final scheduledAppointmentsProvider = Provider<List<ScheduledAppointment>>((
  ref,
) {
  return [
    ScheduledAppointment(
      id: 's1',
      patientName: 'NADILA',
      isSelf: true,
      bookingCode: '0002367894',
      queueNumber: 2,
      doctorName: 'dr. Edwin Hadinata, Sp.PD',
      specialty: 'Penyakit Dalam',
      hospital: 'Ciputra Hospital Surabaya',
      startsAt: DateTime(2025, 2, 13, 12),
      endsAt: DateTime(2025, 2, 13, 12, 15),
      guaranteeType: 'Jaminan Pribadi',
    ),
    ScheduledAppointment(
      id: 's2',
      patientName: 'PUTRI (Anak)',
      isSelf: false,
      bookingCode: '0002367912',
      queueNumber: 5,
      doctorName: 'dr. Ahmad Hidayat, Sp.A',
      specialty: 'Anak',
      hospital: 'Ciputra Hospital Surabaya',
      startsAt: DateTime(2025, 2, 15, 9, 30),
      endsAt: DateTime(2025, 2, 15, 9, 45),
      guaranteeType: 'BPJS Kesehatan',
      partnerId: '0001234567890',
    ),
  ];
});

/// Looks one appointment up by id.
final scheduledAppointmentProvider =
    Provider.family<ScheduledAppointment?, String>((ref, id) {
      for (final appointment in ref.watch(scheduledAppointmentsProvider)) {
        if (appointment.id == id) return appointment;
      }
      return null;
    });
