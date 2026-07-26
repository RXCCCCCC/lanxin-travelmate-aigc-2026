import 'package:dio/dio.dart';
import '../../features/auth/data/auth_session_service.dart';

const String defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.rxcccccc.icu',
);

const String defaultApiFallbackBaseUrl = String.fromEnvironment(
  'API_FALLBACK_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

const Duration apiConnectTimeout = Duration(seconds: 10);
const Duration apiReceiveTimeout = Duration(seconds: 45);
const Duration apiSendTimeout = Duration(seconds: 10);

Dio buildApiClient({
  String baseUrl = defaultApiBaseUrl,
  String fallbackBaseUrl = defaultApiFallbackBaseUrl,
  AuthSessionService? authSession,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: apiConnectTimeout,
      receiveTimeout: apiReceiveTimeout,
      sendTimeout: apiSendTimeout,
      headers: {'content-type': 'application/json'},
    ),
  );
  dio.interceptors.add(_ApiFallbackInterceptor(dio, fallbackBaseUrl));
  final session = authSession ?? AuthSessionService();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_isAuthRequest(options) &&
            !options.headers.containsKey('Authorization')) {
          final token = await session.accessToken(dio);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) => handler.next(error),
    ),
  );
  return dio;
}

const String _fallbackRetriedKey = 'lanxinApiFallbackRetried';

class _ApiFallbackInterceptor extends Interceptor {
  _ApiFallbackInterceptor(this._dio, this._fallbackBaseUrl);

  final Dio _dio;
  final String _fallbackBaseUrl;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final options = err.requestOptions;
    options.extra[_fallbackRetriedKey] = true;
    options.baseUrl = _fallbackBaseUrl;

    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (fallbackError) {
      handler.next(fallbackError);
    } catch (fallbackError) {
      handler.next(
        DioException(
          requestOptions: options,
          error: fallbackError,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  bool _shouldRetry(DioException err) {
    final fallbackBaseUrl = _fallbackBaseUrl.trim();
    if (fallbackBaseUrl.isEmpty) return false;
    final options = err.requestOptions;
    if (options.extra[_fallbackRetriedKey] == true) return false;
    if (_sameBaseUrl(options.baseUrl, fallbackBaseUrl)) return false;

    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.badCertificate ||
      DioExceptionType.connectionError ||
      DioExceptionType.unknown => true,
      DioExceptionType.badResponse => (err.response?.statusCode ?? 0) >= 500,
      DioExceptionType.cancel => false,
    };
  }

  bool _sameBaseUrl(String left, String right) {
    final leftUri = Uri.tryParse(left);
    final rightUri = Uri.tryParse(right);
    if (leftUri == null || rightUri == null) return left == right;
    return leftUri.scheme == rightUri.scheme &&
        leftUri.host == rightUri.host &&
        leftUri.port == rightUri.port;
  }
}

bool _isAuthRequest(RequestOptions options) {
  return options.path.startsWith('/api/auth/');
}
