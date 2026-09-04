import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/booking.dart';

class BookingRepository {
  BookingRepository(this._client);

  final ApiClient _client;

  /// Books an appointment via the hospital's app API.
  ///
  /// Endpoint: POST /api/app/appointments
  ///
  /// `Session` and `slot_no` are not sent: patients must not choose their own
  /// queue number. The server picks the earliest slot that has not started
  /// yet (or the first slot of the day for a future date) and answers with the
  /// `slot_no`, `slot_time`, and `queue_label` it assigned.
  ///
  /// Answers `409 no_slot_available` when the day is full or already over.
  ///
  /// The patient's own identity — name, NIK, date of birth, MedicalNo,
  /// IsNewPatient — is read from the bearer token server-side and must not be
  /// sent here.
  ///
  /// Returns the appointment number (e.g. `OPA/20260822/00038`) on success —
  /// this is the value the void endpoint takes back.
  /// Throws [ApiException] if the slot is unavailable or the request fails.
  Future<BookingResult> create(Booking booking) async {
    // Everything below is required by MEDINFRAS. Catching a gap here names
    // the missing piece; letting it through produces a 422 the patient cannot
    // act on, or — worse, for the slot fields — books the wrong queue number.
    final missing = <String>[
      if (booking.date == null) 'tanggal',
      if (booking.unitCode?.isNotEmpty != true) 'kode klinik',
      if (booking.paramedicCode?.isNotEmpty != true) 'kode dokter',
      if (int.tryParse(booking.doctorId ?? '') == null) 'ID dokter',
      if (booking.operationalTimeCode?.isNotEmpty != true) 'kode sesi praktik',
    ];
    if (missing.isNotEmpty) {
      throw ApiException(
        message:
            'Data janji temu belum lengkap (${missing.join(', ')}). '
            'Silakan pilih ulang jadwal.',
        code: 'incomplete_booking',
      );
    }

    // Date must be yyyyMMdd for the MEDINFRAS system, not yyyy-MM-dd.
    final startDate = DateFormat('yyyyMMdd').format(booking.date!);

    final relationToPatient = _resolveRelation(booking);
    final family = familyPayload(booking, relationToPatient);

    final payload = {
      // Doctor / service unit identifiers
      'ServiceUnitCode': booking.unitCode,
      'ParamedicCode': booking.paramedicCode,
      // ParamedicID must be an integer
      'ParamedicID': int.parse(booking.doctorId!),
      // The operational time code from the selected practice schedule
      'OperationalTimeCode': booking.operationalTimeCode,
      'StartDate': startDate,

      // Session and slot_no are never sent: patients do not choose their queue
      // number, the hospital assigns it. This endpoint ignores both fields
      // outright even when supplied, so omitting them keeps the app honest
      // about who decides.

      // Patient relation / guarantor. Only a note on the relationship — the
      // appointment is always filed under the signed-in account's identity.
      'RelationToPatient': relationToPatient,

      // MedicalNo is deliberately absent: the server takes it from the bearer
      // token and ignores any value sent here. On the first booking of an
      // account still holding a temporary APP-XXXXXX number, MEDINFRAS issues
      // the real MRN and saves it to the account — readable afterwards via
      // GET /app/me.

      // Booking for someone else. Without one of these the appointment is
      // filed under the account holder, so a parent booking for their child
      // would arrive at the hospital registered as themselves. `family_id`
      // wins when both are present, so only one is ever sent.
      if (relationToPatient != 'Pribadi' && booking.patientFamilyId != null)
        'family_id': booking.patientFamilyId,
      'family': ?family,
    };

    final response = await _client.post(
      '/app/appointments',
      body: payload,
      authenticated: true,
    );

    // A successful booking answers with `appointment_no` (e.g.
    // "OPA/20260822/00038") — the same value the void endpoint needs back, so
    // it has to be the real one. The other keys are older shapes kept as a
    // fallback; if none is present the booking may have landed but we cannot
    // identify it, and saying so beats inventing a code the patient would
    // quote to the hospital.
    final data = response['data'] as Map<String, dynamic>?;
    final code = (response['appointment_no'] ??
            response['booking_code'] ??
            response['bookingCode'] ??
            response['code'] ??
            data?['appointment_no'] ??
            data?['booking_code'] ??
            data?['bookingCode'] ??
            data?['code'])
        ?.toString();

    if (code == null || code.isEmpty) {
      throw const ApiException(
        message:
            'Janji temu mungkin sudah terbuat, tetapi nomornya tidak diterima '
            'dari server. Silakan cek menu Jadwal Temu sebelum memesan lagi.',
        code: 'missing_appointment_no',
      );
    }
    return BookingResult(
      appointmentNo: code,
      queueNumber: (response['slot_no'] as num?)?.toInt(),
      queueLabel: response['queue_label'] as String?,
      slotTime: response['slot_time'] as String?,
      session: (response['session'] as num?)?.toInt(),
    );
  }

