import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/booking/domain/booking.dart';
import '../../features/booking/presentation/booking_patient_screen.dart';
import '../../features/booking/presentation/booking_results_screen.dart';
import '../../features/booking/presentation/booking_schedule_screen.dart';
import '../../features/booking/presentation/booking_summary_screen.dart';
import '../../features/doctors/domain/doctor.dart';
import '../../features/doctors/presentation/doctor_finder_screen.dart';
import '../../features/doctors/presentation/doctor_list_screen.dart';
import '../../features/doctors/presentation/doctor_schedule_screen.dart';
import '../../features/emergency/presentation/emergency_screen.dart';
import '../../features/health_news/data/health_news_repository.dart';
import '../../features/health_news/domain/health_article.dart';
import '../../features/health_news/presentation/health_article_detail_screen.dart';
import '../../features/health_news/presentation/health_news_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/mcu/presentation/mcu_packages_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/patient_registration/domain/patient_draft.dart';
import '../../features/patient_registration/presentation/existing_patient_screen.dart';
import '../../features/patient_registration/presentation/new_patient_form_screen.dart';
import '../../features/patient_registration/presentation/patient_review_screen.dart';
import '../../features/patient_registration/presentation/patient_type_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/promo/presentation/promo_screen.dart';
import '../../features/results/presentation/exam_results_screen.dart';
import '../../features/results/presentation/result_viewer_screen.dart';
import '../../features/schedule/domain/scheduled_appointment.dart';
import '../../features/schedule/presentation/appointment_detail_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/wellness/presentation/wellness_screen.dart';
import '../../features/queue/presentation/queue_monitor_screen.dart';
import 'app_routes.dart';
import '../theme/app_motion.dart';

