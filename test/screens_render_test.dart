import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planles_custom/app/app.dart';
import 'package:planles_custom/app/router.dart';
import 'package:planles_custom/core/network/api_client.dart';
import 'package:planles_custom/core/providers.dart';
import 'package:planles_custom/core/storage/token_storage.dart';
import 'package:planles_custom/features/auth/models/user.dart';
import 'package:planles_custom/features/auth/providers/auth_provider.dart';
import 'package:planles_custom/features/notifications/models/app_notification.dart';
import 'package:planles_custom/features/notifications/providers/notifications_providers.dart';
import 'package:planles_custom/features/orders/providers/orders_providers.dart';
import 'package:planles_custom/features/planning/models/planning.dart';
import 'package:planles_custom/features/planning/providers/planning_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('pump home, planning, and profile screens for overflows', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final storage = await TokenStorage.create();
    final apiClient = ApiClient(tokenStorage: storage);

    final mockUser = User(
      id: 1,
      firstName: 'Jan',
      lastName: 'Jansen',
      email: 'jan@example.com',
      balance: 150.0,
      profile: 'STUDENT',
      phone: '0612345678',
    );

    final now = DateTime.now();
    final mockPlanning = Planning(
      id: 101,
      status: 'confirmed',
      startDate: now.add(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1, hours: 1)),
      instructor: User(
        id: 2,
        firstName: 'Peter',
        lastName: 'de Vries (Instructeur)',
        email: 'peter@example.com',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        apiClientProvider.overrideWithValue(apiClient),
        authControllerProvider.overrideWith(
          () => _FakeAuthController(mockUser),
        ),
        planningListProvider.overrideWith(
          (ref) async => PlanningPage(total: 1, items: [mockPlanning]),
        ),
        ordersListProvider.overrideWith(
          (ref) async => const OrdersPage(total: 0, items: []),
        ),
        unreadCountProvider.overrideWith((ref) async => 2),
        notificationsProvider.overrideWith(() => _FakeNotificationsController()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: PlanlesApp(router: container.read(routerProvider)),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Home screen
    expect(find.text('Hallo, Jan'), findsOneWidget);

    // Navigate to Planning
    final router = container.read(routerProvider);
    router.go('/planning');
    await tester.pumpAndSettle();

    // Navigate to Notifications
    router.go('/notifications');
    await tester.pumpAndSettle();

    // Navigate to Profile
    router.go('/profile');
    await tester.pumpAndSettle();
  });
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);
  final User _user;

  @override
  AuthState build() => Authenticated(_user);
}

class _FakeNotificationsController extends NotificationsController {
  @override
  NotificationsState build() => NotificationsState(
    items: [
      AppNotification(
        id: 1,
        title: 'Les bevestigd door instructeur',
        body: 'Je rijles voor morgen om 14:00 is bevestigd.',
        createdAt: DateTime.now(),
      ),
    ],
  );
}
