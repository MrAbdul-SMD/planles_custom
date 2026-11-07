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
class FcmService {
  FcmService(this._api);

  final ApiClient _api;
  String? _currentToken;
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
      return false;
    }
  }

  /// Requests permission and returns the (possibly null) token.
  Future<String?> getToken() async {
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
      return null;
    }
  }

  Future<void> register(String token) async {
    _currentToken = token;
    try {
      await _api.post('/auth/fcm/register', body: {'token': token});
    } catch (e) {
      debugPrint('FCM: register failed: $e');
    }
  }

  Future<void> unregister(String token) async {
    _currentToken = null;
    try {
      await _api.post('/auth/fcm/unregister', body: {'token': token});
    } catch (e) {
      debugPrint('FCM: unregister failed: $e');
    }
  }

  /// Listens for token refreshes and re-registers the new token.
  void listenForRefresh(void Function(String token) onRefresh) {
    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen(onRefresh);
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
