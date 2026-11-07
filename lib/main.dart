import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/deep_links.dart';
import 'core/fcm_service.dart';
import 'core/network/api_client.dart';
import 'core/providers.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Cloud Messaging (best-effort — requires google-services.json /
  // GoogleService-Info.plist, which the developer must add).
  await FcmService.initialize();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Client-side configuration (API_BASE_URL, …) from the bundled .env asset.
  // A missing file must not brick the app — ApiClient falls back to its
  // compiled-in default in that case.
  try {
    await dotenv.load();
  } catch (_) {
    // Ignore: resolvedBaseUrl handles an unloaded dotenv.
  }

  final tokenStorage = await TokenStorage.create();

  // Apply a persisted base-URL override (dev/staging switcher).
  final prefs = await SharedPreferences.getInstance();
  ApiClient.setOverride(prefs.getString('planles.baseUrlOverride'));

  final apiClient = ApiClient(tokenStorage: tokenStorage);

  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(tokenStorage),
      apiClientProvider.overrideWithValue(apiClient),
    ],
    // The backend has no refresh tokens; retrying a rejected request just
    // delays the "please sign in again" message.
    retry: (retryCount, error) => null,
  );

  // A 401 on any authenticated call ends the session.
  apiClient.onUnauthorized = () {
    container.read(authControllerProvider.notifier).forceLogout();
  };

  // Resolve the stored session before the first frame so the router never
  // flashes the login screen for an already signed-in user.
  await container.read(authControllerProvider.notifier).restore();

  final router = container.read(routerProvider);

  // Handle payment redirects coming back into the app (mobile / desktop).
  AppLinks? appLinks;
  if (!kIsWeb) {
    appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      handleDeepLink(uri, router);
    });
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: PlanlesApp(router: router),
    ),
  );

  if (appLinks != null) {
    // Defer the initial-link handling until after the first frame so the
    // router is fully mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await appLinks!.getInitialLink();
      if (initial != null) handleDeepLink(initial, router);
    });
  }

  // Show foreground FCM messages as local notifications.
  FirebaseMessaging.onMessage.listen((message) {
    FcmService.showForeground(message);
  });
}
