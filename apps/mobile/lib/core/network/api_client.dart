import 'package:dio/dio.dart';

const String defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

Dio buildApiClient({String baseUrl = defaultApiBaseUrl}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 8),
    sendTimeout: const Duration(seconds: 5),
    headers: {'content-type': 'application/json'},
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) => handler.next(options),
    onError: (error, handler) => handler.next(error),
  ));
  return dio;
}
