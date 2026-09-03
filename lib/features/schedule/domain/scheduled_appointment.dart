/// Whether the visit is still running to plan.
enum AppointmentStatus { onSchedule, rescheduled, cancelled }

extension AppointmentStatusLabel on AppointmentStatus {
  String get label => switch (this) {
    AppointmentStatus.onSchedule => 'Sesuai Jadwal',
    AppointmentStatus.rescheduled => 'Diubah',
    AppointmentStatus.cancelled => 'Dibatalkan',
  };
}

/// A booked visit as it appears in the schedule & history tabs.
class ScheduledAppointment {
  const ScheduledAppointment({
    required this.id,
    required this.patientName,
    required this.isSelf,
    required this.bookingCode,
    required this.queueNumber,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.startsAt,
    required this.endsAt,
    required this.guaranteeType,
    this.partnerId,
    this.medicalNo,
    this.checkInToken,
    this.status = AppointmentStatus.onSchedule,
  });

  final String id;
  final String patientName;

  /// Separates "Saya Sendiri" from "Orang Lain" in the filter.
  final bool isSelf;

  final String bookingCode;
  final int queueNumber;
  final String doctorName;
  final String specialty;
  final String hospital;
  final DateTime startsAt;
  final DateTime endsAt;

  /// "Jaminan Pribadi" or the insurer/company name.
  final String guaranteeType;
  final String? partnerId;
  final String? medicalNo;

  /// Short code the hospital's kiosk scans to check the patient in, e.g.
  /// `LIUYAK96`. Absent once an appointment is cancelled, so a stale QR can
  /// never be presented at the desk.
  final String? checkInToken;

  final AppointmentStatus status;