  /// Builds the `family` block when booking for someone other than the
  /// account holder.
  ///
  /// `medical_no` must be a real MRN already resolved through
  /// `POST /app/patients/check`. The API deliberately offers no way to
  /// register a relative as a new patient here: an earlier attempt to guess
  /// created duplicate records for people who were already registered, so an
  /// unmatched relative has to be registered at the hospital instead.
  @visibleForTesting
  static Map<String, dynamic>? familyPayload(
    Booking booking,
    String relationToPatient,
  ) {
    if (relationToPatient == 'Pribadi') return null;

    // A saved relative is identified by id; the server already holds their
    // verified details, so re-sending them risks disagreeing with the record.
    if (booking.patientFamilyId != null) return null;

    final medicalNo = booking.patientMedicalRecordNumber?.trim();
    if (medicalNo == null || medicalNo.isEmpty || medicalNo.startsWith('APP-')) {
      throw ApiException(
        message:
            '${booking.patientName ?? 'Pasien ini'} belum terdaftar di sistem '
            'rumah sakit, jadi janji temu tidak bisa dibuat lewat aplikasi. '
            'Silakan daftarkan terlebih dahulu di Rumah Sakit Ciputra '
            'Surabaya.',
        code: 'family_not_registered',
      );
    }

    return {
      'medical_no': medicalNo,
      if (booking.patientName?.isNotEmpty == true) 'name': booking.patientName,
      if (booking.patientBirthDate != null)
        'dob': DateFormat('yyyy-MM-dd').format(booking.patientBirthDate!),
      if (booking.patientGender?.isNotEmpty == true)
        'gender': booking.patientGender,
      if (booking.patientPhone?.isNotEmpty == true)
        'phone': booking.patientPhone,
    };
  }

  /// Resolves the `RelationToPatient` value for the API payload.
  ///
  /// The API accepts only "Pribadi", "Keluarga", or "Orang Lain" — it is a
  /// note on who the account holder booked for, nothing to do with who pays.
  /// The guarantor/insurer is a separate concern and is not carried by this
  /// field; sending a company name here would be rejected.
  String _resolveRelation(Booking booking) {
    final relation = booking.patientRelation?.trim().toLowerCase();
    return switch (relation) {
      null || '' || 'pribadi' || 'diri sendiri' || 'saya sendiri' => 'Pribadi',
      'orang lain' => 'Orang Lain',
      _ => 'Keluarga',
    };
  }
}

/// What the hospital assigned for a confirmed booking.
///
/// The queue number and its time come back from the server rather than being
/// chosen in the app, so they are only known once the booking succeeds.
class BookingResult {
  const BookingResult({
    required this.appointmentNo,
    this.queueNumber,
    this.queueLabel,
    this.slotTime,
    this.session,
  });

  /// e.g. `OPA/20260902/00003` — the value the void endpoint takes back.
  final String appointmentNo;

  /// Queue position assigned by the hospital, e.g. 7.
  final int? queueNumber;

  /// Ready-made label from the server, e.g. `No. 01 | Session 01`.
  final String? queueLabel;

  /// When the patient is expected, e.g. `14:30`.
  final String? slotTime;

  final int? session;
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(apiClientProvider));
});
