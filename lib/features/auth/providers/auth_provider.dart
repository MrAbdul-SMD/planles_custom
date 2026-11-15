import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  /// Monotonic session generation. Incremented on every authenticated session
  /// transition and on sign-out so in-flight FCM operations for a stale session
  /// become no-ops.
  int _sessionGeneration = 0;
  int? _activeSessionGeneration;

  @override
  AuthState build() => const AuthUnknown();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  bool get isAuthenticated => state is Authenticated;

  User? get user => switch (state) {
        Authenticated(:final user) => user,
        _ => null,
      };

  bool _isSessionActive(int generation) =>
      ref.mounted &&
      _activeSessionGeneration == generation &&
      state is Authenticated;

  /// Reads the stored token and, when present, resolves the current user.
  /// Called once from `main()` before the first frame.
  Future<void> restore() async {
    final storage = ref.read(tokenStorageProvider);
    try {
      if (storage.read() == null) {
        _setUnauthenticated();
        return;
      }
      try {
        final user = await _repo.me();
        _setAuthenticated(user);
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          await storage.clear();
        }
        _setUnauthenticated();
      } catch (_) {
        // Transient failure (e.g. offline): keep the stored token so the user
        // can retry, but do not enter an authenticated state without a user.
        _setUnauthenticated();
      }
    } catch (_) {
      _setUnauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final storage = ref.read(tokenStorageProvider);
    // Ensure any previous device-token association is cleared before switching
    // to a different account/session.
    await _deactivateFcm();
    final token = await _repo.login(email: email, password: password);
    await storage.write(token);
    final user = await _repo.me();
    _setAuthenticated(user);
  }

  /// Returns `completed == true` when the account was created and the user
  /// is now signed in; otherwise the API wants an OTP (or reported a problem
  /// through [message]).
  Future<({bool completed, String message})> register({
    required Map<String, dynamic> payload,
    XFile? carImage,
  }) async {
    final storage = ref.read(tokenStorageProvider);
    await _deactivateFcm();
    final result = await _repo.register(payload: payload, carImage: carImage);
    if (result.token == null) {
      return (completed: false, message: result.message);
    }
    await storage.write(result.token!);
    final user = await _repo.me();
    _setAuthenticated(user);
    return (completed: true, message: result.message);
  }

  Future<void> signOut() async {
    final storage = ref.read(tokenStorageProvider);
    // Unregister/delete the device token while auth credentials are still
    // available so the backend can authorize the request and the token can't
    // be reused by a different account on this device.
    await _deactivateFcm();
    await storage.clear();
    _setUnauthenticated();
  }

  /// Called by the HTTP layer when an authenticated request gets a 401.
  /// Best-effort: unregister may fail without valid auth, but we still must
  /// end the local session and drop the local FCM token.
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

  void _setAuthenticated(User user) {
    _sessionGeneration++;
    final generation = _sessionGeneration;
    _activeSessionGeneration = generation;
    _set(Authenticated(user));
    _activateFcm(generation);
  }

  void _setUnauthenticated() {
    _sessionGeneration++;
    _activeSessionGeneration = null;
    _set(const AuthUnauthenticated());
  }

  void _activateFcm(int generation) {
    // Fire-and-forget; guarded so a stale session can never register a token.
    () async {
      try {
        final fcm = ref.read(fcmServiceProvider);
        await fcm.activate(isSessionActive: () => _isSessionActive(generation));
      } catch (_) {
        // Best effort.
      }
    }();
  }

  Future<void> _deactivateFcm() async {
    // Invalidate current session immediately so no in-flight activation can win.
    _activeSessionGeneration = null;
    try {
      final fcm = ref.read(fcmServiceProvider);
      await fcm.deactivate();
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
