/// Route paths, kept in one place so navigation calls never hardcode strings.
abstract final class AppRoutes {
  static const welcome = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';

  // Bottom navigation destinations.
  static const home = '/home';
  static const appointments = '/appointments';
  static const health = '/health';
  static const history = '/history';
  static const profile = '/profile';

  // Reached from the home screen.
  static const notifications = '/notifications';
  static const emergency = '/emergency';
  static const queueMonitor = '/queue-monitor';
  static const promo = '/promo';
  static const healthNews = '/health-news';
  static const savedArticles = '/saved-articles';
  static const doctors = '/doctors';
  static const doctorFinder = '/doctor-finder';
  static const doctorSchedule = '/doctor-schedule';
  // Booking a consultation — same screens for appointments and video calls.
  static const appointmentSearch = '/booking/appointment';
  static const videoCallSearch = '/booking/video-call';
  static const bookingResults = '/booking/results';
  static const bookingSchedule = '/booking/schedule';
  static const bookingPatient = '/booking/patient';
  static const bookingSummary = '/booking/summary';
  static const examResults = '/exam-results';
  static const mcuPackages = '/mcu-packages';

  // Adding a patient to the account, step by step.
  static const patientType = '/patient/type';
  static const registerExistingPatient = '/patient/existing';
  static const registerNewPatient = '/patient/new';
  static const patientReview = '/patient/review';
}
