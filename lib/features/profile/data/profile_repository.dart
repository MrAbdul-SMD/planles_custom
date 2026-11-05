import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

/// Endpoints under `/api/profile`.
class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  /// `PATCH /profile` — multipart, JSON payload under the `data` field.
  Future<void> updateProfile({
    required Map<String, dynamic> profile,
    String? email,
    String? password,
    Map<String, dynamic>? guardian,
    File? carImage,
  }) async {
    final payload = <String, dynamic>{
      ...profile,
      if (email != null && email.isNotEmpty) 'email': email.trim().toLowerCase(),
      if (password != null && password.isNotEmpty) 'password': password,
      'guardian': ?guardian,
    };

    final form = FormData()
      ..fields.add(MapEntry('data', jsonEncode(payload)));

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

    await _api.patch('/profile', body: form);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _api.patch(
        '/profile/change-password',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

  Future<void> deactivate() => _api.patch('/profile/deactivate');
}
