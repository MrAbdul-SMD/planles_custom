/// Normalised error thrown by every repository call.
///
/// The Planles API does not use a single error envelope: some endpoints answer
/// with `{ "message": ... }`, others with `{ "error": ... }`. The [ApiClient]
/// folds both (plus transport failures) into this type so screens only ever
/// deal with a human readable [message].
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors = const []});

  final String message;
  final int? statusCode;

  /// Zod validation issues: `{ path, message, code }`.
  final List<dynamic> errors;

  /// No response at all (offline, DNS, timeout...).
  bool get isNetwork => statusCode == null;

  bool get isUnauthorized => statusCode == 401;

  /// First validation message, if the API sent any.
  String get validationMessage {
    if (errors.isEmpty) return message;
    final first = errors.first;
    if (first is Map && first['message'] is String) {
      return '${first['message']}';
    }
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
