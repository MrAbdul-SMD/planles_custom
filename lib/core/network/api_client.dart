import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// The single HTTP entry point of the app.
///
/// Responsibilities:
///  * point at `https://api.planles.nl/api`
///  * attach `Authorization: Bearer <jwt>` when a token is stored
///  * translate every failure into an [ApiException] with a readable message
///  * notify the app when an *authenticated* request comes back 401 (the API
///    has no refresh token, so the session must end)
class ApiClient {
  ApiClient({required TokenStorage tokenStorage, String? baseUrl}) {
    _tokenStorage = tokenStorage;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? resolvedBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            options.extra[_hadTokenKey] = true;
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final hadToken = error.requestOptions.extra[_hadTokenKey] == true;
          if (hadToken && error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );

    // if (kDebugMode) {
    //   _dio.interceptors.add(
    //     PrettyDioLogger(
    //       requestHeader: true,
    //       requestBody: true,
    //       responseBody: true,
    //       responseHeader: false,
    //       error: true,
    //       compact: true,
    //     ),
    //   );
    // }
  }

  /// Override the base URL at runtime (e.g. switching dev/staging/prod).
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  static String? _overrideBaseUrl;

  /// Persisted override (from SharedPreferences) applied before ApiClient
  /// creation in main().
  static void setOverride(String? url) => _overrideBaseUrl = url;

  static const defaultBaseUrl = 'https://api.planles.nl/api';

  /// `API_BASE_URL` from the bundled `.env` file (or the runtime override),
  /// falling back to [defaultBaseUrl] when missing.
  static String get resolvedBaseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    if (!dotenv.isInitialized) return defaultBaseUrl;
    return dotenv.maybeGet('API_BASE_URL') ?? defaultBaseUrl;
  }

  static const _hadTokenKey = 'planles.hadToken';

  late final TokenStorage _tokenStorage;
  late final Dio _dio;

  /// Invoked when a request that carried a token is rejected with 401.
  void Function()? onUnauthorized;

  Dio get dio => _dio;

  // ---------------------------------------------------------------- helpers

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) =>
      _send(() => _dio.post<dynamic>(path, data: body, queryParameters: query));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<dynamic>(path, data: body));

  /// `GET` that returns raw bytes (invoice PDFs).
  Future<List<int>> getBytes(String path) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() run) async {
    try {
      final response = await run();
      return response.data;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  ApiException _map(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'De verbinding met de server duurde te lang. Probeer het opnieuw.',
          code: AppErrorCode.timeout,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          'Geen verbinding met de server. Controleer je internetverbinding.',
          code: AppErrorCode.offline,
        );
      case DioExceptionType.cancel:
        return const ApiException(
          'Aanvraag geannuleerd.',
          code: AppErrorCode.cancelled,
        );
      case DioExceptionType.badResponse:
        return _mapBadResponse(error);
      case DioExceptionType.badCertificate:
        return const ApiException(
          'Onveilige verbinding met de server.',
          code: AppErrorCode.insecure,
        );
      default:
        return const ApiException(
          'Er is iets misgegaan. Probeer het opnieuw.',
          code: AppErrorCode.transport,
        );
    }
  }

  ApiException _mapBadResponse(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    if (status == 429) {
      return const ApiException(
        'Te veel aanvragen. Wacht even en probeer het opnieuw.',
        statusCode: 429,
        code: AppErrorCode.tooManyRequests,
      );
    }

    if (data is Map) {
      final message = (data['message'] ?? data['error'])?.toString();
      final errors = data['errors'];
      if (message != null && message.isNotEmpty) {
        return ApiException(
          message,
          statusCode: status,
          errors: errors is List ? errors : const [],
        );
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return ApiException(data, statusCode: status);
    }

    return ApiException(
      _fallbackMessage(status),
      statusCode: status,
      code: _fallbackCode(status),
    );
  }

  AppErrorCode _fallbackCode(int? status) {
    if (status == null) return AppErrorCode.transport;
    return switch (status) {
      400 => AppErrorCode.invalidData,
      401 => AppErrorCode.sessionExpired,
      403 => AppErrorCode.forbidden,
      404 => AppErrorCode.notFound,
      409 => AppErrorCode.emailTaken,
      >= 500 => AppErrorCode.serverError,
      _ => AppErrorCode.transport,
    };
  }

  String _fallbackMessage(int? status) {
    switch (status) {
      case 400:
        return 'De ingevulde gegevens zijn ongeldig.';
      case 401:
        return 'Je sessie is verlopen. Log opnieuw in.';
      case 403:
        return 'Je hebt geen toegang tot deze actie.';
      case 404:
        return 'Dit item is niet gevonden.';
      case 409:
        return 'Er bestaat al een account met dit e-mailadres.';
      case 500:
        return 'Er is iets misgegaan op de server. Probeer het later opnieuw.';
      default:
        return 'Er is iets misgegaan. Probeer het opnieuw.';
    }
  }
}
