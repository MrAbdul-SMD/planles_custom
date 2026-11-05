import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT returned by `POST /api/auth/login` and `POST /api/auth/register`.
///
/// The backend has no refresh tokens, so the token is simply discarded on 401
/// and the user is asked to sign in again.
class TokenStorage {
  TokenStorage(this._prefs);

  static const _key = 'planles.jwt';

  final SharedPreferences _prefs;

  static Future<TokenStorage> create() async =>
      TokenStorage(await SharedPreferences.getInstance());

  String? read() => _prefs.getString(_key);

  bool get hasToken => read() != null;

  Future<void> write(String token) => _prefs.setString(_key, token);

  Future<void> clear() => _prefs.remove(_key);
}
