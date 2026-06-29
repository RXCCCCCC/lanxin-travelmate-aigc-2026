import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/core/network/api_client.dart';
import 'package:lanxin_travelmate/features/auth/data/auth_session_service.dart';

class _AuthAdapter implements HttpClientAdapter {
  RequestOptions? guestRequest;
  RequestOptions? authedRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/auth/guest') {
      guestRequest = options;
      return ResponseBody.fromString(
        '{"userId":"guest-device-test","displayName":"蓝心同行游客","authMode":"guest","isGuest":true,"accessToken":"token-abc"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    authedRequest = options;
    return ResponseBody.fromString('{}', 200);
  }
}

void main() {
  test('api client keeps enough receive timeout for real agent calls', () {
    final dio = buildApiClient(
      baseUrl: 'https://example.test',
      authSession: AuthSessionService(
        deviceIdProvider: () async => 'device-test',
      ),
    );

    expect(dio.options.connectTimeout, apiConnectTimeout);
    expect(dio.options.receiveTimeout, apiReceiveTimeout);
    expect(dio.options.sendTimeout, apiSendTimeout);
    expect(
      dio.options.receiveTimeout,
      greaterThanOrEqualTo(const Duration(seconds: 45)),
    );
  });

  test(
    'guest session registers device and adds bearer token to later requests',
    () async {
      final adapter = _AuthAdapter();
      final session = AuthSessionService(
        deviceIdProvider: () async => 'device-test',
        displayName: '蓝心同行游客',
      );
      final dio = buildApiClient(
        baseUrl: 'https://example.test',
        authSession: session,
      )..httpClientAdapter = adapter;

      final auth = await session.ensureGuestSession(dio);
      await dio.get('/api/users/me');

      expect(auth.userId, 'guest-device-test');
      expect(adapter.guestRequest?.data, {
        'deviceId': 'device-test',
        'displayName': '蓝心同行游客',
      });
      expect(
        adapter.authedRequest?.headers['Authorization'],
        'Bearer token-abc',
      );
    },
  );
}
