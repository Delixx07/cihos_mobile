/// How a patient can consult this doctor.
enum ConsultationMethod { appointment, videoCall }

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.rating,
    required this.reviewCount,
    required this.yearsOfExperience,
    required this.consultationFee,
    this.photoAsset,
    this.about = '',
    this.methods = const {ConsultationMethod.appointment},
    this.education = const [],
    this.clinicalInterests = const [],
    this.awards = const [],
    this.courses = const [],
  });

  final String id;
  final String name;
  final String specialty;
  final String hospital;
  final double rating;
  final int reviewCount;
  final int yearsOfExperience;

  /// In IDR.
  final int consultationFee;

  /// Portrait from the Figma export; falls back to an avatar icon.
  final String? photoAsset;
  final String about;

  final Set<ConsultationMethod> methods;
  final List<String> education;
  final List<String> clinicalInterests;
  final List<String> awards;
  final List<String> courses;

  bool supports(ConsultationMethod method) => methods.contains(method);
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
