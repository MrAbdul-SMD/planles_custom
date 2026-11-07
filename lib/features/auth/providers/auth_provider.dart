import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../models/user.dart';

/// Repository providers — one line per data source, so features never build
/// their own HTTP clients.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

sealed class AuthState {
  const AuthState();
}

/// App start / token restore in progress.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);
  final User user;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Owns the session: token persistence, `/auth/me` restore, sign in/out.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthUnknown();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  bool get isAuthenticated => state is Authenticated;

  User? get user => switch (state) {
    Authenticated(:final user) => user,
    _ => null,
  };

  /// Reads the stored token and, when present, resolves the current user.
  /// Called once from `main()` before the first frame.
  Future<void> restore() async {
    final storage = ref.read(tokenStorageProvider);
    if (storage.read() == null) {
      _set(const AuthUnauthenticated());
      return;
    }
    try {
      final user = await _repo.me();
      _set(Authenticated(user));
      _registerFcm();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await storage.clear();
        _set(const AuthUnauthenticated());
      } else {
        // Offline / server trouble: let the user reach the login screen and
        // surface the error there instead of blocking the whole app.
        _set(const AuthUnauthenticated());
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    final storage = ref.read(tokenStorageProvider);
    final token = await _repo.login(email: email, password: password);
    await storage.write(token);
    final user = await _repo.me();
    _set(Authenticated(user));
    // Best-effort FCM registration.
    _registerFcm();
  }

  /// Returns `completed == true` when the account was created and the user
  /// is now signed in; otherwise the API wants an OTP (or reported a problem
  /// through [message]).
  Future<({bool completed, String message})> register({
    required Map<String, dynamic> payload,
    File? carImage,
  }) async {
    final storage = ref.read(tokenStorageProvider);
    final result = await _repo.register(payload: payload, carImage: carImage);
    if (result.token == null) {
      return (completed: false, message: result.message);
    }
    await storage.write(result.token!);
    final user = await _repo.me();
    _set(Authenticated(user));
    _registerFcm();
    return (completed: true, message: result.message);
  }

  Future<void> signOut() async {
    final storage = ref.read(tokenStorageProvider);
    final fcm = ref.read(fcmServiceProvider);
    final token = fcm.currentToken;
    if (token != null) await fcm.unregister(token);
    await storage.clear();
    _set(const AuthUnauthenticated());
  }

  /// Called by the HTTP layer when an authenticated request gets a 401.
  Future<void> forceLogout() => signOut();

  /// Refresh the cached user (after a profile edit or a balance top-up).
  Future<void> refreshUser() async {
    if (!isAuthenticated) return;
    try {
      final user = await _repo.me();
      _set(Authenticated(user));
    } on ApiException {
      // Keep the stale copy — a failed refresh must not sign the user out.
    }
  }

  void setUser(User user) => _set(Authenticated(user));

  Future<void> _registerFcm() async {
    try {
      final fcm = ref.read(fcmServiceProvider);
      final token = await fcm.getToken();
      if (token != null) {
        await fcm.register(token);
        fcm.listenForRefresh((t) => fcm.register(t));
      }
    } catch (_) {
      // Best effort.
    }
  }

  void _set(AuthState next) {
    if (ref.mounted) state = next;
  }
}

/// Convenience view of the signed in user.
final currentUserProvider = Provider<User?>(
  (ref) => switch (ref.watch(authControllerProvider)) {
    Authenticated(:final user) => user,
    _ => null,
  },
);

/// `true` while the app still decides between login and the shell.
final authLoadingProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider) is AuthUnknown,
);
