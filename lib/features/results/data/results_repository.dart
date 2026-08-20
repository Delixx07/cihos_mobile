import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/exam_result.dart';

/// The patients this account can view results for, with their record numbers.
final resultPatientsProvider = Provider<List<ResultPatient>>((ref) {
  return const [
    ResultPatient(name: 'NADILA', medicalRecordNumber: '01012345'),
    ResultPatient(name: 'ANDRI (Suami)', medicalRecordNumber: '010304596'),
    ResultPatient(name: 'DEWI (Saudara)', medicalRecordNumber: '01098895'),
    ResultPatient(name: 'PUTRI (Anak)', medicalRecordNumber: '01023456'),
    ResultPatient(name: 'KARTIKA (Saudara)', medicalRecordNumber: '01076548'),
    ResultPatient(name: 'BAYU (Ayah)', medicalRecordNumber: '01076528'),
    ResultPatient(name: 'OLIVIA (Ibu)', medicalRecordNumber: '01049283'),
  ];
});

/// Stand-in examination results until the backend exists.
final examResultsProvider = Provider<List<ExamResult>>((ref) {
  return [
    ExamResult(
      id: 'r1',
      title: 'CT Scan Thorax',
      category: ExamCategory.radiologi,
      date: DateTime(2025, 3, 3),
      patientName: 'NADILA',
      documentAsset: 'assets/images/hasil_radiologi.jpg',
    ),
    ExamResult(
      id: 'r2',
      title: 'Blood Glucose, Blood Lipid',
      category: ExamCategory.laboratorium,
      date: DateTime(2025, 3, 18),
      patientName: 'NADILA',
      documentAsset: 'assets/images/hasil_lab.jpg',
    ),
    ExamResult(
      id: 'r3',
      title: 'Medical Check Up Lengkap',
      category: ExamCategory.mcu,
      date: DateTime(2025, 2, 20),
      patientName: 'NADILA',
    ),
    ExamResult(
      id: 'r4',
      title: 'Rontgen Thorax',
      category: ExamCategory.radiologi,
      date: DateTime(2025, 1, 12),
      patientName: 'ANDRI (Suami)',
      documentAsset: 'assets/images/hasil_radiologi.jpg',
    ),
  ];
});
