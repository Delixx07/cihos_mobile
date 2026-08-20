/// A service unit ("klinik") the hospital books appointments into.
///
/// The API returns names in uppercase English — `CARDIOLOGY`,
/// `TELINGA HIDUNG TENGGOROKAN KEPALA LEHER (THT-KL)`. Those are the
/// hospital's own records, so they are kept verbatim as [name] and presented
/// through [displayName], which is title-cased for reading.
class Clinic {
  const Clinic({required this.code, required this.name});

  factory Clinic.fromJson(Map<String, dynamic> json) => Clinic(
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );

  /// Service unit code, e.g. `SU-015`. Required when asking for slots.
  final String code;

  /// The hospital's own spelling, usually uppercase.
  final String name;

  /// The name shown to patients.
  ///
  /// The hospital records clinics in English (`INTERNAL MEDICINE`), but the
  /// app is Indonesian throughout — a patient looking for "Penyakit Dalam"
  /// should not have to recognise the English term. Known units are
  /// translated; anything unmapped falls back to title case so a new clinic
  /// still reads sensibly instead of shouting in capitals.
  String get displayName => _indonesian[name.toUpperCase()] ?? _titleCase(name);

  /// Clinic names as patients know them. Keys are the hospital's spellings.
  static const _indonesian = {
    'ANDROLOGY': 'Andrologi',
    'CARDIOLOGY': 'Jantung',
    'CARDIOVASCULAR THORACIC SURGERY': 'Bedah Toraks Kardiovaskular',
    'CURIE ONCOLOGY CLINIC': 'Klinik Onkologi Curie',
    'DENTAL': 'Gigi',
    'DERMATOLOGY': 'Kulit dan Kelamin',
    'DIGESTIVE SURGERY': 'Bedah Digestif',
    'ENT': 'THT',
    'GENERAL SURGERY': 'Bedah Umum',
    'INTERNAL MEDICINE': 'Penyakit Dalam',
    'MCU CLINIC': 'Klinik MCU',
    'MEDICAL & SPORT REHABILITATION CENTER': 'Rehabilitasi Medik dan Olahraga',
    'MEDICAL CHECKUP': 'Medical Check-Up',
    'NEUROLOGY': 'Saraf',
    'NEUROSURGERY': 'Bedah Saraf',
    'NUCLEAR MEDICINE & ONCOLOGY RADIATION CURIE':
        'Kedokteran Nuklir dan Radiasi Onkologi',
    'NUTRITION': 'Gizi',
    'OBSTETRICS AND GYNECOLOGY': 'Kandungan dan Kebidanan',
    'ONCOLOGY': 'Onkologi',
    'OPERATING THEATRE': 'Kamar Operasi',
    'OPHTHALMOLOGY': 'Mata',
    'ORTHOPEDIC & TRAUMATOLOGY': 'Ortopedi dan Traumatologi',
    'PAIN CLINIC/ANESTESI': 'Klinik Nyeri / Anestesi',
    'PEDIATRIC': 'Anak',
    'PEDIATRIC SURGERY': 'Bedah Anak',
    'PHYSICAL REHABILITATION CENTER': 'Rehabilitasi Fisik',
    'PLASTIC SURGERY': 'Bedah Plastik',
    'PSYCHIATRY': 'Kesehatan Jiwa',
    'PSYCHOLOGY': 'Psikologi',
    'PULMONOLOGY': 'Paru',
    'RADIOLOGY': 'Radiologi',
    'UMUM': 'Umum',
    'UROLOGY': 'Urologi',
  };

  static String _titleCase(String value) {
    if (value.isEmpty) return value;

    return value
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          // Leave bracketed acronyms such as (THT-KL) alone.
          if (word.startsWith('(') || word.length <= 3 && !word.contains('-')) {
            return word;
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
