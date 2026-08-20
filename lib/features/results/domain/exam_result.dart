enum ExamCategory { laboratorium, mcu, radiologi }

extension ExamCategoryLabel on ExamCategory {
  String get label => switch (this) {
    ExamCategory.laboratorium => 'Laboratorium',
    ExamCategory.mcu => 'MCU',
    ExamCategory.radiologi => 'Radiologi',
  };

  /// Radiology results open as an image; the rest render as a document.
  bool get isImagery => this == ExamCategory.radiologi;
}

/// One finished examination belonging to a patient.
class ExamResult {
  const ExamResult({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.patientName,
    this.documentAsset,
  });

  final String id;
  final String title;
  final ExamCategory category;
  final DateTime date;
  final String patientName;

  /// The scan or report export; null until the file is available.
  final String? documentAsset;
}

/// A patient the account can view results for.
class ResultPatient {
  const ResultPatient({required this.name, required this.medicalRecordNumber});

  final String name;
  final String medicalRecordNumber;
}
