/// Whether the visit is still running to plan.
enum AppointmentStatus { onSchedule, rescheduled, cancelled }

extension AppointmentStatusLabel on AppointmentStatus {
  String get label => switch (this) {
    AppointmentStatus.onSchedule => 'Sesuai Jadwal',
    AppointmentStatus.rescheduled => 'Diubah',
    AppointmentStatus.cancelled => 'Dibatalkan',
  };
}

/// A booked visit as it appears in the schedule tab.
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

  /// "Jaminan Pribadi" or the insurer's name.
  final String guaranteeType;
  final String? partnerId;
  final AppointmentStatus status;

  String get timeRange {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(startsAt.hour)}:${two(startsAt.minute)} - '
        '${two(endsAt.hour)}:${two(endsAt.minute)} WIB';
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
