import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql_client/mysql_client.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
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

  /// Helper to get a direct MySQL connection for the Catalog.
  Future<MySQLConnection> _getDbConnection() async {
    try {
      final conn = await MySQLConnection.createConnection(
        host: AppConfig.dbCatalogHost,
        port: 3306,
        userName: AppConfig.dbCatalogUser,
        password: AppConfig.dbCatalogPass,
        databaseName: AppConfig.dbCatalogName,
        secure: false, // Wajib ditambahkan untuk server XAMPP/MySQL lokal
      );
      await conn.connect();
      return conn;
    } catch (e) {
      throw ApiException(
        message: 'Koneksi MySQL gagal: $e',
        code: 'db_connection_error',
      );
    }
  }

  /// Every service unit the hospital books into. Fetched from DB.
  Future<List<Clinic>> clinics({String? query}) async {
    final conn = await _getDbConnection();
    try {
      final result = await conn.execute(
        "SELECT * FROM clinics WHERE service_unit_code = 'SU'"
      );

      final List<Clinic> clinicsList = [];
      for (final row in result.rows) {
        // We guess that the clinic code is service_unit_code or id, and name is clinic_name or name.
        // The user didn't specify the exact column for name, we will try `clinic_name` then fallback to `name`.
        final code = row.colByName('service_unit_code') ?? row.colByName('id') ?? '';
        final name = row.colByName('clinic_name') ?? row.colByName('name') ?? '';
        clinicsList.add(Clinic(code: code, name: name));
      }

      // If there's a search query, filter them
      if (query != null && query.isNotEmpty) {
        return clinicsList
            .where((c) => c.displayName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      
      return clinicsList;
    } catch (e) {
      throw ApiException(
        message: 'Query klinik gagal: $e',
        code: 'db_query_error',
      );
    } finally {
      await conn.close();
    }
  }

  /// Doctors, optionally filtered by name or restricted to one unit.
  Future<List<Doctor>> doctors({String? query, String? unitCode}) async {
    final response = await _client.get(
      '/taptalk/doctors',
      query: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (unitCode != null && unitCode.isNotEmpty) 'unit': unitCode,
      },
    );

    final doctors = _listOf(response['doctors'], Doctor.fromJson);
    // Carry the filter's unit through, since slot lookups need a unit code and
    // the doctors payload does not repeat it.
    return unitCode == null
        ? doctors
        : doctors.map((d) => d.copyWith(unitCode: unitCode)).toList();
  }

  /// A doctor's weekly practice sessions.
  Future<List<PracticeSchedule>> schedules(String doctorId) async {
    final response = await _client.get(
      '/taptalk/schedule',
      query: {'paramedic_id': doctorId},
    );
    return _listOf(response['schedules'], PracticeSchedule.fromJson);
  }

  /// Queue numbers still open for [doctorId] at [unitCode] on [date].
  Future<DaySlots> slots({
    required String doctorId,
    required String unitCode,
    required DateTime date,
  }) async {
    final response = await _client.get(
      '/taptalk/slots',
      query: {
        'paramedic_id': doctorId,
        'unit_code': unitCode,
        'date': _isoDate(date),
      },
    );
    return DaySlots.fromJson(response);
  }

  /// Dates the hospital is closed, so the calendar can grey them out.
  Future<Map<DateTime, String>> holidays() async {
    final response = await _client.get('/taptalk/holidays');
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
