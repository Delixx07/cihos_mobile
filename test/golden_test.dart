import 'package:cihos_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cihos_mobile/features/auth/data/auth_repository.dart';
import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_catalog_repository.dart';
import 'package:cihos_mobile/features/doctors/data/catalog_repository.dart';

/// Screenshot regression tests.
///
/// Flutter's answer to Playwright's visual comparisons: each test renders a
/// screen and diffs it against a checked-in PNG under `test/goldens/`. A
/// layout or spacing change that no assertion covers still fails here, which
/// is what catches unintended visual drift.
///
/// Refresh the baselines after a deliberate design change:
///   flutter test --update-goldens test/golden_test.dart
///
/// Fonts fall back to Ahem in the test binding, so glyphs render as boxes —
/// the goldens verify layout, spacing, and colour, not letterforms.

/// Waits for every `Image` in the tree to finish decoding.
///
/// `pumpAndSettle` returns as soon as animations stop, which is usually before
/// asset decoding completes — so goldens would otherwise capture blank gaps
/// where the logo and illustrations belong.
Future<void> _settleImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  /// Pumps the app at a fixed phone viewport so goldens are reproducible.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3
      // Match a real phone's status bar and gesture bar insets.
      ..padding = const FakeViewPadding(top: 72, bottom: 72)
      ..viewPadding = const FakeViewPadding(top: 72, bottom: 72);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: const CihosApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await _settleImages(tester);
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
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

  testWidgets('onboarding', (tester) async {
    await pumpApp(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding.png'),
    );
  });

  testWidgets('login', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/login.png'),
    );
  });

  testWidgets('home', (tester) async {
    await pumpApp(tester);
    await signIn(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home.png'),
    );
  });

  testWidgets('schedule', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Jadwal Temu'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/schedule.png'),
    );
  });

  testWidgets('history', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/history.png'),
    );
  });

  testWidgets('wellness', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Sehat-mu'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/wellness.png'),
    );
  });

  testWidgets('health news', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('moreArticles')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artikel Selanjutnya'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/health_news.png'),
    );
  });

  testWidgets('profile', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/profile.png'),
    );
  });
}
