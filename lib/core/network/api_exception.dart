/// Machine readable reason behind an [ApiException].
///
/// Screens never show [ApiException.message] for these — they call
/// `describeError(context, e)`, which maps the code to a translated string
/// (see `lib/l10n/l10n.dart`). The raw message stays around for logs and for
/// `toString()`.
enum AppErrorCode {
  /// Request took too long (connect/send/receive timeout).
  timeout,

  /// No response at all: offline, DNS failure, connection refused.
  offline,

  /// Request was cancelled by the app.
  cancelled,

  /// TLS handshake failed.
  insecure,

  /// Unexpected transport failure.
  transport,

  /// HTTP 429.
  tooManyRequests,

  /// HTTP 400 without a more specific cause.
  invalidData,

  /// HTTP 401.
  sessionExpired,

  /// HTTP 403.
  forbidden,

  /// HTTP 404.
  notFound,

  /// HTTP 409 — the email is already registered.
  emailTaken,

  /// HTTP 5xx.
  serverError,

  /// The API rejected the credentials.
  invalidCredentials,

  /// The requested user does not exist.
  userNotFound,

  /// The requested order does not exist.
  orderNotFound,

  /// The requested lesson does not exist.
  lessonNotFound,

  /// Opening the Mollie checkout failed.
  paymentFailed,

  /// An invoice download came back empty.
  emptyInvoice,
}

/// Normalised error thrown by every repository call.
///
/// The Planles API does not use a single error envelope: some endpoints answer
/// with `{ "message": ... }`, others with `{ "error": ... }`. The [ApiClient]
/// folds both (plus transport failures) into this type so screens only ever
/// deal with a human readable [message].
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.errors = const [],
    this.code,
  });

  final String message;
  final int? statusCode;

  /// Set when the client generated this error itself, which means [message]
  /// can be replaced by a translated equivalent.
  final AppErrorCode? code;

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
