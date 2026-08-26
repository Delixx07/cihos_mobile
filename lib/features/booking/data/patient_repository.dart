import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/booking.dart';

/// Manages registered patient profiles for booking.
/// Stored locally in secure storage per account/device.
class PatientRepository {
  PatientRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'user_registered_patients';
  final FlutterSecureStorage _storage;

  Future<List<BookingPatient>> getPatients() async {
    try {
      final jsonStr = await _storage.read(key: _key);
      if (jsonStr == null || jsonStr.isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => BookingPatient.fromJson(item.cast<String, dynamic>()))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> savePatients(List<BookingPatient> patients) async {
    final encoded = jsonEncode(patients.map((p) => p.toJson()).toList());
    await _storage.write(key: _key, value: encoded);
  }

  Future<void> addPatient(BookingPatient patient) async {
    final list = List<BookingPatient>.from(await getPatients());
    // Avoid duplicate MRN/Name
    final index = list.indexWhere(
      (p) =>
          p.medicalRecordNumber == patient.medicalRecordNumber &&
          p.medicalRecordNumber.isNotEmpty,
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
        (p.name == patient.name && p.medicalRecordNumber == patient.medicalRecordNumber));
    await savePatients(list);
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository();
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
          p.medicalRecordNumber.isNotEmpty &&
          p.medicalRecordNumber == patient.medicalRecordNumber,
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
    state = await _repository.getPatients();
  }
}

final registeredPatientsProvider =
    StateNotifierProvider<PatientsNotifier, List<BookingPatient>>((ref) {
  return PatientsNotifier(ref.watch(patientRepositoryProvider));
});
