import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/clinic.dart';
import '../domain/doctor.dart';
import '../domain/practice_schedule.dart';

/// Reads the hospital's live catalogue: clinics, doctors, schedules, slots.
///
/// These endpoints were built for the WhatsApp bot and the walk-in kiosk; the
/// mobile app is a third reader of the same data, so nothing here writes.
class CatalogRepository {
  const CatalogRepository(this._client);

  final ApiClient _client;

  /// Every service unit the hospital books into. Fetched from API.
  Future<List<Clinic>> clinics({String? query}) async {
    final response = await _client.get(
      '/app/clinics',
      query: {if (query != null && query.isNotEmpty) 'q': query},
      authenticated: true,
    );

    // Endpoint baru biasanya mengembalikan array di dalam 'data' atau 'clinics'.
    final rawList = response['clinics'] ?? response['data'];
    final allClinics = _listOf(rawList, Clinic.fromJson);

    // Filter lokal di Flutter: hanya ambil yang berawalan 'SU' (Poli)
    return allClinics.where((c) => c.code.toUpperCase().startsWith('SU')).toList();
  }

  static const _excludedDoctorKeywords = [
    'dummy test',
    'dokter mcu',
    'dokter radiologi',
    'dokter ugd',
  ];

  static bool isExcludedDoctor(String name) {
    final normalized = name.trim().toLowerCase();
    return _excludedDoctorKeywords.any((keyword) => normalized.contains(keyword));
  }

  /// Doctors, optionally filtered by name or restricted to one unit.
  Future<List<Doctor>> doctors({String? query, String? unitCode}) async {
    final response = await _client.get(
      '/app/doctors',
      query: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (unitCode != null && unitCode.isNotEmpty) 'unit': unitCode,
      },
      authenticated: true,
    );

    final rawList = response['doctors'] ?? response['data'];
    final doctorsList = _listOf(rawList, Doctor.fromJson)
        .where((d) => !isExcludedDoctor(d.name))
        .toList();
    return unitCode == null
        ? doctorsList
        : doctorsList.map((d) => d.copyWith(unitCode: unitCode)).toList();
  }

  /// A doctor's practice sessions.
  ///
  /// Without [date] the API answers the weekly template — the shape the
  /// booking screen leans on for `operational_time_code` and `unit_code`.
  /// With [date] each window also carries the numbered slots still free that
  /// day, which is what `slot_no` is taken from when booking.
  Future<List<PracticeSchedule>> schedules(
    String doctorId, {
    String? unitCode,
    DateTime? date,
  }) async {
    final response = await _client.get(
      '/app/schedule',
      query: {
        'paramedic_id': doctorId,
        if (unitCode != null && unitCode.isNotEmpty) 'unit': unitCode,
        if (date != null) 'date': _isoDate(date),
      },
      authenticated: true,
    );
    return _listOf(response['schedules'], PracticeSchedule.fromJson);
  }

  /// Upcoming schedules for a doctor within [days] (default 30).
  /// GET /app/schedule-upcoming?paramedic_id=...&unit=...&days=30&with_slots=0
  Future<List<UpcomingScheduleDate>> upcomingSchedules({
    required String doctorId,
    String? unitCode,
    int days = 30,
    int withSlots = 0,
  }) async {
    final response = await _client.get(
      '/app/schedule-upcoming',
      query: {
        'paramedic_id': doctorId,
        if (unitCode != null && unitCode.isNotEmpty) 'unit': unitCode,
        'days': days,
        'with_slots': withSlots,
      },
      authenticated: true,
    );

    Object? rawList = response['schedules'] ??
        response['data'] ??
        response['dates'] ??
        response['upcoming'] ??
        response['list'] ??
        response['result'] ??
        response['items'];
    if (rawList is Map) {
      rawList = rawList['schedules'] ??
          rawList['data'] ??
          rawList['dates'] ??
          rawList['upcoming'] ??
          rawList['list'] ??
          rawList['result'] ??
          rawList['items'];
    }

    if (rawList is List) {
      final list = <UpcomingScheduleDate>[];
      for (final item in rawList) {
        if (item is Map) {
          final schedules = item['schedules'];
          // Skip if schedules is explicitly an empty list or explicitly null when the key exists
          if (schedules is List && schedules.isEmpty) {
            continue;
          }
          if (item.containsKey('schedules') && schedules == null) {
            continue;
          }

          final dateObj = UpcomingScheduleDate.fromJson(
            item.cast<String, dynamic>(),
          );
          if (dateObj.isValidDate) {
            list.add(dateObj);
          }
        } else if (item is String) {
          final parsed = DateTime.tryParse(item.trim());
          if (parsed != null && parsed.year > 2000) {
            list.add(UpcomingScheduleDate(date: parsed));
          }
        }
      }
      return list;
    }

    return const [];
  }

  /// Queue numbers still open for [doctorId] at [unitCode] on [date].
  Future<DaySlots> slots({
    required String doctorId,
    required String unitCode,
    required DateTime date,
  }) async {
    final response = await _client.get(
      '/app/slots',
      query: {
        'paramedic_id': doctorId,
        'unit_code': unitCode,
        'date': _isoDate(date),
      },
      authenticated: true,
    );
    return DaySlots.fromJson(response);
  }

  /// Dates the hospital is closed, so the calendar can grey them out.
  Future<Map<DateTime, String>> holidays() async {
    final response = await _client.get(
      '/app/holidays',
      // Without a query the endpoint answers only the next five holidays.
      // The calendar opens up to 30 days ahead, so ask for a range wide
      // enough to cover it even when that crosses into the next year.
      query: {
        'from': _isoDate(DateTime.now()),
        'to': _isoDate(DateTime.now().add(const Duration(days: 120))),
      },
      authenticated: true,
    );
    final raw = response['holidays'];
    if (raw is! List) return const {};

    return {
      for (final entry in raw.whereType<Map>())
        if (DateTime.tryParse(entry['date'] as String? ?? '')
            case final DateTime date)
          DateTime(date.year, date.month, date.day):
              entry['name'] as String? ?? 'Hari libur',
    };
  }

  static String _isoDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static List<T> _listOf<T>(
    Object? raw,
    T Function(Map<String, dynamic>) build,
  ) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => build(e.cast<String, dynamic>()))
        .toList();
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(apiClientProvider)),
);

