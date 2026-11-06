import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Builds the URL Mollie redirects to after a payment. Must be a URL the app
/// can actually receive on the current platform:
///   * Web: a same-origin path handled by go_router (no query string — the
///     backend appends `?orderId=...` for orders).
///   * Mobile / desktop: a custom scheme (`planles://...`) registered in the
///     platform manifests and handled by `app_links`.
String paymentRedirectUrl({required String kind}) {
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
  final host = uri.host;
  final path = uri.path;
  String? kind;
  if (host == 'payment' || path == '/payment/callback') {
    kind = 'payment';
  } else if (host == 'topup' || path == '/topup/callback') {
    kind = 'topup';
  }
  if (kind == null) return false;
  router.go('/${kind == 'topup' ? 'topup' : 'payment'}/callback');
  return true;
}