/// The patient record being assembled across the registration steps.
class PatientDraft {
  const PatientDraft({
    this.medicalRecordNumber,
    this.familyRelation,
    this.birthDate,
    this.gender,
    this.name,
    this.idType,
    this.idNumber,
    this.nationality,
    this.maritalStatus,
    this.religion,
    this.education,
    this.occupation,
    this.phone,
    this.email,
    this.address,
    this.province,
    this.city,
    this.village,
    this.agreedToTerms = false,
    this.wantsWhatsAppUpdates = false,
  });

  // Step 2 — existing patient lookup.
  final String? medicalRecordNumber;
  final String? familyRelation;
  final DateTime? birthDate;
  final String? gender;

  // Step 3 — identity.
  final String? name;
  final String? idType;
  final String? idNumber;
  final String? nationality;

  // Step 3 — additional information.
  final String? maritalStatus;
  final String? religion;
  final String? education;
  final String? occupation;

  // Step 3 — contact.
  final String? phone;
  final String? email;
  final String? address;
  final String? province;
  final String? city;
  final String? village;

  final bool agreedToTerms;
  final bool wantsWhatsAppUpdates;

  PatientDraft copyWith({
    String? medicalRecordNumber,
    String? familyRelation,
    DateTime? birthDate,
    String? gender,
    String? name,
    String? idType,
    String? idNumber,
    String? nationality,
    String? maritalStatus,
    String? religion,
    String? education,
    String? occupation,
    String? phone,
    String? email,
    String? address,
    String? province,
    String? city,
    String? village,
    bool? agreedToTerms,
    bool? wantsWhatsAppUpdates,
  }) {
    return PatientDraft(
      medicalRecordNumber: medicalRecordNumber ?? this.medicalRecordNumber,
      familyRelation: familyRelation ?? this.familyRelation,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      name: name ?? this.name,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      nationality: nationality ?? this.nationality,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      religion: religion ?? this.religion,
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      province: province ?? this.province,
      city: city ?? this.city,
      village: village ?? this.village,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      wantsWhatsAppUpdates:
          wantsWhatsAppUpdates ?? this.wantsWhatsAppUpdates,
    );
  }
}

/// Option lists for the dropdowns, standing in for reference data the backend
/// will eventually serve.
abstract final class PatientOptions {
  static const familyRelations = [
    'Diri Sendiri',
    'Suami/Istri',
    'Anak',
    'Orang Tua',
    'Saudara Kandung',
    'Lainnya',
  ];

  static const idTypes = ['KTP (NIK)', 'Kartu Keluarga', 'Paspor', 'SIM'];

  static const genders = ['Laki-laki', 'Perempuan'];

  static const nationalities = ['Indonesia', 'Warga Negara Asing'];

  static const maritalStatuses = [
    'Belum Menikah',
    'Menikah',
    'Cerai Hidup',
    'Cerai Mati',
  ];

  static const religions = [
    'Islam',
    'Kristen',
    'Katolik',
    'Hindu',
    'Buddha',
    'Konghucu',
    'Lainnya',
  ];

  static const educations = [
    'Tidak Sekolah',
    'SD',
    'SMP',
    'SMA/SMK',
    'D3',
    'S1',
    'S2',
    'S3',
  ];

  static const occupations = [
    'Pelajar/Mahasiswa',
    'Karyawan Swasta',
    'PNS',
    'Wiraswasta',
    'Ibu Rumah Tangga',
    'Tidak Bekerja',
    'Lainnya',
  ];

  static const provinces = [
    'Jawa Timur',
    'Jawa Tengah',
    'Jawa Barat',
    'DKI Jakarta',
    'Bali',
  ];

  static const cities = ['Surabaya', 'Sidoarjo', 'Gresik', 'Malang'];

  static const villages = ['Gubeng', 'Wonokromo', 'Tegalsari', 'Sukolilo'];
}