/// Clinics, fetched once and cached for the session.
final clinicsProvider = FutureProvider<List<Clinic>>(
  (ref) => ref.watch(catalogRepositoryProvider).clinics(),
);

/// Doctors for a unit, or all doctors when [unitCode] is null.
///
/// Named apart from the seeded `doctorsProvider` so both can coexist while
/// screens migrate across to live data one at a time.
final liveDoctorsProvider = FutureProvider.family<List<Doctor>, String?>(
  (ref, unitCode) =>
      ref.watch(catalogRepositoryProvider).doctors(unitCode: unitCode),
);

final doctorSchedulesProvider =
    FutureProvider.family<List<PracticeSchedule>, String>(
      (ref, doctorId) =>
          ref.watch(catalogRepositoryProvider).schedules(doctorId),
    );

final holidaysProvider = FutureProvider<Map<DateTime, String>>(
  (ref) => ref.watch(catalogRepositoryProvider).holidays(),
);

/// The query for a slot lookup — doctor, unit, and date together.
class SlotQuery {
  const SlotQuery({
    required this.doctorId,
    required this.unitCode,
    required this.date,
  });

  final String doctorId;
  final String unitCode;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is SlotQuery &&
      other.doctorId == doctorId &&
      other.unitCode == unitCode &&
      other.date.year == date.year &&
      other.date.month == date.month &&
      other.date.day == date.day;

  @override
  int get hashCode => Object.hash(doctorId, unitCode, date.day, date.month);
}

final slotsProvider = FutureProvider.family<DaySlots, SlotQuery>(
  (ref, query) => ref
      .watch(catalogRepositoryProvider)
      .slots(
        doctorId: query.doctorId,
        unitCode: query.unitCode,
        date: query.date,
      ),
);

/// Query for upcoming schedules within a number of days (default 30).
class UpcomingScheduleQuery {
  const UpcomingScheduleQuery({
    required this.doctorId,
    this.unitCode,
    this.days = 30,
    this.withSlots = 0,
  });

  final String doctorId;
  final String? unitCode;
  final int days;
  final int withSlots;

  @override
  bool operator ==(Object other) =>
      other is UpcomingScheduleQuery &&
      other.doctorId == doctorId &&
      other.unitCode == unitCode &&
      other.days == days &&
      other.withSlots == withSlots;

  @override
  int get hashCode => Object.hash(doctorId, unitCode, days, withSlots);
}

final upcomingSchedulesProvider =
    FutureProvider.family<List<UpcomingScheduleDate>, UpcomingScheduleQuery>(
  (ref, query) => ref.watch(catalogRepositoryProvider).upcomingSchedules(
        doctorId: query.doctorId,
        unitCode: query.unitCode,
        days: query.days,
        withSlots: query.withSlots,
      ),
);
