import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/api_client.dart';
import 'storage/token_storage.dart';

/// Infrastructure providers.
///
/// [tokenStorageProvider] is overridden in `main()` with a real instance;
/// [apiClientProvider] is derived from it and overridden only when a test
/// wants to swap the HTTP layer.
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => throw UnimplementedError('tokenStorageProvider must be overridden'),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStorage: ref.watch(tokenStorageProvider)),
);