/// Destinations that require a signed-in patient.
const _guardedRoutes = {
  AppRoutes.home,
  AppRoutes.appointments,
  AppRoutes.health,
  AppRoutes.history,
  AppRoutes.profile,
  AppRoutes.notifications,
};

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    redirect: (context, state) {
      final isSignedIn = ref.read(authControllerProvider).isSignedIn;

      if (_guardedRoutes.contains(state.matchedLocation) && !isSignedIn) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            _fadeThrough(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
            _slideUp(state, const RegisterScreen()),
      ),

      // Bottom navigation destinations. Tabs crossfade so switching between
      // them does not read as forward or backward movement.
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _fadeThrough(state, const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.appointments,
        pageBuilder: (context, state) =>
            _fadeThrough(state, const ScheduleScreen()),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => AppointmentDetailScreen(
              appointmentId: state.pathParameters['id']!,
              initialAppointment: state.extra is ScheduledAppointment
                  ? state.extra as ScheduledAppointment
                  : null,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.health,
        pageBuilder: (context, state) =>
            _fadeThrough(state, const WellnessScreen()),
      ),
      GoRoute(
        path: AppRoutes.history,
        pageBuilder: (context, state) =>
            _fadeThrough(state, const HistoryScreen()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) =>
            _fadeThrough(state, const ProfileScreen()),
      ),

      // Pushed from home.
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.emergency,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const EmergencyScreen()),
      ),
      GoRoute(
        path: AppRoutes.queueMonitor,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const QueueMonitorScreen()),
      ),

      GoRoute(
        path: AppRoutes.examResults,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const ExamResultsScreen()),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => ResultViewerScreen(
              resultId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.mcuPackages,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const McuPackagesScreen()),
      ),
      GoRoute(
        path: AppRoutes.promo,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const PromoScreen()),
      ),
      GoRoute(
        path: AppRoutes.healthNews,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const HealthNewsScreen()),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              HealthArticle? article;
              if (state.extra is HealthArticle) {
                article = state.extra as HealthArticle;
              }
              if (article == null) {
                final container = ProviderScope.containerOf(context);
                final articles = container.read(healthArticlesProvider);
                article = articles.firstWhere(
                  (a) => a.id == id,
                  orElse: () => HealthArticle(
                    id: id,
                    title: 'Artikel Kesehatan',
                    date: DateTime.now(),
                    imageAsset: 'assets/images/info kesehatan/runner 3.png',
                  ),
                );
              }
              return HealthArticleDetailScreen(article: article);
            },
          ),
        ],
      ),

      // Finding and choosing a doctor.
      GoRoute(
        path: AppRoutes.doctors,
        pageBuilder: (context, state) => _sharedAxis(
          state,
          DoctorListScreen(
            initialUnitCode:
                state.extra is String ? state.extra as String : null,
          ),
        ),
      ),
      // Booking flow. The draft rides along with the navigation rather than
      // living in global state, so an abandoned booking cannot leak into the
      // next attempt.
      GoRoute(
        path: AppRoutes.appointmentSearch,
        pageBuilder: (context, state) => _sharedAxis(
          state,
          DoctorListScreen(
            kind: BookingKind.appointment,
            isAddingAnother: state.extra == true,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.videoCallSearch,
        pageBuilder: (context, state) => _sharedAxis(
          state,
          DoctorListScreen(
            kind: BookingKind.videoCall,
            isAddingAnother: state.extra == true,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.bookingResults,
        builder: (context, state) =>
            BookingResultsScreen(booking: _bookingFrom(state)),
      ),
      GoRoute(
        path: AppRoutes.bookingSchedule,
        builder: (context, state) =>
            BookingScheduleScreen(booking: _bookingFrom(state)),
      ),
      GoRoute(
        path: AppRoutes.bookingPatient,
        builder: (context, state) =>
            BookingPatientScreen(booking: _bookingFrom(state)),
      ),
      GoRoute(
        path: AppRoutes.bookingSummary,
        builder: (context, state) =>
            BookingSummaryScreen(booking: _bookingFrom(state)),
      ),
      GoRoute(
        path: AppRoutes.doctorFinder,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const DoctorFinderScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.doctorSchedule}/:id',
        builder: (context, state) => DoctorScheduleScreen(
          doctorId: state.pathParameters['id']!,
          doctor: state.extra is Doctor ? state.extra as Doctor : null,
          initialDate: state.extra is DateTime ? state.extra as DateTime : null,
        ),
      ),

      // Adding a patient, step by step.
      GoRoute(
        path: AppRoutes.patientType,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const PatientTypeScreen()),
      ),
      GoRoute(
        path: AppRoutes.registerExistingPatient,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const ExistingPatientScreen()),
      ),
      GoRoute(
        path: AppRoutes.registerNewPatient,
        pageBuilder: (context, state) =>
            _sharedAxis(state, const NewPatientFormScreen()),
      ),
      GoRoute(
        path: AppRoutes.patientReview,
        builder: (context, state) => PatientReviewScreen(
          // The draft travels with the navigation rather than through global
          // state, so a half-filled form cannot leak between attempts.
          draft: state.extra as PatientDraft? ?? const PatientDraft(),
        ),
      ),
    ],
  );
});

/// Reads the in-progress booking off the navigation, defaulting to a fresh
/// appointment when a route is opened directly.
Booking _bookingFrom(GoRouterState state) =>
    state.extra as Booking? ?? const Booking(kind: BookingKind.appointment);

/// Fade-through — for tab switches, where neither direction is "forward".
///
/// The outgoing page fades and shrinks a touch; the incoming one fades in as
/// it settles to full size. Scaling rather than sliding keeps the tabs feeling
/// like peers rather than a sequence.
CustomTransitionPage<void> _fadeThrough(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.normal,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final entering = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enter,
      );

      return FadeTransition(
        opacity: entering,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(entering),
          child: child,
        ),
      );
    },
  );
}

/// Shared-axis — for pushes, where there is a real sense of going deeper.
///
/// The new page slides in from the right while the one behind it slides out to
/// the left and dims, so the stack reads as a horizontal filmstrip. Popping
/// plays the same motion in reverse, which is what makes back feel like back.
CustomTransitionPage<void> _sharedAxis(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.slow,
    reverseTransitionDuration: AppMotion.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final entering = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
      );
      // Drives the outgoing page while a new one covers it.
      final leaving = CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-AppMotion.pageSlide, 0),
        ).animate(leaving),
        child: FadeTransition(
          // Dim the page underneath instead of leaving it fully lit.
          opacity: Tween<double>(begin: 1, end: 0.7).animate(leaving),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(entering),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Sign-up rises from the bottom over sign-in.
CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.slow,
    reverseTransitionDuration: AppMotion.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
