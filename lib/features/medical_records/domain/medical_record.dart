enum RecordType { visit, labResult, prescription, radiology }

class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.doctorName,
    this.diagnosis = '',
    this.notes = '',
    this.attachments = const [],
  });

  final String id;
  final String title;
  final RecordType type;
  final DateTime date;
  final String doctorName;
  final String diagnosis;
  final String notes;
  final List<String> attachments;
}

class LabResult {
  const LabResult({
    required this.name,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.isNormal,
  });

  final String name;
  final String value;
  final String unit;
  final String referenceRange;
  final bool isNormal;
}
