import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Builds the URL Mollie redirects to after a payment.
///   * Web: a same-origin path handled by go_router.
///   * Mobile / desktop: a custom scheme (`planles://...`) registered in the
///     platform manifests and handled by `app_links`.
String paymentRedirectUrl({String kind = 'payment'}) {
  if (kIsWeb) {
    final base = Uri.base;
    final path = kind == 'topup' ? '/topup/callback' : '/payment/callback';
    return base.replace(path: path, queryParameters: {}).toString();
  }
  return 'planles://$kind';
}

String get paymentRedirectKind => 'payment';
String get topupRedirectKind => 'topup';

/// Routes an incoming deep link into the app. Returns true if handled.
bool handleDeepLink(Uri uri, GoRouter router) {
  final scheme = uri.scheme;
  final host = uri.host;
  final path = uri.path;
  String? kind;
  if (scheme == 'planles' || scheme == 'intent') {
    if (host == 'payment' || path == '/payment/callback') {
      kind = 'payment';
    } else if (host == 'topup' || path == '/topup/callback') {
      kind = 'topup';
    }
  } else if (path == '/payment/callback') {
    kind = 'payment';
  } else if (path == '/topup/callback') {
    kind = 'topup';
  }
  // Also check query param 'kind'.
  kind ??= uri.queryParameters['kind'];
  if (kind != 'payment' && kind != 'topup') return false;
  router.go('/${kind == 'topup' ? 'topup' : 'payment'}/callback');
  return true;
}