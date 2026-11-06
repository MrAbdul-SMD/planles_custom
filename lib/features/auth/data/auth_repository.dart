import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/user.dart';

/// Endpoints under `/api/auth`.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// Returns the JWT.
  Future<String> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final data = await _api.post(
      '/auth/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
      },
    );
    final token = data is Map ? data['token']?.toString() : null;
    if (token == null || token.isEmpty) {
      throw const ApiException('Inloggen is mislukt. Probeer het opnieuw.');
    }
    return token;
  }

  /// Two-step OTP registration.
  ///
  /// * `otp == null`  → asks the API to mail a code, returns `token: null`
  /// * `otp != null`  → creates the account, returns the JWT
  ///
  /// The payload is sent as a multipart form field literally named `data`
  /// (a JSON string), with an optional `carImage` file next to it.
  ///
  /// Note the API answers `202` for both "OTP sent" and "all fields are
  /// required", so the message is surfaced instead of being swallowed.
  Future<({String? token, String message})> register({
    required Map<String, dynamic> payload,
    File? carImage,
  }) async {
    final form = FormData()..fields.add(MapEntry('data', jsonEncode(payload)));

    if (carImage != null) {
      form.files.add(
        MapEntry(
          'carImage',
          await MultipartFile.fromFile(
            carImage.path,
            filename: carImage.uri.pathSegments.last,
          ),
        ),
      );
    }

    final data = await _api.post('/auth/register', body: form);
    final message = data is Map
        ? data['message']?.toString() ?? 'Registratie verwerkt'
        : 'Registratie verwerkt';
    final token = data is Map ? data['token']?.toString() : null;
    return (token: (token?.isEmpty ?? true) ? null : token, message: message);
  }

  Future<User> me() async {
    final data = await _api.get('/auth/me');
    final user = data is Map ? data['user'] : null;
    if (user is! Map) throw const ApiException('Gebruiker niet gevonden.');
    return User.fromJson(Map<String, dynamic>.from(user));
  }

  Future<void> forgetPassword(String email) => _api.post(
    '/auth/forget-password',
    body: {'email': email.trim().toLowerCase()},
  );

  /// Verifies the OTP; when [password] is given it also resets it.
  /// Returns the refreshed user when the API provides one.
  Future<User?> resetPassword({
    required String email,
    required String otp,
    String? password,
  }) async {
    final data = await _api.post(
      '/auth/reset-password',
      body: {
        'email': email.trim().toLowerCase(),
        'otp': otp,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );
    if (data is Map && data['user'] is Map) {
      return User.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    }
    return null;
  }
}
