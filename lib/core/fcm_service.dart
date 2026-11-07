import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'network/api_client.dart';

/// Firebase Cloud Messaging integration.
///
/// Registers the device token with the backend on sign-in and unregisters on
/// sign-out. All operations are best-effort: a missing Firebase configuration
/// (no `google-services.json` / `GoogleService-Info.plist`) or a network
/// failure must never block authentication.
class FcmService {
  FcmService(this._api);

  final ApiClient _api;
  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Initialises Firebase. Returns `true` when FCM is available.
  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (e) {
      debugPrint('FCM: Firebase.initializeApp failed: $e');
      return false;
    }
  }

  /// Requests notification permission and returns the (possibly null) token.
  Future<String?> getToken() async {
    // Web push requires a service worker + VAPID key; skip on web for now.
    if (kIsWeb) {
      debugPrint('FCM: web push skipped.');
      return null;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // Use the classic (deprecated but working) getToken API. On iOS this
      // waits for the APNS token internally.
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
}
