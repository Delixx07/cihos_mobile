import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/doctor.dart';

/// Stand-in doctor list until the backend exists.
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
    Doctor(
      id: 'd3',
      name: 'dr. Fidela Olivia Wijono, Sp.M',
      specialty: 'Mata',
      hospital: 'Ciputra Hospital Surabaya',
      rating: 4.8,
      reviewCount: 143,
      yearsOfExperience: 9,
      consultationFee: 230000,
      methods: {ConsultationMethod.appointment},
      education: ['Universitas Brawijaya Malang, 2015'],
      clinicalInterests: ['Katarak', 'Kelainan Refraksi'],
    ),
    Doctor(
      id: 'd4',
      name: 'dr. Endy Wahyudi Sp.B',
      specialty: 'Bedah Umum',
      hospital: 'Ciputra Hospital Surabaya',
      rating: 4.7,
      reviewCount: 128,
      yearsOfExperience: 15,
      consultationFee: 300000,
      methods: {ConsultationMethod.appointment},
      education: ['Universitas Indonesia, 2009'],
      clinicalInterests: ['Bedah Digestif'],
    ),
    Doctor(
      id: 'd5',
      name: 'dr. Melia Bogari, Sp.B.P.R.E',
      specialty: 'Bedah Plastik',
      hospital: 'Ciputra Hospital Surabaya',
      rating: 4.9,
      reviewCount: 97,
      yearsOfExperience: 10,
      consultationFee: 350000,
      methods: {ConsultationMethod.appointment, ConsultationMethod.videoCall},
      education: ['Universitas Padjadjaran Bandung, 2014'],
      clinicalInterests: ['Bedah Rekonstruksi', 'Estetika'],
    ),
    Doctor(
      id: 'd6',
      name: 'dr. Sidharta Suwanto, Sp.Rad',
      specialty: 'Radiologi',
      hospital: 'Ciputra Hospital Surabaya',
      rating: 4.8,
      reviewCount: 88,
      yearsOfExperience: 12,
      consultationFee: 210000,
      methods: {ConsultationMethod.appointment},
      education: ['Universitas Gadjah Mada Yogyakarta, 2012'],
      clinicalInterests: ['Radiologi Diagnostik'],
    ),
    Doctor(
      id: 'd7',
      name: 'drg. Ermin Budiyanti Sukisno',
      specialty: 'Gigi & Kesehatan Mulut',
      hospital: 'Ciputra Hospital Surabaya',
      rating: 4.7,
      reviewCount: 154,
      yearsOfExperience: 8,
      consultationFee: 180000,
      methods: {ConsultationMethod.appointment},
      education: ['Universitas Airlangga Surabaya, 2016'],
      clinicalInterests: ['Konservasi Gigi'],
    ),
    Doctor(
      id: 'd8',
      name: 'dr. Harry Febryanto, Sp.A',
      specialty: 'Anak',
      hospital: 'Ciputra Hospital Surabaya',
      rating: 4.8,
      reviewCount: 132,
      yearsOfExperience: 10,
      consultationFee: 220000,
      methods: {ConsultationMethod.appointment, ConsultationMethod.videoCall},
      education: ['Universitas Hangtuah Surabaya, 2014'],
      clinicalInterests: ['Alergi Anak'],
    ),
  ];
});

/// Looks a doctor up by id; null when the id is unknown.
final doctorByIdProvider = Provider.family<Doctor?, String>((ref, id) {
  final doctors = ref.watch(doctorsProvider);
  for (final doctor in doctors) {
    if (doctor.id == id) return doctor;
  }
  return null;
});
