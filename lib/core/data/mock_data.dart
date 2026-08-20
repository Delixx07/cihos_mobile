import '../../features/appointments/domain/appointment.dart';
import '../../features/auth/domain/user.dart';
import '../../features/doctors/domain/doctor.dart';
import '../../features/medical_records/domain/medical_record.dart';

/// Stand-in data used until the backend exists. Every repository reads from
/// here, so swapping in real API calls only touches the repository layer.
abstract final class MockData {
  static final currentUser = AppUser(
    id: 'u1',
    fullName: 'Dustin Felix',
    email: 'dustinfelix01@gmail.com',
    phone: '081234567890',
    nik: '3201234567890001',
    birthDate: DateTime(2003, 5, 14),
    gender: Gender.male,
    address: 'Jl. Merdeka No. 12, Bandung',
  );

  static const specialties = <Specialty>[
    Specialty(id: 's1', name: 'Umum', iconName: 'general'),
    Specialty(id: 's2', name: 'Jantung', iconName: 'cardiology'),
    Specialty(id: 's3', name: 'Anak', iconName: 'pediatrics'),
    Specialty(id: 's4', name: 'Gigi', iconName: 'dental'),
    Specialty(id: 's5', name: 'Mata', iconName: 'ophthalmology'),
    Specialty(id: 's6', name: 'Kulit', iconName: 'dermatology'),
    Specialty(id: 's7', name: 'Saraf', iconName: 'neurology'),
    Specialty(id: 's8', name: 'Kandungan', iconName: 'obgyn'),
  ];

  static const doctors = <Doctor>[
    Doctor(
      id: 'd1',
      name: 'dr. Siti Rahmawati, Sp.JP',
      specialty: 'Jantung',
      hospital: 'RS Cihos Pusat',
      rating: 4.9,
      reviewCount: 214,
      yearsOfExperience: 12,
      consultationFee: 250000,
      about:
          'Spesialis jantung dan pembuluh darah dengan fokus pada penanganan '
          'hipertensi dan gagal jantung.',
    ),
    Doctor(
      id: 'd2',
      name: 'dr. Ahmad Hidayat, Sp.A',
      specialty: 'Anak',
      hospital: 'RS Cihos Pusat',
      rating: 4.8,
      reviewCount: 189,
      yearsOfExperience: 9,
      consultationFee: 180000,
      about:
          'Dokter spesialis anak, berpengalaman menangani tumbuh kembang '
          'dan imunisasi.',
    ),
    Doctor(
      id: 'd3',
      name: 'drg. Maya Kusuma',
      specialty: 'Gigi',
      hospital: 'RS Cihos Cabang Dago',
      rating: 4.7,
      reviewCount: 132,
      yearsOfExperience: 7,
      consultationFee: 150000,
      about: 'Dokter gigi umum dengan layanan perawatan dan estetika gigi.',
    ),
    Doctor(
      id: 'd4',
      name: 'dr. Budi Santoso, Sp.M',
      specialty: 'Mata',
      hospital: 'RS Cihos Pusat',
      rating: 4.9,
      reviewCount: 176,
      yearsOfExperience: 15,
      consultationFee: 220000,
      about:
          'Spesialis mata dengan keahlian pada katarak dan kelainan refraksi.',
    ),
    Doctor(
      id: 'd5',
      name: 'dr. Rina Wijaya',
      specialty: 'Umum',
      hospital: 'RS Cihos Cabang Dago',
      rating: 4.6,
      reviewCount: 98,
      yearsOfExperience: 5,
      consultationFee: 100000,
      about: 'Dokter umum untuk pemeriksaan kesehatan dan keluhan sehari-hari.',
    ),
  ];

  static List<Appointment> get appointments {
    final now = DateTime.now();
    return [
      Appointment(
        id: 'a1',
        doctor: doctors[0],
        scheduledAt: DateTime(now.year, now.month, now.day + 2, 9, 30),
        status: AppointmentStatus.upcoming,
        type: AppointmentType.inPerson,
        complaint: 'Kontrol rutin tekanan darah',
        queueNumber: 4,
      ),
      Appointment(
        id: 'a2',
        doctor: doctors[4],
        scheduledAt: DateTime(now.year, now.month, now.day + 5, 14, 0),
        status: AppointmentStatus.upcoming,
        type: AppointmentType.video,
        complaint: 'Batuk dan demam ringan',
      ),
      Appointment(
        id: 'a3',
        doctor: doctors[2],
        scheduledAt: DateTime(now.year, now.month, now.day - 12, 10, 0),
        status: AppointmentStatus.completed,
        type: AppointmentType.inPerson,
        complaint: 'Pembersihan karang gigi',
      ),
    ];
  }

  static List<MedicalRecord> get medicalRecords {
    final now = DateTime.now();
    return [
      MedicalRecord(
        id: 'm1',
        title: 'Pemeriksaan Jantung Rutin',
        type: RecordType.visit,
        date: DateTime(now.year, now.month - 1, 8),
        doctorName: 'dr. Siti Rahmawati, Sp.JP',
        diagnosis: 'Hipertensi tingkat 1',
        notes: 'Disarankan mengurangi asupan garam dan olahraga ringan rutin.',
      ),
      MedicalRecord(
        id: 'm2',
        title: 'Hasil Lab Darah Lengkap',
        type: RecordType.labResult,
        date: DateTime(now.year, now.month - 1, 8),
        doctorName: 'dr. Siti Rahmawati, Sp.JP',
      ),
      MedicalRecord(
        id: 'm3',
        title: 'Resep Obat Hipertensi',
        type: RecordType.prescription,
        date: DateTime(now.year, now.month - 1, 8),
        doctorName: 'dr. Siti Rahmawati, Sp.JP',
        notes: 'Amlodipine 5mg — 1x sehari setelah makan malam, 30 hari.',
      ),
      MedicalRecord(
        id: 'm4',
        title: 'Rontgen Thorax',
        type: RecordType.radiology,
        date: DateTime(now.year, now.month - 3, 22),
        doctorName: 'dr. Rina Wijaya',
        diagnosis: 'Tidak ditemukan kelainan',
      ),
    ];
  }

  static const labResults = <LabResult>[
    LabResult(
      name: 'Hemoglobin',
      value: '14.2',
      unit: 'g/dL',
      referenceRange: '13.0 - 17.0',
      isNormal: true,
    ),
    LabResult(
      name: 'Leukosit',
      value: '11.800',
      unit: '/µL',
      referenceRange: '4.000 - 10.000',
      isNormal: false,
    ),
    LabResult(
      name: 'Trombosit',
      value: '265.000',
      unit: '/µL',
      referenceRange: '150.000 - 400.000',
      isNormal: true,
    ),
    LabResult(
      name: 'Kolesterol Total',
      value: '215',
      unit: 'mg/dL',
      referenceRange: '< 200',
      isNormal: false,
    ),
  ];
}
