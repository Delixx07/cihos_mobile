import 'package:cihos_mobile/core/widgets/app_button.dart';
import 'package:cihos_mobile/features/auth/presentation/login_screen.dart';
import 'package:cihos_mobile/features/auth/presentation/register_screen.dart';
import 'package:cihos_mobile/features/auth/presentation/welcome_screen.dart';
import 'package:cihos_mobile/features/health_news/presentation/health_article_detail_screen.dart';
import 'package:cihos_mobile/features/health_news/presentation/health_news_screen.dart';
import 'package:cihos_mobile/features/history/presentation/history_screen.dart';
import 'package:cihos_mobile/features/home/presentation/home_screen.dart';
import 'package:cihos_mobile/features/mcu/presentation/mcu_packages_screen.dart';
import 'package:cihos_mobile/features/results/presentation/exam_results_screen.dart';
import 'package:cihos_mobile/features/results/presentation/result_viewer_screen.dart';
import 'package:cihos_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:cihos_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:cihos_mobile/features/patient_registration/presentation/new_patient_form_screen.dart';
import 'package:cihos_mobile/features/patient_registration/presentation/patient_type_screen.dart';
import 'package:cihos_mobile/features/profile/presentation/profile_screen.dart';
import 'package:cihos_mobile/features/doctors/presentation/doctor_finder_screen.dart';
import 'package:cihos_mobile/features/doctors/presentation/doctor_list_screen.dart';
import 'package:cihos_mobile/features/doctors/presentation/doctor_schedule_screen.dart';
import 'package:cihos_mobile/features/promo/presentation/promo_screen.dart';
import 'package:cihos_mobile/features/schedule/presentation/appointment_detail_screen.dart';
import 'package:cihos_mobile/features/schedule/presentation/schedule_screen.dart';
import 'package:cihos_mobile/features/wellness/presentation/wellness_screen.dart';
import 'package:cihos_mobile/features/booking/presentation/booking_patient_screen.dart';
import 'package:cihos_mobile/features/booking/presentation/booking_results_screen.dart';
import 'package:cihos_mobile/features/booking/presentation/booking_schedule_screen.dart';
import 'package:cihos_mobile/features/booking/presentation/booking_search_screen.dart';
import 'package:cihos_mobile/features/booking/presentation/booking_summary_screen.dart';
import 'package:cihos_mobile/features/queue/presentation/queue_monitor_screen.dart';
import 'package:cihos_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cihos_mobile/core/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cihos_mobile/core/network/api_exception.dart';
import 'package:cihos_mobile/features/auth/data/auth_repository.dart';
import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_catalog_repository.dart';
import 'package:cihos_mobile/features/doctors/data/catalog_repository.dart';

/// Gives the test a phone-shaped viewport; the default 800x600 is landscape
/// and nothing in this app is laid out for it.
void _usePhoneViewport(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 2.625
    // A real phone reserves space for the status bar and the gesture bar.
    // Without these the bottom nav gets more room in tests than on device,
    // which hides overflows that users actually see.
    ..padding = const FakeViewPadding(top: 63, bottom: 63)
    ..viewPadding = const FakeViewPadding(top: 63, bottom: 63);
  addTearDown(tester.view.reset);
}

/// Pumps the app and waits out the splash timer, landing on onboarding.
Future<void> _startAtOnboarding(WidgetTester tester) async {
  _usePhoneViewport(tester);
  await tester.pumpWidget(
    ProviderScope(
      // Keeps tests off the network: the hospital API is on an internal
      // network, so a real call would make these fail for the wrong reason.
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      ],
      child: const CihosApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

/// Goes one step further, tapping through onboarding to the sign-in form.
Future<void> _startAtLogin(WidgetTester tester) async {
  await _startAtOnboarding(tester);
  await tester.tap(find.text('Mulai'));
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).first,
    FakeAuthRepository.email,
  );
  await tester.enterText(
    find.byType(TextFormField).last,
    FakeAuthRepository.password,
  );
  await tester.tap(find.text('Masuk').last);
  await tester.pumpAndSettle();
}

