import '../../doctors/domain/doctor.dart';

enum AppointmentStatus { upcoming, completed, cancelled }

enum AppointmentType { inPerson, video, chat }

class Appointment {
  const Appointment({
    required this.id,
    required this.doctor,
    required this.scheduledAt,
    required this.status,
    required this.type,
    this.complaint = '',
    this.queueNumber,
  });

  final String id;
  final Doctor doctor;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final AppointmentType type;
  final String complaint;
  final int? queueNumber;
}

/// One bookable slot in a doctor's schedule.
class TimeSlot {
  const TimeSlot({required this.time, required this.isAvailable});

  final DateTime time;
  final bool isAvailable;
}
