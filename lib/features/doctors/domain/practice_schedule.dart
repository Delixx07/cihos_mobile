/// One weekly practice session: which clinic, which day, which hours.
class PracticeSchedule {
  const PracticeSchedule({
    required this.unitCode,
    required this.unitName,
    required this.dayNumber,
    required this.timeLabel,
    this.operationalTimeCode = '',
    this.roomCode,
    this.windows = const [],
  });

  factory PracticeSchedule.fromJson(Map<String, dynamic> json) {
    final rawWindows = json['windows'];
    return PracticeSchedule(
      unitCode: json['service_unit_code'] as String? ?? '',
      unitName: json['service_unit_name'] as String? ?? '',
      // The API uses ISO weekday numbering: 1 = Monday.
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 0,
      timeLabel: json['operational_time_name'] as String? ?? '',
      operationalTimeCode: json['operational_time_code'] as String? ?? '',
      roomCode: json['room_code'] as String?,
      windows: rawWindows is List
          ? rawWindows
                .whereType<Map>()
                .map((w) => PracticeWindow.fromJson(w.cast<String, dynamic>()))
                .toList()
          : const [],
    );
  }

  final String unitCode;
  final String unitName;

  /// ISO weekday: 1 = Monday … 7 = Sunday.
  final int dayNumber;

  /// Human-readable range, e.g. `19:00 - 20:00`.
  final String timeLabel;

  /// Medinfras operational time code, e.g. `OT-020`.
  final String operationalTimeCode;

  final String? roomCode;
  final List<PracticeWindow> windows;
}

/// A bookable window inside a practice session.
class PracticeWindow {
  const PracticeWindow({
    required this.session,
    required this.start,
    required this.end,
  });

  factory PracticeWindow.fromJson(Map<String, dynamic> json) => PracticeWindow(
    session: (json['session'] as num?)?.toInt() ?? 1,
    start: json['start'] as String? ?? '',
    end: json['end'] as String? ?? '',
  );

  final int session;

  /// `HH:mm`.
  final String start;
  final String end;
}

/// A queue position the patient can take on a given date.
///
/// The hospital books by queue number within a session rather than by exact
/// minute, so a "slot" is a number plus the session's time range — not a
/// fifteen-minute appointment.
class BookableSlot {
  const BookableSlot({
    required this.session,
    required this.number,
    required this.start,
    required this.end,
    this.room,
  });

  final int session;

  /// Queue number within the session.
  final int number;

  final String start;
  final String end;
  final String? room;

  String get timeLabel => '$start - $end';
}

/// The sessions available for one doctor on one date.
class DaySlots {
  const DaySlots({required this.date, required this.slots});

  factory DaySlots.fromJson(Map<String, dynamic> json) {
    final date =
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
    final sessions = json['sessions'];
    final slots = <BookableSlot>[];

    if (sessions is List) {
      for (final raw in sessions.whereType<Map>()) {
        final session = raw.cast<String, dynamic>();
        final available = session['available'];
        if (available is! List) continue;

        for (final entry in available.whereType<Map>()) {
          slots.add(
            BookableSlot(
              session: (session['session'] as num?)?.toInt() ?? 1,
              number: (entry['no'] as num?)?.toInt() ?? 0,
              start: session['start'] as String? ?? '',
              end: session['end'] as String? ?? '',
              room: session['room'] as String?,
            ),
          );
        }
      }
    }

    return DaySlots(date: date, slots: slots);
  }

  final DateTime date;
  final List<BookableSlot> slots;

  bool get isEmpty => slots.isEmpty;
}

/// A specific upcoming practice date for a doctor.
class UpcomingScheduleDate {
  const UpcomingScheduleDate({
    required this.date,
    this.unitCode = '',
    this.unitName = '',
    this.timeLabel = '',
    this.operationalTimeCode = '',
    this.roomCode,
    this.raw = const {},
  });

  final DateTime date;
  final String unitCode;
  final String unitName;
  final String timeLabel;
  final String operationalTimeCode;
  final String? roomCode;
  final Map<String, dynamic> raw;

  factory UpcomingScheduleDate.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['date'] ??
        json['practice_date'] ??
        json['schedule_date'] ??
        json['booking_date'] ??
        json['service_date'] ??
        json['day_date'] ??
        json['tanggal'] ??
        json['dt'];

    if (rawDate != null) {
      final str = rawDate.toString().trim();
      parsedDate = DateTime.tryParse(str);
      if (parsedDate == null) {
        final parts = str.split(RegExp(r'[-/]'));
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            // YYYY-MM-DD
            parsedDate = DateTime.tryParse(
              '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}',
            );
          } else if (parts[2].length == 4) {
            // DD-MM-YYYY
            parsedDate = DateTime.tryParse(
              '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
            );
          }
        }
      }
    }

    final schedulesList = json['schedules'] as List?;
    final firstSchedule = schedulesList?.isNotEmpty == true && schedulesList!.first is Map
        ? schedulesList.first as Map
        : const {};

    final time = json['operational_time_name'] as String? ??
        firstSchedule['operational_time_name'] as String? ??
        json['time_label'] as String? ??
        json['operational_time'] as String? ??
        json['time'] as String? ??
        json['jam_praktek'] as String? ??
        '';

    return UpcomingScheduleDate(
      date: parsedDate ?? DateTime.fromMillisecondsSinceEpoch(0),
      unitCode: json['service_unit_code'] as String? ??
          firstSchedule['service_unit_code'] as String? ??
          json['unit_code'] as String? ??
          json['unit'] as String? ??
          '',
      unitName: json['service_unit_name'] as String? ??
          firstSchedule['service_unit_name'] as String? ??
          json['unit_name'] as String? ??
          '',
      timeLabel: time,
      operationalTimeCode: json['operational_time_code'] as String? ??
          firstSchedule['operational_time_code'] as String? ??
          '',
      roomCode: json['room_code'] as String? ??
          firstSchedule['room_code'] as String?,
      raw: json,
    );
  }

  bool get isValidDate => date.year > 2000;
}
