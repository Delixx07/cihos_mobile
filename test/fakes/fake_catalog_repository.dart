import 'package:cihos_mobile/features/doctors/data/catalog_repository.dart';
import 'package:cihos_mobile/features/doctors/domain/clinic.dart';
import 'package:cihos_mobile/features/doctors/domain/doctor.dart';
import 'package:cihos_mobile/features/doctors/domain/practice_schedule.dart';

/// A [CatalogRepository] that answers from memory.
///
/// Shapes mirror what the hospital API actually returns — uppercase English
/// clinic names, doctors without ratings or fees — so the screens are tested
/// against realistic data rather than the tidier dummy set they began with.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({this.failWith});

  /// When set, every call throws this instead of returning data. Lets a test
  /// drive the error and retry paths.
  final Object? failWith;

  /// A representative slice of the hospital's 35 units, with the real codes
  /// and spellings so translation and search behave as they do in production.
  static const clinicList = [
    Clinic(code: 'SU-022', name: 'ANDROLOGY'),
    Clinic(code: 'SU-015', name: 'CARDIOLOGY'),
    Clinic(code: 'SU-006', name: 'DERMATOLOGY'),
    Clinic(code: 'SU-019', name: 'ENT'),
    Clinic(code: 'SU-007', name: 'GENERAL SURGERY'),
    Clinic(code: 'SU-016', name: 'INTERNAL MEDICINE'),
    Clinic(code: 'SU-013', name: 'NEUROLOGY'),
    Clinic(code: 'SU-001', name: 'PEDIATRIC'),
    Clinic(code: 'SU-024', name: 'PEDIATRIC SURGERY'),
    Clinic(code: 'SU-010', name: 'PLASTIC SURGERY'),
    Clinic(code: 'PM-03', name: 'RADIOLOGY'),
    Clinic(code: 'SU-008', name: 'UROLOGY'),
  ];

  static const doctorList = [
    Doctor(
      id: '1',
      name: 'dr. Edwin Hadinata, Sp.PD',
      specialty: 'PENYAKIT DALAM',
      code: 'D240001',
      unitCode: 'SU-016',
    ),
    Doctor(
      id: '2',
      name: 'dr. Sinta Maharani, Sp.JP',
      specialty: 'PENYAKIT JANTUNG DAN PEMBULUH DARAH',
      code: 'D240002',
      unitCode: 'SU-015',
    ),
    Doctor(
      id: '3',
      name: 'dr. Bagus Prakoso, Sp.KK',
      specialty: 'KULIT DAN KELAMIN',
      code: 'D240003',
      unitCode: 'SU-006',
    ),
  ];

  void _guard() {
    if (failWith != null) throw failWith!;
  }

  @override
  Future<List<Clinic>> clinics({String? query}) async {
    _guard();
    if (query == null || query.isEmpty) return clinicList;
    final needle = query.toLowerCase();
    return clinicList
        .where(
          (c) =>
              c.name.toLowerCase().contains(needle) ||
              c.displayName.toLowerCase().contains(needle),
        )
        .toList();
  }

  @override
  Future<List<Doctor>> doctors({String? query, String? unitCode}) async {
    _guard();
    return doctorList.where((d) {
      final matchesUnit = unitCode == null || d.unitCode == unitCode;
      final matchesName =
          query == null ||
          query.isEmpty ||
          d.name.toLowerCase().contains(query.toLowerCase());
      return matchesUnit && matchesName;
    }).toList();
  }

  @override
  Future<List<PracticeSchedule>> schedules(String doctorId) async {
    _guard();
    return const [
      PracticeSchedule(
        unitCode: 'SU-016',
        unitName: 'INTERNAL MEDICINE',
        dayNumber: 1,
        timeLabel: '12:00 - 12:15',
        roomCode: '1736',
        windows: [PracticeWindow(session: 1, start: '12:00', end: '12:15')],
      ),
    ];
  }

  @override
  Future<List<UpcomingScheduleDate>> upcomingSchedules({
    required String doctorId,
    String? unitCode,
    int days = 30,
    int withSlots = 0,
  }) async {
    _guard();
    final now = DateTime.now();
    return [
      UpcomingScheduleDate(
        date: now.add(const Duration(days: 1)),
        unitCode: unitCode ?? 'SU-016',
        unitName: 'INTERNAL MEDICINE',
        timeLabel: '12:00 - 12:15',
      ),
    ];
  }

  @override
  Future<DaySlots> slots({
    required String doctorId,
    required String unitCode,
    required DateTime date,
  }) async {
    _guard();
    return DaySlots(
      date: date,
      slots: const [
        BookableSlot(
          session: 1,
          number: 1,
          start: '12:00',
          end: '12:15',
          room: '1736',
        ),
        BookableSlot(
          session: 1,
          number: 2,
          start: '12:00',
          end: '12:15',
          room: '1736',
        ),
      ],
    );
  }

  @override
  Future<Map<DateTime, String>> holidays() async {
    _guard();
    return {DateTime(2026, 8, 25): 'Maulid Nabi Muhammad SAW'};
  }
}
