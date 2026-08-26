import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_store.dart';
import '../../booking/data/patient_repository.dart';
import '../domain/scheduled_appointment.dart';

/// Repository for reading appointments from the live API:
/// GET /api/app/appointments
class ScheduleRepository {
  const ScheduleRepository(this._client, this._tokens, this._patientRepo);

  final ApiClient _client;
  final TokenStore _tokens;
  final PatientRepository _patientRepo;

  /// Fetches all appointments for the authenticated user from the backend.
  Future<List<ScheduledAppointment>> getAppointments() async {
    try {
      final response = await _client.get(
        '/app/appointments',
        authenticated: true,
      );

      if (kDebugMode) {
        // ignore: avoid_print
        print('[ScheduleRepository] GET /app/appointments raw: $response');
      }

      final rawList = response['data'] ??
          response['appointments'] ??
          response['items'] ??
          response['list'] ??
          response['result'] ??
          (response is List ? response : null);

      if (rawList is List) {
        final user = await _tokens.readUser();
        final patients = await _patientRepo.getPatients();
        final mrnMap = <String, String>{
          for (final p in patients)
            if (p.medicalRecordNumber.isNotEmpty)
              p.medicalRecordNumber: p.name,
        };

        final list = <ScheduledAppointment>[];
        for (final item in rawList) {
          if (item is Map) {
            try {
              final appt = ScheduledAppointment.fromJson(
                item.cast<String, dynamic>(),
                fallbackPatientName: user?.fullName,
                mrnToNameMap: mrnMap,
              );
              list.add(appt);
            } catch (e) {
              if (kDebugMode) {
                // ignore: avoid_print
                print('[ScheduleRepository] Error parsing appointment: $e');
              }
            }
          }
        }
        return list;
      }
      return const [];
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[ScheduleRepository] Error fetching appointments: $e');
      }
      rethrow;
    }
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
    ref.watch(patientRepositoryProvider),
  );
});

/// Live appointments fetched from GET /api/app/appointments
final appointmentsProvider =
    FutureProvider<List<ScheduledAppointment>>((ref) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  return await repo.getAppointments();
});

/// Upcoming appointments: scheduled for today or upcoming future dates (startsAt >= today 00:00:00).
final upcomingAppointmentsProvider =
    Provider<List<ScheduledAppointment>>((ref) {
  final appointmentsAsync = ref.watch(appointmentsProvider);
  final all = appointmentsAsync.valueOrNull ?? const [];

  final upcoming = all.where((a) => a.isUpcoming).toList();
  // Sort ascending by appointment date (nearest first)
  upcoming.sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return upcoming;
});

/// Past/History appointments: dates that have already passed (startsAt < today 00:00:00) or cancelled/completed.
final historyAppointmentsProvider =
    Provider<List<ScheduledAppointment>>((ref) {
  final appointmentsAsync = ref.watch(appointmentsProvider);
  final all = appointmentsAsync.valueOrNull ?? const [];

  final history = all.where((a) => a.isPast).toList();
  // Sort descending by appointment date (newest first)
  history.sort((a, b) => b.startsAt.compareTo(a.startsAt));
  return history;
});

/// Backward-compatible alias for upcoming appointments
final scheduledAppointmentsProvider = upcomingAppointmentsProvider;

/// Looks up an appointment by id or booking code across all appointments.
final scheduledAppointmentProvider =
    Provider.family<ScheduledAppointment?, String>((ref, id) {
  final all = ref.watch(appointmentsProvider).valueOrNull ?? const [];
  for (final appointment in all) {
    if (appointment.id == id || appointment.bookingCode == id) {
      return appointment;
    }
  }
  return null;
});
