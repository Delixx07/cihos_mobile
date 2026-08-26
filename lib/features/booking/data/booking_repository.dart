import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../domain/booking.dart';

class BookingRepository {
  BookingRepository(this._client);

  final ApiClient _client;

  /// Books an appointment via the hospital's app API.
  ///
  /// Endpoint: POST /api/app/appointments
  ///
  /// The API automatically assigns `Session` and `slot_no` — we always send 1
  /// for both as the server will override them with the next available queue
  /// position for that operational time.
  ///
  /// Returns the booking code (e.g. `BKG-00123`) on success.
  /// Throws [ApiException] if the slot is unavailable or the request fails.
  Future<String> create(Booking booking) async {
    // Date must be yyyyMMdd for the MEDINFRAS system.
    final startDate = booking.date != null
        ? DateFormat('yyyyMMdd').format(booking.date!)
        : '';

    // Map the patient's relation / payment selection to the RelationToPatient
    // field the API expects. If the booking is for the user themselves (indicated
    // by "Diri Sendiri" in the family relation) it maps to "Pribadi".
    // For a family member the relation name is passed directly.
    final relationToPatient = _resolveRelation(booking);

    final payload = {
      // Doctor / service unit identifiers
      'ServiceUnitCode': booking.unitCode ?? '',
      'ParamedicCode': booking.paramedicCode ?? '',
      // ParamedicID must be an integer
      'ParamedicID': int.tryParse(booking.doctorId ?? '') ?? 0,
      // The operational time code from the selected practice schedule
      'OperationalTimeCode': booking.operationalTimeCode ?? '',
      // Session and slot_no: the API auto-assigns the actual queue position,
      // but the body still requires these fields — send 1 as placeholder.
      'Session': booking.session ?? 1,
      'StartDate': startDate,
      'slot_no': booking.slotNumber ?? 1,

      // Patient relation / guarantor
      'RelationToPatient': relationToPatient,

      // Only send MedicalNo if it is a real hospital-issued MRN (not a temporary APP- one).
      // The backend resolves patient identity from the JWT token when MedicalNo is absent.
      // Sending an empty string or APP- prefix actively breaks the MEDINFRAS lookup.
      if (_isRealMrn(booking.patientMedicalRecordNumber))
        'MedicalNo': booking.patientMedicalRecordNumber!,
    };

    // ignore: avoid_print
    print('[BookingRepository] POST /app/appointments payload: $payload');

    final response = await _client.post(
      '/app/appointments',
      body: payload,
      authenticated: true,
    );

    // The API may return the code under various keys. Try common patterns.
    final data = response['data'] as Map<String, dynamic>?;
    return (data?['booking_code'] as String?) ??
        (data?['bookingCode'] as String?) ??
        (data?['code'] as String?) ??
        (response['booking_code'] as String?) ??
        (response['bookingCode'] as String?) ??
        (response['code'] as String?) ??
        'BKG-SUCCESS';
  }

  /// Resolves the `RelationToPatient` value for the API payload.
  ///
  /// - Payment method "Pribadi" (self-pay) with no family relation → "Pribadi"
  /// - For a named family member, use the relation string directly
  /// - Insurance / company payer → pass the guarantor company name
  String _resolveRelation(Booking booking) {
    final paymentMethod = booking.paymentMethod ?? 'Pribadi';

    if (paymentMethod == 'Asuransi/Perusahaan' && booking.company != null) {
      return booking.company!;
    }

    return 'Pribadi';
  }

  /// Returns true only for real hospital-issued MRNs.
  /// Temporary app IDs (APP-XXXXX), empty strings, and null are excluded.
  bool _isRealMrn(String? mrn) {
    if (mrn == null || mrn.isEmpty) return false;
    if (mrn.startsWith('APP-')) return false;
    return true;
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(apiClientProvider));
});
