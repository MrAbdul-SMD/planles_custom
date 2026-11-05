import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/network/api_client.dart';
import 'core/providers.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = await TokenStorage.create();
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

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: PlanlesApp(router: container.read(routerProvider)),
    ),
  );
}
