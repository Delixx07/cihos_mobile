/// How a patient can consult this doctor.
enum ConsultationMethod { appointment, videoCall }

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.hospital = 'Ciputra Hospital Surabaya',
    this.code,
    this.unitCode,
    this.rating,
    this.reviewCount,
    this.yearsOfExperience,
    this.consultationFee,
    this.photoAsset,
    this.about = '',
    this.methods = const {ConsultationMethod.appointment},
    this.education = const [],
    this.clinicalInterests = const [],
    this.awards = const [],
    this.courses = const [],
  });

  /// `paramedic_id` from the hospital system.
  final String id;

  final String name;
  final String specialty;
  final String hospital;

  /// `paramedic_code`, e.g. `D240001`.
  final String? code;

  /// Service unit this doctor practises in. Needed to request slots.
  final String? unitCode;

  /// The fields below are not published by the hospital API. They stay null
  /// rather than being filled with invented numbers — a fabricated rating on a
  /// medical booking screen would mislead patients choosing a doctor.
  final double? rating;
  final int? reviewCount;
  final int? yearsOfExperience;

  /// In IDR, when the hospital publishes it.
  final int? consultationFee;

  /// Portrait from the Figma export; falls back to an avatar icon.
  final String? photoAsset;
  final String about;

  final Set<ConsultationMethod> methods;
  final List<String> education;
  final List<String> clinicalInterests;
  final List<String> awards;
  final List<String> courses;

  bool supports(ConsultationMethod method) => methods.contains(method);

  /// Builds a doctor from `/api/taptalk/doctors`.
  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
    id: json['paramedic_id'].toString(),
    name: (json['name'] as String? ?? '').trim(),
    specialty: (json['specialty'] as String?)?.trim() ?? 'Lain-lain',
    code: json['paramedic_code'] as String?,
    unitCode: json['unit_code'] as String?,
  );

  Doctor copyWith({String? unitCode}) => Doctor(
    id: id,
    name: name,
    specialty: specialty,
    hospital: hospital,
    code: code,
    unitCode: unitCode ?? this.unitCode,
    rating: rating,
    reviewCount: reviewCount,
    yearsOfExperience: yearsOfExperience,
    consultationFee: consultationFee,
    photoAsset: photoAsset,
    about: about,
    methods: methods,
    education: education,
    clinicalInterests: clinicalInterests,
    awards: awards,
    courses: courses,
  );
}

class Specialty {
  const Specialty({
    required this.id,
    required this.name,
    required this.iconName,
  });

  final String id;
  final String name;

  /// Key for the icon asset; maps to a Material icon until Figma icons land.
  final String iconName;
}
