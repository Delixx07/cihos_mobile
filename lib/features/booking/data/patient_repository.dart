import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_store.dart';
import '../../auth/domain/user.dart';
import '../domain/booking.dart';

/// Manages registered patient profiles for booking.
/// Stored locally in secure storage per account/device.
class PatientRepository {
  PatientRepository({
    required ApiClient client,
    FlutterSecureStorage? storage,
    TokenStore? tokens,
  })  : _client = client,
        _storage = storage ?? const FlutterSecureStorage(),
        _tokens = tokens ?? TokenStore();

  static const _key = 'user_registered_patients';
  final ApiClient _client;
  final FlutterSecureStorage _storage;
  final TokenStore _tokens;

  Future<List<BookingPatient>> getPatients() async {
    List<BookingPatient> list = [];
    try {
      final jsonStr = await _storage.read(key: _key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          list = decoded
              .whereType<Map>()
              .map((item) =>
                  BookingPatient.fromJson(item.cast<String, dynamic>()))
              .toList();
        }
      }
    } catch (_) {}

    // Otomatis sinkronisasi user yang sedang login sebagai pasien utama ("Diri Sendiri")
    final user = await _tokens.readUser();
    if (user != null && user.fullName.isNotEmpty) {
      final selfPatient = BookingPatient(
        name: user.fullName,
        medicalRecordNumber: user.medicalNo ?? '',
        nik: user.nik,
        phone: user.phone,
        gender: user.gender == Gender.female
            ? 'Perempuan'
            : (user.gender == Gender.male ? 'Laki-Laki' : null),
        birthDate: user.birthDate,
        familyRelation: 'Diri Sendiri',
      );

      final index = list.indexWhere((p) =>
          (p.medicalRecordNumber.isNotEmpty &&
              selfPatient.medicalRecordNumber.isNotEmpty &&
              p.medicalRecordNumber == selfPatient.medicalRecordNumber) ||
          (p.nik != null &&
              selfPatient.nik != null &&
              p.nik!.isNotEmpty &&
              p.nik == selfPatient.nik) ||
          p.name.toLowerCase() == selfPatient.name.toLowerCase());

      if (index < 0) {
        list = [selfPatient, ...list];
      } else {
        list[index] = list[index].copyWith(
          name: selfPatient.name,
          medicalRecordNumber: selfPatient.medicalRecordNumber.isNotEmpty
              ? selfPatient.medicalRecordNumber
              : list[index].medicalRecordNumber,
          nik: selfPatient.nik ?? list[index].nik,
          phone: selfPatient.phone ?? list[index].phone,
          gender: selfPatient.gender ?? list[index].gender,
          birthDate: selfPatient.birthDate ?? list[index].birthDate,
          familyRelation: 'Diri Sendiri',
        );
      }
    }

    return list;
  }

  Future<void> savePatients(List<BookingPatient> patients) async {
    final encoded = jsonEncode(patients.map((p) => p.toJson()).toList());
    await _storage.write(key: _key, value: encoded);
  }

  Future<void> addPatient(BookingPatient patient) async {
    final list = List<BookingPatient>.from(await getPatients());
    // Avoid duplicate MRN/NIK/Name
    final index = list.indexWhere(
      (p) =>
          (p.medicalRecordNumber.isNotEmpty &&
              patient.medicalRecordNumber.isNotEmpty &&
              p.medicalRecordNumber == patient.medicalRecordNumber) ||
          (p.nik != null &&
              patient.nik != null &&
              p.nik!.isNotEmpty &&
              p.nik == patient.nik) ||
          p.name.toLowerCase() == patient.name.toLowerCase(),
    );
    if (index >= 0) {
      list[index] = patient;
    } else {
      list.add(patient);
    }
    await savePatients(list);
  }

  Future<void> removePatient(BookingPatient patient) async {
    final list = List<BookingPatient>.from(await getPatients());
    list.removeWhere((p) =>
        (p.medicalRecordNumber == patient.medicalRecordNumber &&
            patient.medicalRecordNumber.isNotEmpty) ||
        (p.name == patient.name &&
            p.medicalRecordNumber == patient.medicalRecordNumber));
    await savePatients(list);
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }

  /// Checks if a patient exists in MEDINFRAS by NIK, Name, DOB, and Phone.
  /// Returns a [PatientLinkResult] indicating if a confident match was found.
  /// If a match is found, the result will contain the `medical_no`.
  Future<PatientLinkResult> checkPatientLink({
    required String nik,
    required String name,
    required String phone,
    DateTime? dob,
  }) async {
    try {
      final response = await _client.post(
        '/app/patients/check',
        body: {
          'nik': nik,
          'name': name,
          'phone': phone,
          if (dob != null) 'dob': DateFormat('yyyy-MM-dd').format(dob),
        },
        authenticated: true,
      );

      final status = response['status'] as String?;
      if (status == 'found') {
        final data = response['data'] as Map<String, dynamic>?;
        return PatientLinkResult(
          status: LinkStatus.found,
          medicalNo: data?['medical_no'] as String?,
          matchedName: data?['name'] as String?,
          matchedDob: data?['birth_date'] as String?,
        );
      } else if (status == 'ambiguous') {
        return const PatientLinkResult(status: LinkStatus.ambiguous);
      }
      return const PatientLinkResult(status: LinkStatus.notFound);
    } catch (e) {
      // If the API isn't ready or fails, fallback to assuming not_found so it doesn't block the app entirely during dev.
      // In production, you might want to throw or return ambiguous.
      return const PatientLinkResult(status: LinkStatus.notFound);
    }
  }
}

enum LinkStatus { found, notFound, ambiguous }

class PatientLinkResult {
  const PatientLinkResult({
    required this.status,
    this.medicalNo,
    this.matchedName,
    this.matchedDob,
  });

  final LinkStatus status;
  final String? medicalNo;
  final String? matchedName;
  final String? matchedDob;
}

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(
    client: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStoreProvider),
  );
});

class PatientsNotifier extends StateNotifier<List<BookingPatient>> {
  PatientsNotifier(this._repository) : super(const []) {
    _load();
  }

  final PatientRepository _repository;

  Future<void> _load() async {
    final list = await _repository.getPatients();
    state = list;
  }

  Future<BookingPatient> addPatient(BookingPatient patient) async {
    final list = List<BookingPatient>.from(state);
    final index = list.indexWhere(
      (p) =>
          (p.medicalRecordNumber.isNotEmpty &&
              patient.medicalRecordNumber.isNotEmpty &&
              p.medicalRecordNumber == patient.medicalRecordNumber) ||
          (p.nik != null &&
              patient.nik != null &&
              p.nik!.isNotEmpty &&
              p.nik == patient.nik) ||
          p.name.toLowerCase() == patient.name.toLowerCase(),
    );
    if (index >= 0) {
      list[index] = patient;
    } else {
      list.add(patient);
    }
    state = list;
    await _repository.savePatients(list);
    return patient;
  }

  Future<void> removePatient(BookingPatient patient) async {
    state = state
        .where((p) => !(p.medicalRecordNumber == patient.medicalRecordNumber &&
            p.name == patient.name))
        .toList();
    await _repository.removePatient(patient);
  }

  Future<void> refresh() async {
    await _load();
  }
}

final registeredPatientsProvider =
    StateNotifierProvider<PatientsNotifier, List<BookingPatient>>((ref) {
  return PatientsNotifier(ref.watch(patientRepositoryProvider));
});
