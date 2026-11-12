import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

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
    XFile? carImage,
  }) async {
    final payload = <String, dynamic>{
      ...profile,
      if (email != null && email.isNotEmpty)
        'email': email.trim().toLowerCase(),
      if (password != null && password.isNotEmpty) 'password': password,
      'guardian': ?guardian,
    };

    final form = FormData()..fields.add(MapEntry('data', jsonEncode(payload)));

    if (carImage != null) {
      final bytes = await carImage.readAsBytes();
      if (bytes.isNotEmpty) {
        final rawName = (carImage.name.isNotEmpty ? carImage.name : carImage.path)
            .split(RegExp(r'[\\/]'))
            .last;
        final fallbackName = rawName.isNotEmpty ? rawName : 'car_image.jpg';
        final filename =
            fallbackName.contains('.') ? fallbackName : '$fallbackName.jpg';
        final ext = filename.split('.').last.toLowerCase();
        final mime = carImage.mimeType;
        final subtype = (mime != null && mime.startsWith('image/'))
            ? mime.split('/').last.toLowerCase()
            : switch (ext) {
                'png' => 'png',
                'webp' => 'webp',
                'gif' => 'gif',
                'heic' => 'heic',
                'heif' => 'heif',
                _ => 'jpeg',
              };
        form.files.add(
          MapEntry(
            'carImage',
            MultipartFile.fromBytes(
              bytes,
              filename: filename,
              contentType: DioMediaType('image', subtype),
            ),
          ),
        );
      }
    }

    await _api.patch('/profile', body: form);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _api.patch(
    '/profile/change-password',
    body: {'currentPassword': currentPassword, 'newPassword': newPassword},
  );

  Future<void> deactivate() => _api.patch('/profile/deactivate');
}
