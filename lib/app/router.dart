import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/balance/screens/top_up_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/notifications/screens/notification_settings_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/orders/screens/buy_lessons_screen.dart';
import '../features/orders/screens/invoice_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/orders/screens/payment_return_screen.dart';
import '../features/orders/screens/schedule_lesson_screen.dart';
import '../features/planning/screens/lesson_cards_screen.dart';
import '../features/planning/screens/planning_detail_screen.dart';
import '../features/planning/screens/planning_list_screen.dart';
import '../features/planning/screens/reschedule_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/students/screens/students_screen.dart';
import 'shell.dart';

/// The router is rebuilt only when the *session* changes, not on every
/// auth state tweak: [GoRouter.refreshListenable] is fed a [ValueNotifier]
/// that mirrors `authControllerProvider`.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => auth.value = next);
  ref.onDispose(auth.dispose);

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: auth,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final signedIn = auth.value is Authenticated;
      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';

      if (signedIn) return isAuthRoute ? '/home' : null;
      return isAuthRoute ? null : '/login';
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/planning',
                builder: (_, _) => const PlanningListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (_, _) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Detail routes sit above the shell so they push full-screen.
      GoRoute(
        path: '/planning/:id',
        builder: (_, state) =>
            PlanningDetailScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/planning/:id/reschedule',
        builder: (_, state) =>
            RescheduleScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/planning/:id/lesson-cards',
        builder: (_, state) => LessonCardsScreen(
          planningId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/orders/new', builder: (_, _) => const BuyLessonsScreen()),
      GoRoute(
        path: '/schedule/:orderId/:itemId',
        builder: (_, state) => ScheduleLessonScreen(
          orderId: int.parse(state.pathParameters['orderId']!),
          itemId: int.parse(state.pathParameters['itemId']!),
        ),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) =>
            OrderDetailScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/orders/:id/invoice',
        builder: (_, state) =>
            InvoiceScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/balance/topup', builder: (_, _) => const TopUpScreen()),
      GoRoute(
        path: '/notifications/settings',
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
      GoRoute(path: '/students', builder: (_, _) => const StudentsScreen()),
      GoRoute(
        path: '/payment/callback',
        builder: (_, state) => PaymentReturnScreen(
          kind: state.uri.queryParameters['kind'] ?? 'payment',
        ),
      ),
      GoRoute(
        path: '/topup/callback',
        builder: (_, _) => const PaymentReturnScreen(kind: 'topup'),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