/// Searches the video-call flow for the seeded doctor, landing on results.
Future<void> _searchForEdwin(WidgetTester tester) async {
  await tester.tap(find.text('Video Call Dokter'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'Edwin');
  await tester.tap(find.text('Selanjutnya, Pilih Dokter'));
  await tester.pumpAndSettle();
}

/// Goes all the way to the patient step with a slot already chosen.
Future<void> _reachPatientStep(WidgetTester tester) async {
  await _searchForEdwin(tester);
  await tester.tap(find.text('12:00 - 12:15').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lanjut'));
  await tester.pumpAndSettle();
}

/// Opens patient registration, reached through the patient picker sheet.
Future<void> _reachPatientRegistration(WidgetTester tester) async {
  await _reachPatientStep(tester);
  await tester.tap(find.byKey(const Key('patientField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('+ Tambah Pasien Baru'));
  await tester.pumpAndSettle();
}

/// Opens the filter sheet, picks "Penyakit Dalam", and applies it.
Future<void> _filterBySpecialty(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('searchFilter')));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(InkWell, 'Penyakit Dalam').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tampilkan Hasil Pencarian'));
  await tester.pumpAndSettle();
}

/// The doctor list is no longer on a home tile; reach it by route.
Future<void> _openDoctorList(WidgetTester tester) async {
  final context = tester.element(find.byType(HomeScreen));
  GoRouter.of(context).push(AppRoutes.doctors);
  await tester.pumpAndSettle();
}

/// Picks the seeded doctor in the finder, leaving the panel filled.
Future<void> _pickEdwinInFinder(WidgetTester tester) async {
  await tester.tap(find.text('Dokter'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('finderDoctor')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('dr. Edwin Hadinata, Sp.PD'));
  await tester.pumpAndSettle();
}

/// Opens the first appointment's detail from the schedule tab.
Future<void> _openAppointmentDetail(WidgetTester tester) async {
  await tester.tap(find.text('Jadwal Temu'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lihat Detail').first);
  await tester.pumpAndSettle();
}

/// Scrolls to the cancel action and opens the reason sheet.
Future<void> _openCancelSheet(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('cancelAppointment')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('cancelAppointment')));
  await tester.pumpAndSettle();
}

/// Scrolls the home feed to the article link and follows it.
Future<void> _openHealthNews(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('moreArticles')),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  // The bottom nav overlaps the link's centre, so clear it first.
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('moreArticles')));
  await tester.pumpAndSettle();
}

/// Scrolls the registration form to its submit button and taps it.
Future<void> _tapRegister(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.widgetWithText(AppButton, 'Daftar'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.widgetWithText(AppButton, 'Daftar'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    // A tap that lands on nothing means the control is unreachable in the real
    // app too; fail rather than warn.
    WidgetController.hitTestWarningShouldBeFatal = true;

    // main() does this before runApp; the tests pump the widget directly.
    await initializeDateFormatting('id_ID');
  });

  testWidgets('splash shows the app wordmark', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const ProviderScope(child: CihosApp()));
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('MOBILE APPS'), findsOneWidget);

    // Let the splash timer fire so it does not outlive the widget tree.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('splash advances to onboarding', (tester) async {
    await _startAtOnboarding(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Kesehatan Anda,\ndalam genggaman'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);
  });

  testWidgets('"Mulai" opens the sign-in form', (tester) async {
    await _startAtLogin(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
  });

  testWidgets('onboarding links straight to sign-up', (tester) async {
    await _startAtOnboarding(tester);

    await tester.tap(find.byKey(const Key('onboardingRegister')));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('sign-in rejects a malformed email', (tester) async {
    await _startAtLogin(tester);

    await tester.enterText(find.byType(TextFormField).first, 'bukan-email');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.text('Masuk').last);
    await tester.pumpAndSettle();

    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('sign-in surfaces the rejection from the server', (tester) async {
    await _startAtLogin(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'orang.lain@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'salahsekali');
    await tester.tap(find.text('Masuk').last);
    await tester.pumpAndSettle();

    expect(find.text('Email atau password salah.'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('valid credentials land on home', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Konsultasi Anda'), findsNothing);
  });

  testWidgets('sign-in links through to sign-up', (tester) async {
    await _startAtLogin(tester);

    await tester.tap(find.byKey(const Key('goToRegister')));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Pendaftaran Pasien Baru'), findsOneWidget);
  });

  testWidgets('back returns from sign-up to sign-in', (tester) async {
    await _startAtLogin(tester);
    await tester.tap(find.byKey(const Key('goToRegister')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('registering a new patient lands on home', (tester) async {
    await _startAtLogin(tester);
    await tester.tap(find.byKey(const Key('goToRegister')));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '3201234567890001');
    await tester.enterText(fields.at(1), 'password123');
    await tester.enterText(fields.at(2), 'Budi Santoso');
    await tester.enterText(fields.at(3), 'budi@example.com');
    await tester.enterText(fields.at(4), '081234567890');

    // Date of birth comes from a picker, not a text field.
    await tester.scrollUntilVisible(
      find.byKey(const Key('birthDateField')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('birthDateField')));
    await tester.pumpAndSettle();
    // Confirm the picker by button position rather than label: the label is
    // localised, so matching text would tie the test to the id_ID strings.
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();

    await _tapRegister(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Halo, Budi!'), findsOneWidget);
  });

  testWidgets('registration cannot be submitted without a birth date', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await tester.tap(find.byKey(const Key('goToRegister')));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '3201234567890001');
    await tester.enterText(fields.at(1), 'password123');
    await tester.enterText(fields.at(2), 'Budi Santoso');
    await tester.enterText(fields.at(3), 'budi@example.com');
    await tester.enterText(fields.at(4), '081234567890');

    await _tapRegister(tester);

    expect(find.text('Tanggal lahir wajib diisi'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('home reaches notifications through the bell', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text('Janji Temu Berhasil Dibuat'), findsWidgets);
  });

  testWidgets('marking all read clears the bell badge', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tandai semua telah dibaca'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    // The badge only renders while something is unread.
    expect(find.text('3'), findsNothing);
  });

  testWidgets('the profile tab opens the profile screen', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Sosial Media'), findsOneWidget);
    expect(find.byTooltip('Edit Profil'), findsOneWidget);
  });

  testWidgets('signing out from profile returns to onboarding', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Keluar'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('back returns from sign-in to onboarding', (tester) async {
    await _startAtLogin(tester);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('home opens the queue check', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.text('Monitor Antrean Dokter'));
    await tester.pumpAndSettle();

    expect(find.byType(QueueMonitorScreen), findsOneWidget);
    expect(find.text('Klinik'), findsOneWidget);
    expect(find.text('Farmasi'), findsOneWidget);
  });

  testWidgets('the clinic option opens the live queue', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Monitor Antrean Dokter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Klinik'));
    await tester.pumpAndSettle();

    expect(find.byType(QueueMonitorScreen), findsOneWidget);
    expect(find.text('Penting Untuk Diketahui'), findsOneWidget);
  });

  testWidgets('refreshing the queue updates the timestamp', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Monitor Antrean Dokter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Klinik'));
    await tester.pumpAndSettle();

    expect(find.text('08.54'), findsOneWidget);

    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();

    expect(find.text('08.54'), findsNothing);
  });

  testWidgets('the doctor tile opens the finder', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.text('Dokter'));
    await tester.pumpAndSettle();

    expect(find.byType(DoctorFinderScreen), findsOneWidget);
    expect(find.text('Pilih Klinik'), findsOneWidget);
  });

  testWidgets('the card opens the doctor profile sheet', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _openDoctorList(tester);

    await tester.tap(find.text('Lihat Profil').first);
    await tester.pumpAndSettle();

    expect(find.text('Profil Dokter'), findsOneWidget);
    expect(find.text('Riwayat Pendidikan'), findsOneWidget);
    expect(find.text('Pilih Dokter Ini'), findsOneWidget);
  });

  testWidgets('the profile sheet leads to the doctor schedule', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _openDoctorList(tester);
    await tester.tap(find.text('Lihat Profil').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih Dokter Ini'));
    await tester.pumpAndSettle();

    expect(find.byType(DoctorScheduleScreen), findsOneWidget);
  });

  testWidgets('booking from a card opens the doctor schedule', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _openDoctorList(tester);

    await tester.tap(find.text('Booking Jadwal').first);
    await tester.pumpAndSettle();

    expect(find.byType(DoctorScheduleScreen), findsOneWidget);
  });

  testWidgets('the promo tile opens the promo list', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.text('Promo'));
    await tester.pumpAndSettle();

    expect(find.byType(PromoScreen), findsOneWidget);
    expect(find.text('Promo Spesial'), findsOneWidget);
  });

  testWidgets('promo search narrows the list', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Promo'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'tidak ada promo ini');
    await tester.pumpAndSettle();

    expect(find.text('Promo tidak ditemukan'), findsOneWidget);
  });

  testWidgets('the booking flow can add a new patient', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _reachPatientStep(tester);

    await tester.tap(find.byKey(const Key('patientField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Tambah Pasien Baru'));
    await tester.pumpAndSettle();

    expect(find.byType(PatientTypeScreen), findsOneWidget);
  });

  testWidgets('new-patient registration reaches the review step', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _reachPatientRegistration(tester);

    await tester.tap(find.byKey(const Key('newPatient')));
    await tester.pumpAndSettle();

    expect(find.byType(NewPatientFormScreen), findsOneWidget);
    expect(find.text('Kartu ID'), findsOneWidget);
  });

  testWidgets('the intake form refuses to advance while empty', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _reachPatientRegistration(tester);
    await tester.tap(find.byKey(const Key('newPatient')));
    await tester.pumpAndSettle();

    // The submit button sits far below the fold on a form this long.
    await tester.scrollUntilVisible(
      find.widgetWithText(AppButton, 'Lanjut'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(AppButton, 'Lanjut'));
    await tester.pumpAndSettle();

    // Still on the form, with the missing-data warning shown.
    expect(find.byType(NewPatientFormScreen), findsOneWidget);
    expect(find.text('Lengkapi data yang bertanda *.'), findsOneWidget);
  });

  testWidgets('back from the queue check returns to home', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Monitor Antrean Dokter'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('back from the doctor list returns to home', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _openDoctorList(tester);
    expect(find.byType(DoctorListScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('back from promo returns to home', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Promo'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the video call tile opens the search screen', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.text('Video Call Dokter'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingSearchScreen), findsOneWidget);
    expect(find.text('Buat Video Call'), findsOneWidget);
    expect(find.text('Atau'), findsOneWidget);
  });

  testWidgets('the appointment tile opens its own search screen', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.text('Janji Temu Dokter'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingSearchScreen), findsOneWidget);
    expect(find.text('Buat Janji Temu'), findsOneWidget);
  });

  testWidgets('booking search needs at least one criterion', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Video Call Dokter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Selanjutnya, Pilih Dokter'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingResultsScreen), findsNothing);
    expect(find.textContaining('Isi salah satu'), findsOneWidget);
  });

  testWidgets('searching by doctor name lists matching doctors', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _searchForEdwin(tester);

    expect(find.byType(BookingResultsScreen), findsOneWidget);
    expect(find.text('dr. Edwin Hadinata, Sp.PD'), findsOneWidget);
  });

  testWidgets('a search with no match says so', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Video Call Dokter'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Zulkarnain');
    await tester.tap(find.text('Selanjutnya, Pilih Dokter'));
    await tester.pumpAndSettle();

    expect(find.text('Dokter tidak ditemukan'), findsOneWidget);
  });

  testWidgets('picking a slot from the results opens the schedule', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _searchForEdwin(tester);

    await tester.tap(find.text('12:00 - 12:15').first);
    await tester.pumpAndSettle();

    expect(find.byType(BookingScheduleScreen), findsOneWidget);
    expect(find.text('Pilih Jam'), findsOneWidget);
  });

  testWidgets('the schedule carries the slot through to patient selection', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _searchForEdwin(tester);
    await tester.tap(find.text('12:00 - 12:15').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingPatientScreen), findsOneWidget);
    expect(find.text('Jenis Jaminan'), findsOneWidget);
  });

  testWidgets('booking a doctor without a slot needs a date first', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _searchForEdwin(tester);

    await tester.tap(find.text('Booking Jadwal').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih tanggal terlebih dahulu.'), findsOneWidget);
    expect(find.byType(BookingPatientScreen), findsNothing);
  });

  testWidgets('insurance payment requires choosing a company', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _reachPatientStep(tester);

    await tester.tap(find.text('Asuransi/Perusahaan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih asuransi atau perusahaan.'), findsOneWidget);
    expect(find.byType(BookingSummaryScreen), findsNothing);
  });

  testWidgets('the patient picker sheet changes the chosen patient', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _reachPatientStep(tester);

    await tester.tap(find.byKey(const Key('patientField')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PUTRI (Anak)'));
    await tester.pumpAndSettle();

    expect(find.text('PUTRI (Anak)'), findsOneWidget);
  });

  testWidgets('confirming the patient reaches the summary', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _reachPatientStep(tester);

    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingSummaryScreen), findsOneWidget);
    expect(find.text('dr. Edwin Hadinata, Sp.PD'), findsOneWidget);
    expect(find.text('12:00 - 12:15'), findsOneWidget);
  });

  testWidgets('confirming needs the terms ticked first', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _reachPatientStep(tester);
    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Setujui Syarat & Ketentuan'), findsOneWidget);
    expect(find.text('Janji Temu Berhasil Dibuat!'), findsNothing);
  });

  testWidgets('creating the booking confirms and opens the schedule', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _reachPatientStep(tester);
    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('summaryTerms')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();

    expect(find.text('Janji Temu Berhasil Dibuat!'), findsOneWidget);

    await tester.tap(find.byKey(const Key('successHistory')));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleScreen), findsOneWidget);
  });

  testWidgets('the summary can be edited before confirming', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _reachPatientStep(tester);
    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('summaryEdit')));
    await tester.pumpAndSettle();

    expect(find.text('Ubah Janji Temu?'), findsOneWidget);
    expect(find.text('Ubah Dokter'), findsOneWidget);
    expect(find.text('Ubah Tanggal/Waktu'), findsOneWidget);
  });

  testWidgets('the results tile opens the examination list', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.text('Hasil Pemeriksaan'));
    await tester.pumpAndSettle();

    expect(find.byType(ExamResultsScreen), findsOneWidget);
    expect(find.text('CT Scan Thorax'), findsOneWidget);
    expect(find.text('Blood Glucose, Blood Lipid'), findsOneWidget);
  });

  testWidgets('a category tab narrows the results', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Hasil Pemeriksaan'));
    await tester.pumpAndSettle();

    // The tab strip scrolls horizontally; bring the last tab into reach.
    await tester.scrollUntilVisible(
      find.text('Radiologi').first,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Radiologi').first);
    await tester.pumpAndSettle();

    expect(find.text('CT Scan Thorax'), findsOneWidget);
    expect(find.text('Blood Glucose, Blood Lipid'), findsNothing);
  });

  testWidgets('switching patient shows that patient results', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Hasil Pemeriksaan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('resultPatientSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANDRI (Suami)').last);
    await tester.pumpAndSettle();

    expect(find.text('Rontgen Thorax'), findsOneWidget);
    expect(find.text('CT Scan Thorax'), findsNothing);
  });

  testWidgets('a patient with no results shows the empty state', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Hasil Pemeriksaan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('resultPatientSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OLIVIA (Ibu)').last);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada hasil pemeriksaan'), findsOneWidget);
  });

  testWidgets('opening a result shows its viewer', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Hasil Pemeriksaan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CT Scan Thorax'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultViewerScreen), findsOneWidget);
    expect(find.text('Hasil Radiologi'), findsOneWidget);
  });

  testWidgets('the MCU tile opens the package catalogue', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.text('Medical Check Up'));
    await tester.pumpAndSettle();

    expect(find.byType(McuPackagesScreen), findsOneWidget);
    expect(find.text('Paket MCU'), findsOneWidget);
    expect(find.text('Paket Khusus'), findsOneWidget);
  });

  testWidgets('the search filter narrows results by specialty', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Janji Temu Dokter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'dr');
    await tester.tap(find.text('Selanjutnya, Pilih Dokter'));
    await tester.pumpAndSettle();

    // Every appointment doctor matches "dr" before filtering.
    expect(find.text('dr. Fidela Olivia Wijono, Sp.M'), findsOneWidget);

    await _filterBySpecialty(tester);

    expect(find.text('dr. Edwin Hadinata, Sp.PD'), findsOneWidget);
    expect(find.text('dr. Fidela Olivia Wijono, Sp.M'), findsNothing);
  });

  testWidgets('clearing the filter restores every result', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Janji Temu Dokter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'dr');
    await tester.tap(find.text('Selanjutnya, Pilih Dokter'));
    await tester.pumpAndSettle();

    await _filterBySpecialty(tester);

    await tester.tap(find.byKey(const Key('searchFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tampilkan Hasil Pencarian'));
    await tester.pumpAndSettle();

    expect(find.text('dr. Fidela Olivia Wijono, Sp.M'), findsOneWidget);
  });

  testWidgets('the specialty row opens the picker sheet', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Janji Temu Dokter'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('specialtyRow')));
    await tester.pumpAndSettle();

    expect(find.text('Cari Spesialisasi'), findsOneWidget);
    expect(find.text('Andrologi'), findsOneWidget);

    // The list is long enough to scroll; the tail is reachable. The search
    // screen behind the sheet is scrollable too, so target the sheet's list.
    await tester.scrollUntilVisible(
      find.text('Urologi'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    expect(find.text('Urologi'), findsOneWidget);
  });

  testWidgets('searching narrows the specialty list', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Janji Temu Dokter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('specialtyRow')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'bedah');
    await tester.pumpAndSettle();

    expect(find.text('Bedah Anak'), findsOneWidget);
    expect(find.text('Andrologi'), findsNothing);
  });

  testWidgets('choosing a specialty fills the search panel', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Janji Temu Dokter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('specialtyRow')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Penyakit Dalam').first);
    await tester.pumpAndSettle();

    expect(find.text('Penyakit Dalam'), findsOneWidget);
  });

  testWidgets('a chosen specialty carries into the results', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Janji Temu Dokter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('specialtyRow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Penyakit Dalam').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Selanjutnya, Pilih Dokter'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingResultsScreen), findsOneWidget);
    expect(find.text('dr. Edwin Hadinata, Sp.PD'), findsOneWidget);
    expect(find.text('dr. Fidela Olivia Wijono, Sp.M'), findsNothing);
  });

  testWidgets('a failed catalogue load offers a retry', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(startSignedIn: true),
          ),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(
              failWith: const ApiException(
                message: 'Tidak dapat terhubung ke server.',
                code: 'network',
              ),
            ),
          ),
        ],
        child: const CihosApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Janji Temu Dokter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('specialtyRow')));
    await tester.pumpAndSettle();

    // The failure is shown in the patient's language, with a way out.
    expect(find.text('Tidak dapat terhubung ke server.'), findsOneWidget);
    expect(find.byKey(const Key('retry')), findsOneWidget);
  });

  testWidgets('the specialty list carries no duplicates', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Janji Temu Dokter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('specialtyRow')));
    await tester.pumpAndSettle();

    // Units come from the hospital catalogue, so each appears exactly once.
    expect(find.text('Penyakit Dalam'), findsOneWidget);
    expect(find.text('Radiologi'), findsOneWidget);
  });

  testWidgets('the schedule tab lists upcoming appointments', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.text('Jadwal Temu'));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleScreen), findsOneWidget);
    expect(find.text('NADILA'), findsOneWidget);
    expect(find.text('PUTRI (Anak)'), findsOneWidget);
  });

  testWidgets('the schedule filter separates self from others', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Jadwal Temu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saya Sendiri'));
    await tester.pumpAndSettle();

    expect(find.text('NADILA'), findsOneWidget);
    expect(find.text('PUTRI (Anak)'), findsNothing);

    await tester.tap(find.text('Orang Lain'));
    await tester.pumpAndSettle();

    expect(find.text('PUTRI (Anak)'), findsOneWidget);
    expect(find.text('NADILA'), findsNothing);
  });

  testWidgets('an appointment card opens its detail', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Jadwal Temu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lihat Detail').first);
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentDetailScreen), findsOneWidget);
    expect(find.text('0002367894'), findsOneWidget);
    expect(find.text('Sesuai Jadwal'), findsOneWidget);
  });

  testWidgets('the QR link shows the booking code', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Jadwal Temu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('QR Janji Temu').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('KiosK'), findsOneWidget);
  });

  testWidgets('cancelling asks for confirmation first', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Jadwal Temu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat Detail').first);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('cancelAppointment')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible stops as soon as the widget enters the viewport;
    // nudge past it so the whole button is tappable.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancelAppointment')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Mengapa Anda Ingin Membatalkan'),
      findsOneWidget,
    );
    expect(find.text('Kondisi sudah membaik'), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();

    // Backing out leaves the appointment intact.
    expect(find.byType(AppointmentDetailScreen), findsOneWidget);
  });

  testWidgets('cancelling needs a reason before it submits', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _openAppointmentDetail(tester);
    await _openCancelSheet(tester);

    // The confirm button is inert until a reason is picked.
    await tester.tap(find.byKey(const Key('confirmCancel')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Mengapa Anda Ingin Membatalkan'),
      findsOneWidget,
    );

    await tester.tap(find.text('Kondisi sudah membaik'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmCancel')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Pembatalan Janji Temu sedang diproses'),
      findsOneWidget,
    );
  });

  testWidgets('the detail shows an itemised cost estimate', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _openAppointmentDetail(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('costEstimate')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('costEstimate')));
    await tester.pumpAndSettle();

    expect(find.text('Perkiraan Biaya'), findsOneWidget);
    expect(find.text('Biaya Administrasi'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Rp 569.000'), findsOneWidget);
  });

  testWidgets('home links through to the health news feed', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await _openHealthNews(tester);

    expect(find.byType(HealthNewsScreen), findsOneWidget);
    expect(find.text('Berita Terbaru'), findsOneWidget);
    expect(find.text('Bacaan Anda'), findsOneWidget);
  });

  testWidgets('the news shelves carry their articles', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _openHealthNews(tester);

    expect(
      find.textContaining('Ketahui 7 Penyebab Badan Meriang'),
      findsOneWidget,
    );
    expect(find.textContaining('7 Manfaat Minum Teh Tawar'), findsOneWidget);
  });

  testWidgets('the wellness tab lists its tools', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.text('Sehat-mu'));
    await tester.pumpAndSettle();

    expect(find.byType(WellnessScreen), findsOneWidget);
    expect(find.text('Asuransi'), findsOneWidget);
    expect(find.text('Kalender Haid'), findsOneWidget);
  });

  testWidgets('the history tab lists finished visits', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('dr. Edwin Hadinata, Sp.PD'), findsWidgets);
    expect(find.text('Selesai'), findsWidgets);
    expect(find.text('Dibatalkan'), findsOneWidget);
  });

  testWidgets('rebooking a past visit reopens the booking search', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('rebook_h1')));
    await tester.pumpAndSettle();

    expect(find.byType(DoctorListScreen), findsOneWidget);
    expect(find.text('Buat Janji Temu'), findsWidgets);
  });

  testWidgets('a past video call rebooks into the video call flow', (
    tester,
  ) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('rebook_h3')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('rebook_h3')));
    await tester.pumpAndSettle();

    expect(find.byType(DoctorListScreen), findsOneWidget);
    expect(find.text('Buat Video Call'), findsWidgets);
  });

  testWidgets('the finder needs a doctor before continuing', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Dokter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih dokter terlebih dahulu.'), findsOneWidget);
  });

  testWidgets('the clinic row opens its picker', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await tester.tap(find.text('Dokter'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('finderClinic')));
    await tester.pumpAndSettle();

    expect(find.text('Cari Klinik'), findsOneWidget);
    expect(find.text('Andrologi'), findsOneWidget);
  });

  testWidgets('choosing a doctor fills the finder', (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _pickEdwinInFinder(tester);

    expect(find.text('dr. Edwin Hadinata, Sp.PD'), findsOneWidget);
  });

  testWidgets('continuing with doctor opens consultation methods',
      (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);
    await _pickEdwinInFinder(tester);

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Appointment?'), findsOneWidget);
    expect(find.text('Janji Temu dengan Dokter'), findsOneWidget);
    expect(find.text('Video Call dengan Dokter'), findsOneWidget);
  });

  testWidgets('tapping an article opens the article detail screen',
      (tester) async {
    await _startAtLogin(tester);
    await _signIn(tester);

    await tester.scrollUntilVisible(
      find.text('Indonesia Running Series 2025 Berlangsung di 4 Kota!'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.text('Indonesia Running Series 2025 Berlangsung di 4 Kota!'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HealthArticleDetailScreen), findsOneWidget);
    expect(find.text('Event & Olahraga'), findsOneWidget);
    expect(find.text('dr. Antonius Wijaya, Sp.KO'), findsOneWidget);
  });
}
