import 'package:flutter/widgets.dart';
import 'package:planles_custom/core/network/api_exception.dart';
import 'package:planles_custom/l10n/app_localizations.dart';

export 'package:planles_custom/l10n/app_localizations.dart';

/// Convenience access to the localizations of the current locale.
///
/// ```dart
/// final l10n = context.l10n;
/// Text(l10n.loginTitle);
/// ```
extension L10nContext on BuildContext {
  /// Never null: the app registers [AppLocalizations.delegate] in
  /// `MaterialApp.router`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Turns any thrown value into a message that is safe to show to the user.
///
/// * [ApiException]s created by the client are mapped by their
///   [AppErrorCode] to a translated string;
/// * API-provided messages are passed through (the backend produces them);
/// * anything else falls back to a generic "something went wrong".
String describeError(BuildContext context, Object error) {
  final l10n = context.l10n;

  if (error is! ApiException) {
    return error is String && error.isNotEmpty ? error : l10n.errGeneric;
  }

  final code = error.code;
  if (code == null) return error.validationMessage;

  return switch (code) {
    AppErrorCode.timeout => l10n.errTimeout,
    AppErrorCode.offline => l10n.errOffline,
    AppErrorCode.cancelled => l10n.errCancelled,
    AppErrorCode.insecure => l10n.errInsecure,
    AppErrorCode.transport => l10n.errGeneric,
    AppErrorCode.tooManyRequests => l10n.errTooManyRequests,
    AppErrorCode.invalidData => l10n.errInvalidData,
    AppErrorCode.sessionExpired => l10n.errSessionExpired,
    AppErrorCode.forbidden => l10n.errForbidden,
    AppErrorCode.notFound => l10n.errNotFound,
    AppErrorCode.emailTaken => l10n.errEmailTaken,
    AppErrorCode.serverError => l10n.errServer,
    AppErrorCode.invalidCredentials => l10n.errInvalidCredentials,
    AppErrorCode.userNotFound => l10n.errUserNotFound,
    AppErrorCode.orderNotFound => l10n.errOrderNotFound,
    AppErrorCode.lessonNotFound => l10n.errLessonNotFound,
    AppErrorCode.paymentFailed => l10n.errPaymentFailed,
    AppErrorCode.emptyInvoice => l10n.errEmptyInvoice,
  };
}
