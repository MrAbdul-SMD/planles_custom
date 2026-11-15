import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'network/api_client.dart';

/// Channel used for FCM notifications on Android 8+.
const _androidChannel = AndroidNotificationChannel(
  'planles_default',
  'Planles notifications',
  description: 'Lesson and payment updates',
  importance: Importance.high,
);

/// Firebase Cloud Messaging integration.
///
/// Token registration is driven by the authenticated session:
/// - [activate] fetches the current device token, registers it with the backend
///   for the signed-in user, and keeps it in sync via token refresh.
/// - [deactivate] unregisters the current token from the backend (best-effort)
///   and deletes the local FCM token so it can't be reused by a different
///   account after logout/account switch.
class FcmService {
  FcmService(this._api);

  final ApiClient _api;

  String? _currentToken;
  String? _registeredToken;
  StreamSubscription<String>? _refreshSub;
  bool _available = true;

  /// Last device token observed (may differ from what is registered remotely).
  String? get currentToken => _currentToken;

  static final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialises Firebase + local notifications. Returns `true` when available.
  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Create the Android notification channel.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_androidChannel);
      }
      // iOS foreground presentation.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      return true;
    } catch (e) {
      debugPrint('FCM: initialize failed: $e');
      _availableStatic = false;
      return false;
    }
  }

  static bool _availableStatic = true;

  /// Requests permission and returns the (possibly null) device token.
  Future<String?> _fetchToken() async {
    if (!_available || !_availableStatic) return null;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kIsWeb) {
        final vapidKey = dotenv.maybeGet('FCM_VAPID_KEY');
        if (vapidKey == null || vapidKey.isEmpty) {
          debugPrint('FCM: web push skipped (no FCM_VAPID_KEY in .env).');
          return null;
        }
        // ignore: deprecated_member_use
        return await messaging.getToken(vapidKey: vapidKey);
      }
      // ignore: deprecated_member_use
      return await messaging.getToken();
    } catch (e) {
      debugPrint('FCM: getToken failed: $e');
      _available = false;
      return null;
    }
  }

  /// Ensures the current device token is registered for the authenticated user.
  ///
  /// Safe to call multiple times (idempotent per token). [isSessionActive]
  /// must return `true` only while the same authenticated session is still
  /// valid; it is checked before/after async work to avoid registering a token
  /// for a logged-out or switched account.
  Future<void> activate({required bool Function() isSessionActive}) async {
    if (!_available || !_availableStatic) return;
    if (!isSessionActive()) return;

    final token = await _fetchToken();
    if (token == null || token.isEmpty) return;
    _currentToken = token;

    if (!isSessionActive()) return;

    await _registerRemote(token, isSessionActive: isSessionActive);
    _ensureRefreshListener(isSessionActive);
  }

  void _ensureRefreshListener(bool Function() isSessionActive) {
    if (_refreshSub != null) return;
    try {
      // ignore: deprecated_member_use
      _refreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty) return;
        final oldToken = _currentToken;
        _currentToken = newToken;
        if (!isSessionActive()) return;
        // Best-effort: drop the previous token registration for this session.
        if (oldToken != null && oldToken != newToken) {
          await _unregisterRemote(oldToken);
        }
        if (!isSessionActive()) return;
        await _registerRemote(newToken, isSessionActive: isSessionActive);
      });
    } catch (e) {
      debugPrint('FCM: token refresh listener failed: $e');
    }
  }

  Future<void> _registerRemote(
    String token, {
    required bool Function() isSessionActive,
  }) async {
    if (!isSessionActive()) return;
    if (_registeredToken == token) return;
    try {
      await _api.post('/auth/fcm/register', body: {'token': token});
      if (isSessionActive()) {
        _registeredToken = token;
      }
    } catch (e) {
      debugPrint('FCM: register failed: $e');
    }
  }

  Future<void> _unregisterRemote(String token) async {
    try {
      await _api.post('/auth/fcm/unregister', body: {'token': token});
    } catch (e) {
      debugPrint('FCM: unregister failed: $e');
    } finally {
      if (_registeredToken == token) _registeredToken = null;
    }
  }

  /// Unregisters the device token for the current session and deletes the local
  /// token so it cannot be associated with a different account later.
  ///
  /// Call this while the user's auth credentials are still available so the
  /// backend can authorize the unregister request. Safe to call when there is
  /// no known token (no-op best-effort).
  Future<void> deactivate() async {
    await _refreshSub?.cancel();
    _refreshSub = null;

    final token = _registeredToken ?? _currentToken ?? await _fetchToken();
    if (token != null && token.isNotEmpty) {
      await _unregisterRemote(token);
    }

    _registeredToken = null;
    _currentToken = null;

    // Delete the local FCM token so a subsequent login (possibly a different
    // account) obtains a fresh token and cannot inherit a stale registration.
    if (_available && _availableStatic) {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (e) {
        debugPrint('FCM: deleteToken failed: $e');
      }
    }
  }

  /// Shows a local notification for a foreground FCM message.
  static Future<void> showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}

/// Top-level background message handler (required by firebase_messaging).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Background messages are displayed by the system automatically when they
  // contain a `notification` payload. Nothing else to do here.
}