  String get timeRange {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(startsAt.hour)}:${two(startsAt.minute)} - '
        '${two(endsAt.hour)}:${two(endsAt.minute)} WIB';
  }

  /// Returns true if this appointment date is today or in the future
  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(startsAt.year, startsAt.month, startsAt.day);
    return (aDate.isAtSameMomentAs(today) || aDate.isAfter(today)) &&
        status != AppointmentStatus.cancelled;
  }

  /// Returns true if this appointment date is in the past (before today) or cancelled
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(startsAt.year, startsAt.month, startsAt.day);
    return aDate.isBefore(today) || status == AppointmentStatus.cancelled;
  }

  ScheduledAppointment copyWith({
    String? id,
    String? patientName,
    bool? isSelf,
    String? bookingCode,
    int? queueNumber,
    String? doctorName,
    String? specialty,
    String? hospital,
    DateTime? startsAt,
    DateTime? endsAt,
    String? guaranteeType,
    String? partnerId,
    String? medicalNo,
    String? checkInToken,
    AppointmentStatus? status,
  }) {
    return ScheduledAppointment(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      isSelf: isSelf ?? this.isSelf,
      bookingCode: bookingCode ?? this.bookingCode,
      queueNumber: queueNumber ?? this.queueNumber,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      hospital: hospital ?? this.hospital,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      guaranteeType: guaranteeType ?? this.guaranteeType,
      partnerId: partnerId ?? this.partnerId,
      medicalNo: medicalNo ?? this.medicalNo,
      checkInToken: checkInToken ?? this.checkInToken,
      status: status ?? this.status,
    );
  }

  factory ScheduledAppointment.fromJson(
    Map<String, dynamic> json, {
    String? fallbackPatientName,
    Map<String, String>? mrnToNameMap,
  }) {
    final id = (json['id'] ??
            json['appointment_id'] ??
            json['AppointmentID'] ??
            json['booking_id'] ??
            json['booking_code'] ??
            json['code'] ??
            '')
        .toString();

    final bookingCode = (json['booking_code'] ??
            json['bookingCode'] ??
            json['BookingCode'] ??
            json['code'] ??
            json['registration_no'] ??
            json['RegistrationNo'] ??
            json['AppointmentNo'] ??
            json['appointment_no'] ??
            id)
        .toString();

    final relation = (json['relation_to_patient'] ??
            json['RelationToPatient'] ??
            json['family_relation'] ??
            json['relation'] ??
            '')
        .toString()
        .toLowerCase();

    final isSelf = json['is_self'] == true ||
        json['isSelf'] == true ||
        relation == 'pribadi' ||
        relation == 'diri sendiri' ||
        relation.contains('self') ||
        relation.isEmpty;

    final medicalNo = (json['medical_no'] ??
            json['medicalNo'] ??
            json['MedicalNo'] ??
            json['no_rm'] ??
            json['NoRM'] ??
            '')
        .toString()
        .trim();

    // 1. Resolve Patient Name thoroughly
    String patientName = '';
    final directName = json['patient_name'] ??
        json['patientName'] ??
        json['PatientName'] ??
        json['patient_full_name'] ??
        json['PatientFullName'] ??
        json['nama_pasien'] ??
        json['NamaPasien'] ??
        json['full_name'] ??
        json['fullName'] ??
        json['FullName'] ??
        json['CustomerName'] ??
        json['customer_name'] ??
        json['cust_name'];

    if (directName != null && directName.toString().trim().isNotEmpty) {
      patientName = directName.toString().trim();
    }

    if (patientName.isEmpty || patientName.toLowerCase() == 'pasien') {
      if (json['patient'] is Map) {
        final p = json['patient'] as Map;
        final pName = p['name'] ?? p['patient_name'] ?? p['PatientName'] ?? p['full_name'];
        if (pName != null && pName.toString().trim().isNotEmpty) {
          patientName = pName.toString().trim();
        }
      } else if (json['Patient'] is Map) {
        final p = json['Patient'] as Map;
        final pName = p['name'] ?? p['PatientName'] ?? p['Name'] ?? p['full_name'];
        if (pName != null && pName.toString().trim().isNotEmpty) {
          patientName = pName.toString().trim();
        }
      } else if (json['user'] is Map) {
        final u = json['user'] as Map;
        final uName = u['name'] ?? u['full_name'] ?? u['fullName'] ?? u['FullName'];
        if (uName != null && uName.toString().trim().isNotEmpty) {
          patientName = uName.toString().trim();
        }
      }
    }

    if (patientName.isEmpty || patientName.toLowerCase() == 'pasien') {
      final n = json['name'] ?? json['Name'];
      if (n != null &&
          n.toString().trim().isNotEmpty &&
          n.toString().toLowerCase() != 'pasien') {
        patientName = n.toString().trim();
      }
    }

    if ((patientName.isEmpty || patientName.toLowerCase() == 'pasien') &&
        medicalNo.isNotEmpty &&
        mrnToNameMap != null &&
        mrnToNameMap.containsKey(medicalNo)) {
      patientName = mrnToNameMap[medicalNo]!;
    }

    if (patientName.isEmpty || patientName.toLowerCase() == 'pasien') {
      if (fallbackPatientName != null && fallbackPatientName.trim().isNotEmpty) {
        patientName = fallbackPatientName.trim();
      } else {
        patientName = 'Pasien';
      }
    }

    // 2. Queue Number
    final rawQueue = json['queue_number'] ??
        json['queue_no'] ??
        json['queueNumber'] ??
        json['slot_no'] ??
        json['SlotNo'] ??
        json['Session'] ??
        1;
    final queueNumber = int.tryParse(rawQueue.toString()) ?? 1;

    // 3. Doctor Name
    String doctorName = '';
    final directDoc = json['doctor_name'] ??
        json['doctorName'] ??
        json['DoctorName'] ??
        json['paramedic_name'] ??
        json['ParamedicName'] ??
        json['nama_dokter'] ??
        json['NamaDokter'] ??
        // GET /app/appointments sends the name as a plain string under
        // `doctor`; the Map branches below only fire for the nested shapes
        // other endpoints use.
        (json['doctor'] is String ? json['doctor'] : null) ??
        (json['paramedic'] is String ? json['paramedic'] : null);
    if (directDoc != null && directDoc.toString().trim().isNotEmpty) {
      doctorName = directDoc.toString().trim();
    } else if (json['doctor'] is Map) {
      final d = json['doctor'] as Map;
      doctorName = (d['name'] ?? d['doctor_name'] ?? d['DoctorName'] ?? '').toString().trim();
    } else if (json['paramedic'] is Map) {
      final p = json['paramedic'] as Map;
      doctorName = (p['name'] ?? p['paramedic_name'] ?? p['ParamedicName'] ?? '').toString().trim();
    } else if (json['Paramedic'] is Map) {
      final p = json['Paramedic'] as Map;
      doctorName = (p['Name'] ?? p['ParamedicName'] ?? '').toString().trim();
    }
    if (doctorName.isEmpty) doctorName = 'Dokter';

    // 4. Specialty / Unit
    String specialty = '';
    final directSpec = json['specialty'] ??
        json['specialization'] ??
        json['service_unit_name'] ??
        json['ServiceUnitName'] ??
        json['unit_name'] ??
        json['UnitName'] ??
        json['nama_poli'] ??
        json['poli'];
    if (directSpec != null && directSpec.toString().trim().isNotEmpty) {
      specialty = directSpec.toString().trim();
    } else if (json['doctor'] is Map && (json['doctor'] as Map)['specialty'] != null) {
      specialty = (json['doctor'] as Map)['specialty'].toString().trim();
    } else if (json['service_unit'] is Map) {
      final su = json['service_unit'] as Map;
      specialty = (su['name'] ?? su['service_unit_name'] ?? '').toString().trim();
    } else if (json['ServiceUnit'] is Map) {
      final su = json['ServiceUnit'] as Map;
      specialty = (su['Name'] ?? su['ServiceUnitName'] ?? '').toString().trim();
    }
    if (specialty.isEmpty) specialty = 'Poli Spesialis';

    final hospital = (json['hospital'] ??
            json['hospital_name'] ??
            json['HospitalName'] ??
            'Ciputra Hospital Surabaya')
        .toString();

    // 5. Dates
    DateTime startsAt = _parseDateTime(
      rawDate: json['starts_at'] ??
          json['scheduled_at'] ??
          json['appointment_date'] ??
          json['date'] ??
          json['StartDate'] ??
          json['start_date'] ??
          json['OperationalDate'] ??
          json['AppointmentDate'],
      rawTime: json['start_time'] ??
          json['operational_time'] ??
          json['time'] ??
          json['OperationalTime'] ??
          json['StartTime'],
    );

    DateTime endsAt = _parseDateTime(
      rawDate: json['ends_at'] ??
          json['starts_at'] ??
          json['scheduled_at'] ??
          json['appointment_date'] ??
          json['date'] ??
          json['StartDate'],
      rawTime: json['end_time'] ?? json['endTime'] ?? json['EndTime'],
      fallbackDuration: const Duration(minutes: 15),
      baseDate: startsAt,
    );

    // 6. Guarantee Type
    final guaranteeType = (json['guarantee_type'] ??
            json['guaranteeType'] ??
            json['payment_method'] ??
            json['paymentMethod'] ??
            json['Payer'] ??
            json['payer'] ??
            (relation.isNotEmpty && relation != 'diri sendiri' ? relation : null) ??
            'Jaminan Pribadi')
        .toString();

    final partnerId = json['partner_id']?.toString() ??
        json['partnerId']?.toString() ??
        json['card_number']?.toString() ??
        json['CardNumber']?.toString();

    final rawToken = (json['token'] ??
            json['qr_token'] ??
            json['checkin_token'] ??
            json['CheckInToken'] ??
            '')
        .toString()
        .trim();
    final checkInToken = rawToken.isEmpty || rawToken == 'null'
        ? null
        : rawToken;

    final rawStatus = (json['status'] ?? json['appointment_status'] ?? '')
        .toString()
        .toLowerCase();
    AppointmentStatus status = AppointmentStatus.onSchedule;
    if (rawStatus.contains('cancel') || rawStatus.contains('batal')) {
      status = AppointmentStatus.cancelled;
    } else if (rawStatus.contains('resched') || rawStatus.contains('ubah')) {
      status = AppointmentStatus.rescheduled;
    }

    return ScheduledAppointment(
      id: id,
      patientName: patientName,
      isSelf: isSelf,
      bookingCode: bookingCode,
      queueNumber: queueNumber,
      doctorName: doctorName,
      specialty: specialty,
      hospital: hospital,
      startsAt: startsAt,
      endsAt: endsAt,
      guaranteeType: guaranteeType,
      partnerId: partnerId,
      medicalNo: medicalNo,
      checkInToken: checkInToken,
      status: status,
    );
  }

  static DateTime _parseDateTime({
    Object? rawDate,
    Object? rawTime,
    Duration fallbackDuration = Duration.zero,
    DateTime? baseDate,
  }) {
    if (rawDate == null && baseDate != null) {
      return baseDate.add(fallbackDuration);
    }
    DateTime parsedDate = baseDate ?? DateTime.now();

    if (rawDate != null) {
      final str = rawDate.toString().trim();
      // Case 1: yyyyMMdd (e.g. 20260827)
      if (str.length == 8 && int.tryParse(str) != null) {
        final y = int.parse(str.substring(0, 4));
        final m = int.parse(str.substring(4, 6));
        final d = int.parse(str.substring(6, 8));
        parsedDate = DateTime(y, m, d, 9, 0);
      }
      // Case 2: dd-MM-yyyy or dd/MM/yyyy (e.g. 27-08-2026 or 27/08/2026)
      else if (RegExp(r'^\d{1,2}[-/]\d{1,2}[-/]\d{4}').hasMatch(str)) {
        final parts = str.split(RegExp(r'[-/]'));
        final d = int.tryParse(parts[0]) ?? 1;
        final m = int.tryParse(parts[1]) ?? 1;
        final y = int.tryParse(parts[2].substring(0, 4)) ?? DateTime.now().year;
        parsedDate = DateTime(y, m, d, 9, 0);
      }
      // Case 3: ISO 8601 or standard DateTime.tryParse (yyyy-MM-dd ...)
      else {
        final tryParsed = DateTime.tryParse(str);
        if (tryParsed != null) {
          parsedDate = tryParsed;
        }
      }
    }

    if (rawTime is String && rawTime.trim().isNotEmpty) {
      final timeStr = rawTime.trim();
      final ranges = timeStr.split(RegExp(r'\s*-\s*'));
      String targetTime = ranges.first;
      if (fallbackDuration != Duration.zero && ranges.length > 1) {
        targetTime = ranges[1];
      }

      final timeParts = targetTime.trim().split(RegExp(r'[:.\s]'));
      if (timeParts.isNotEmpty) {
        final h = int.tryParse(timeParts[0]);
        final m = timeParts.length > 1 ? int.tryParse(timeParts[1]) : 0;
        if (h != null) {
          parsedDate = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            h,
            m ?? 0,
          );
        }
      }
    } else if (fallbackDuration != Duration.zero && baseDate != null) {
      return parsedDate.add(fallbackDuration);
    }

    return parsedDate;
  }
}

/// Which slice of the schedule the tab is showing.
enum ScheduleFilter { all, self, others }

extension ScheduleFilterLabel on ScheduleFilter {
  String get label => switch (this) {
    ScheduleFilter.all => 'Semua',
    ScheduleFilter.self => 'Saya Sendiri',
    ScheduleFilter.others => 'Orang Lain',
  };
}
