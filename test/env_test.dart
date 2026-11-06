import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planles_custom/core/network/api_client.dart';

/// Verifies the dotenv wiring without depending on a particular value: the
/// bundled `.env` is gitignored (see `.gitignore`), so it may be absent in
/// CI — in that case [ApiClient] falls back to [ApiClient.defaultBaseUrl].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default base URL is the production endpoint', () {
    expect(ApiClient.defaultBaseUrl, 'https://api.planles.nl/api');
  });

  test('without a loaded .env, resolvedBaseUrl falls back to the default', () {
    // dotenv is not initialised in this test process.
    expect(dotenv.isInitialized, isFalse);
    expect(ApiClient.resolvedBaseUrl, ApiClient.defaultBaseUrl);
  });

  test('a loaded .env overrides the base URL consistently', () async {
    try {
      await dotenv.load();
    } catch (_) {
      // No .env shipped (it is gitignored) — nothing more to check.
      return;
    }
    expect(
      ApiClient.resolvedBaseUrl,
      dotenv.maybeGet('API_BASE_URL', fallback: ApiClient.defaultBaseUrl),
    );
  });
}
