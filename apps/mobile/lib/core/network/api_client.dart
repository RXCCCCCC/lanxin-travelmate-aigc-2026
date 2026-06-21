import 'package:dio/dio.dart';
import '../../features/auth/data/auth_session_service.dart';

const String defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

Dio buildApiClient({
  String baseUrl = defaultApiBaseUrl,
  AuthSessionService? authSession,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 5),
      headers: {'content-type': 'application/json'},
    ),
  );
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

bool _isAuthRequest(RequestOptions options) {
  return options.path.startsWith('/api/auth/');
}
