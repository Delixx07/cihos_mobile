/// How a past visit ended.
enum VisitOutcome { completed, cancelled, missed }

extension VisitOutcomeLabel on VisitOutcome {
  String get label => switch (this) {
    VisitOutcome.completed => 'Selesai',
    VisitOutcome.cancelled => 'Dibatalkan',
    VisitOutcome.missed => 'Tidak Hadir',
  };
}

/// Which kind of consultation the past visit was.
enum VisitKind { appointment, videoCall }

extension VisitKindLabel on VisitKind {
  String get label => switch (this) {
    VisitKind.appointment => 'Janji Temu Dokter',
    VisitKind.videoCall => 'Video Call Dokter',
  };
}

/// A finished visit as it appears in the history tab.
class PastAppointment {
  const PastAppointment({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.specialty,
    required this.startsAt,
    required this.endsAt,
    required this.outcome,
    this.kind = VisitKind.appointment,
  });

  final String id;
  final String patientName;
  final String doctorName;
  final String specialty;
  final DateTime startsAt;
  final DateTime endsAt;
  final VisitOutcome outcome;
  final VisitKind kind;

  String get timeRange {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(startsAt.hour)}:${two(startsAt.minute)} - '
        '${two(endsAt.hour)}:${two(endsAt.minute)} WIB';
  }
}
