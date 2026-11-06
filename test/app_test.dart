import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planles_custom/app/app.dart';
import 'package:planles_custom/app/router.dart';
import 'package:planles_custom/core/network/api_client.dart';
import 'package:planles_custom/core/providers.dart';
import 'package:planles_custom/core/storage/token_storage.dart';
import 'package:planles_custom/features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real app (router, theme, providers) with an empty token store,
/// which is exactly what a first-time user sees. No network is touched.
///
/// The app follows the system locale, so [locale] pins it for assertions
/// (the default UI strings are Dutch).
Future<ProviderContainer> _pumpSignedOutApp(
  WidgetTester tester, {
  Locale locale = const Locale('nl'),
}) async {
  tester.platformDispatcher.localeTestValue = locale;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  SharedPreferences.setMockInitialValues({});

  final storage = await TokenStorage.create();
  final apiClient = ApiClient(tokenStorage: storage);

  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      apiClientProvider.overrideWithValue(apiClient),
    ],
    retry: (retryCount, error) => null,
  );
  addTearDown(container.dispose);

  await container.read(authControllerProvider.notifier).restore();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: PlanlesApp(router: container.read(routerProvider)),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  testWidgets('a signed out user lands on the login screen', (tester) async {
    await _pumpSignedOutApp(tester);

    expect(find.text('Welkom terug'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Inloggen'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('login form rejects an empty submission', (tester) async {
    await _pumpSignedOutApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Inloggen'));
    await tester.pump();

    expect(find.text('Vul je e-mailadres in'), findsOneWidget);
    expect(find.text('Vul je wachtwoord in'), findsOneWidget);
  });

  testWidgets('navigation between the auth screens works', (tester) async {
    await _pumpSignedOutApp(tester);

    await tester.ensureVisible(find.text('Registreren'));
    await tester.tap(find.text('Registreren'));
    await tester.pumpAndSettle();
    expect(find.text('Accounttype'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wachtwoord vergeten?'));
    await tester.pumpAndSettle();
    expect(find.text('Herstel je wachtwoord'), findsOneWidget);
  });

  testWidgets('wide windows centre the app in a max-width column',
      (tester) async {
    // A typical desktop window; the app must not stretch to 1280px.
    tester.view.physicalSize = const Size(1280 * 2, 800 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await _pumpSignedOutApp(tester);

    final loginWidth = tester.getSize(find.byType(Scaffold)).width;
    expect(loginWidth, 760);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the app follows the system locale', (tester) async {
    await _pumpSignedOutApp(tester, locale: const Locale('en'));

    final context = tester.element(find.byType(Scaffold));
    expect(Localizations.localeOf(context), const Locale('en'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unsupported locale falls back to Dutch', (tester) async {
    await _pumpSignedOutApp(tester, locale: const Locale('fr'));

    final context = tester.element(find.byType(Scaffold));
    expect(Localizations.localeOf(context), const Locale('nl'));
    expect(find.text('Welkom terug'), findsOneWidget);
  });
}
