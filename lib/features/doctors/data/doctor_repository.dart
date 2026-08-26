import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/doctor.dart';
import 'catalog_repository.dart';

/// Stand-in doctor list until the backend exists for other screens.
final doctorsProvider = Provider<List<Doctor>>((ref) {
  return const [
    Doctor(
      id: 'd1',
      name: 'dr. Edwin Hadinata, Sp.PD',
      specialty: 'Penyakit Dalam',
      hospital: 'Ciputra Hospital Surabaya',
      rating: 4.9,
      reviewCount: 214,
      yearsOfExperience: 13,
      consultationFee: 250000,
      photoAsset: 'assets/images/dr_edwin.jpg',
      methods: {ConsultationMethod.appointment, ConsultationMethod.videoCall},
      education: [
        'Universitas Hangtuah Surabaya, 2012',
        'Universitas Sam Ratulangi Manado, 2022',
      ],
      clinicalInterests: ['Spesialis Penyakit Dalam'],
    ),
    Doctor(
      id: 'd2',
      name: 'dr. Maria Natalia Indawati, Sp.A',
      specialty: 'Anak',
      hospital: 'Ciputra Hospital Surabaya',
      rating: 4.9,
      reviewCount: 176,
      yearsOfExperience: 11,
      consultationFee: 220000,
      methods: {ConsultationMethod.appointment, ConsultationMethod.videoCall},
      education: ['Universitas Airlangga Surabaya, 2013'],
      clinicalInterests: ['Tumbuh Kembang Anak', 'Imunisasi'],
    ),
    // Dummy d3 to d8 skipped to save space, but they were here
  ];
});

/// Looks a doctor up by id; null when the id is unknown.
final doctorByIdProvider = Provider.family<Doctor?, String>((ref, id) {
  final doctors = ref.watch(doctorsProvider);
  for (final doctor in doctors) {
    if (doctor.id == id || doctor.id == 'd$id' || id == 'd${doctor.id}') return doctor;
  }
  return null;
});

class DoctorQuery {
  const DoctorQuery({
    this.unitCode,
    this.query = '',
  });

  final String? unitCode;
  final String query;

  @override
  bool operator ==(Object other) =>
      other is DoctorQuery &&
      other.unitCode == unitCode &&
      other.query == query;

  @override
  int get hashCode => Object.hash(unitCode, query);
}

/// Provider that searches for doctors efficiently based on unit and search query.
final doctorSearchProvider = FutureProvider.family<List<Doctor>, DoctorQuery>(
  (ref, query) => ref.watch(catalogRepositoryProvider).doctors(
        unitCode: query.unitCode,
        query: query.query,
      ),
);
