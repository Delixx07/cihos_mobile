import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
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

    // The server is the source of truth for relatives; the local copy is only
    // a cache so the picker still works on a dropped connection.
    try {
      final remote = await getFamily();
      if (remote.isNotEmpty) {
        // The server is authoritative and now returns relation_label, so its
        // answer wins. The cached label only fills in for rows saved before
        // that column existed, which would otherwise read "Keluarga".
        final labels = <String, String>{
          for (final cached in await _cachedPatients())
            if (cached.medicalRecordNumber.isNotEmpty &&
                isSpecificRelation(cached.familyRelation))
              cached.medicalRecordNumber: cached.familyRelation!,
        };

        final merged = [
          for (final person in remote)
            if (isSpecificRelation(person.familyRelation))
              person
            else if (labels[person.medicalRecordNumber] case final label?)
              person.copyWith(familyRelation: label)
            else
              person,
        ];

        await savePatients(merged);
        list = List<BookingPatient>.from(merged);
      }
    } catch (_) {
      // Offline or the endpoint is unavailable — fall through to the cache.
    }

    try {
      if (list.isEmpty) {
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
      }
    } catch (_) {}

    // Drop relatives left over from the removed /patient/* flow, which minted
    // its own numbers (`RM-610877`) instead of resolving a real MRN. They
    // cannot be booked with, so leaving them in the picker only invites the
    // patient to pick one and fail at the summary screen.
    list = list
        .where(
          (p) =>
              p.familyId != null ||
              isUsableRecordNumber(p.medicalRecordNumber),
        )
        .toList();

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
          // The account is authoritative for its own record number. The
          // cached copy can still hold the temporary APP-XXXXXX issued at
          // sign-up, which MEDINFRAS replaces with a real MRN on the first
          // booking — keeping the stale one would show the patient a number
          // the hospital does not recognise.
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

  /// Whether [recordNumber] is a real MEDINFRAS record number.
  ///
  /// Rejects the two kinds the hospital never issued: `APP-XXXXXX`, the
  /// temporary number an account holds until its first booking, and `RM-*`,
  /// which the removed /patient/* flow generated from a timestamp. Booking
  /// with either is refused by the API.
  @visibleForTesting
  static bool isUsableRecordNumber(String? recordNumber) {
    final mrn = recordNumber?.trim() ?? '';
    if (mrn.isEmpty) return false;
    return !mrn.startsWith('APP-') && !mrn.startsWith('RM-');
  }

  /// Whether [relation] says more than the server's coarse grouping.
  ///
  /// "Keluarga" and "Orang Lain" are the only values the API stores, so they
  /// carry no information worth preserving over what the server returns.
  @visibleForTesting
  static bool isSpecificRelation(String? relation) {
    if (relation == null || relation.trim().isEmpty) return false;
    final normalised = relation.trim().toLowerCase();
    return normalised != 'keluarga' && normalised != 'orang lain';
  }

  /// Reads the device's copy of the patient list, ignoring the server.
  Future<List<BookingPatient>> _cachedPatients() async {
    try {
      final jsonStr = await _storage.read(key: _key);
      if (jsonStr == null || jsonStr.isEmpty) return const [];
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => BookingPatient.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// The account's saved family members, from `GET /app/family`.
  ///
  /// Server-held rather than device-held: a family list kept only in secure
  /// storage vanished on a new phone, forcing the patient to re-verify every
  /// relative by NIK before each booking.
  Future<List<BookingPatient>> getFamily() async {
    final response = await _client.get('/app/family', authenticated: true);
    final raw = response['family'];
    if (raw is! List) return const [];

    return raw.whereType<Map>().map((entry) {
      final json = entry.cast<String, dynamic>();
      return BookingPatient(
        name: json['name'] as String? ?? '',
        medicalRecordNumber: json['medical_no'] as String? ?? '',
        // relation_label carries the specific tie ("Ibu", "Anak"); relation
        // is only the coarse Keluarga/Orang Lain grouping the API validates.
        familyRelation:
            json['relation_label'] as String? ?? json['relation'] as String?,
        phone: json['phone'] as String?,
        gender: json['gender'] as String?,
        birthDate: DateTime.tryParse(json['dob'] as String? ?? ''),
        familyId: (json['id'] as num?)?.toInt(),
      );
    }).toList();
  }

  /// Saves one relative to the account, resolving their NIK on the way.
  ///
  /// The endpoint runs the same lookup as `/patients/check` and only stores a
  /// `found` match, so an unregistered relative is refused here rather than
  /// failing later at booking. Re-sending a NIK updates the existing row.
  ///
  /// Returns null when the relative could not be matched — the caller should
  /// send them to register at the hospital.
  Future<BookingPatient?> addFamily({
    required String nik,
    required String name,
    DateTime? dob,
    String? phone,
    String? relation,
  }) async {
    final response = await _client.post(
      '/app/family',
      body: {
        'nik': nik,
        'name': name,
        if (dob != null) 'dob': DateFormat('yyyy-MM-dd').format(dob),
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        // Two fields, two jobs: `relation` is the validated grouping, while
        // `relation_label` keeps the specific tie the patient chose so it
        // survives a new phone.
        'relation': relation == 'Orang Lain' ? 'Orang Lain' : 'Keluarga',
        if (isSpecificRelation(relation)) 'relation_label': relation,
      },
      authenticated: true,
    );

    if (response['status'] != 'found') return null;

    final json = (response['family'] as Map).cast<String, dynamic>();
    return BookingPatient(
      name: json['name'] as String? ?? name,
      medicalRecordNumber: json['medical_no'] as String? ?? '',
      familyRelation:
          json['relation_label'] as String? ?? json['relation'] as String?,
      nik: nik,
      phone: json['phone'] as String? ?? phone,
      gender: json['gender'] as String?,
      birthDate: DateTime.tryParse(json['dob'] as String? ?? ''),
      familyId: (json['id'] as num?)?.toInt(),
    );
  }

  /// Removes one saved relative. Scoped to the signed-in account server-side.
  Future<void> removeFamily(int familyId) async {
    await _client.delete('/app/family/$familyId', authenticated: true);
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
    } on ApiException {
      // A failed lookup is NOT proof the patient is new. Reporting notFound
      // here would send someone who already has a medical record through
      // first-time registration, and MEDINFRAS would issue them a second one.
      rethrow;
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

  /// Saves a relative to the account on the server, then mirrors it locally.
  ///
  /// Returns null when MEDINFRAS has no matching record: the API refuses to
  /// register a relative as a new patient, so the caller must send them to
  /// the hospital rather than carrying on.
  Future<BookingPatient?> addFamilyMember({
    required String nik,
    required String name,
    DateTime? dob,
    String? phone,
    String? relation,
  }) async {
    final saved = await _repository.addFamily(
      nik: nik,
      name: name,
      dob: dob,
      phone: phone,
      relation: relation,
    );
    if (saved == null) return null;

    // The server now stores and returns relation_label, so its answer already
    // carries the specific tie — no need to re-attach it here.
    await addPatient(saved);
    return saved;
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

  /// Changes only the relation label shown against a saved relative.
  ///
  /// Their medical record is untouched, so this never re-runs the NIK lookup.
  /// The NIK is re-sent because `POST /app/family` keys on it, and the server
  /// keeps the rest of the row as it is.
  Future<void> updateRelation(BookingPatient patient, String relation) async {
    final updated = patient.copyWith(familyRelation: relation);

    // Update the list first so the change shows immediately; the server call
    // is a sync, not something the patient should wait on.
    state = [
      for (final p in state)
        if (p.medicalRecordNumber == patient.medicalRecordNumber &&
            p.name == patient.name)
          updated
        else
          p,
    ];
    await _repository.savePatients(state);

    if (patient.nik case final nik? when nik.isNotEmpty) {
      try {
        await _repository.addFamily(
          nik: nik,
          name: patient.name,
          dob: patient.birthDate,
          phone: patient.phone,
          relation: relation,
        );
      } catch (_) {
        // Offline: the label is saved locally and re-syncs next time the
        // relative is edited. Not worth blocking the patient over.
      }
    }
  }

  Future<void> removePatient(BookingPatient patient) async {
    state = state
        .where((p) => !(p.medicalRecordNumber == patient.medicalRecordNumber &&
            p.name == patient.name))
        .toList();

    // Remove server-side too, or the relative reappears on the next fetch.
    if (patient.familyId case final id?) {
      try {
        await _repository.removeFamily(id);
      } catch (_) {
        // Already gone, or offline; the local copy is updated either way.
      }
    }
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
