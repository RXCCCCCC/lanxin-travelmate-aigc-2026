import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/core/network/api_client.dart';
import 'package:lanxin_travelmate/features/auth/data/auth_session_service.dart';

class _AuthAdapter implements HttpClientAdapter {
  RequestOptions? guestRequest;
  RequestOptions? upgradeRequest;
  RequestOptions? registerRequest;
  RequestOptions? loginRequest;
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
    if (options.path == '/api/auth/upgrade-guest') {
      upgradeRequest = options;
      return ResponseBody.fromString(
        '{"userId":"guest-device-test","displayName":"蓝心用户","authMode":"password","isGuest":false,"accessToken":"token-upgraded","migrationSummary":{"memories":1,"trips":1}}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path == '/api/auth/login') {
      loginRequest = options;
      return ResponseBody.fromString(
        '{"userId":"user-password","displayName":"蓝心用户","authMode":"password","isGuest":false,"accessToken":"token-login"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path == '/api/auth/register') {
      registerRequest = options;
      return ResponseBody.fromString(
        '{"userId":"user-registered","displayName":"蓝心用户","authMode":"password","isGuest":false,"accessToken":"token-register"}',
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

class _MemoryAuthStore implements AuthSessionStore {
  Map<String, dynamic>? saved;

  @override
  Future<Map<String, dynamic>?> read() async => saved;

  @override
  Future<void> write(Map<String, dynamic> json) async {
    saved = json;
  }

  @override
  Future<void> clear() async {
    saved = null;
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
      final store = _MemoryAuthStore();
      final session = AuthSessionService(
        deviceIdProvider: () async => 'device-test',
        displayName: '蓝心同行游客',
        store: store,
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
      expect(store.saved?['accessToken'], 'token-abc');
    },
  );

  test('guest session can upgrade to password account and persist token', () async {
    final adapter = _AuthAdapter();
    final store = _MemoryAuthStore();
    final session = AuthSessionService(
      deviceIdProvider: () async => 'device-test',
      store: store,
    );
    final dio = buildApiClient(
      baseUrl: 'https://example.test',
      authSession: session,
    )..httpClientAdapter = adapter;

    final upgraded = await session.upgradeGuest(
      dio,
      account: 'lanxin-user',
      password: 'secret123',
      displayName: '蓝心用户',
    );
    await dio.get('/api/users/me');

    expect(upgraded.isGuest, isFalse);
    expect(upgraded.authMode, 'password');
    expect(adapter.upgradeRequest?.headers['Authorization'], 'Bearer token-abc');
    expect(adapter.upgradeRequest?.data, {
      'account': 'lanxin-user',
      'password': 'secret123',
      'displayName': '蓝心用户',
    });
    expect(adapter.authedRequest?.headers['Authorization'], 'Bearer token-upgraded');
    expect(store.saved?['accessToken'], 'token-upgraded');
  });

  test('password register stores returned session for later api requests', () async {
    final adapter = _AuthAdapter();
    final store = _MemoryAuthStore();
    final session = AuthSessionService(store: store);
    final dio = buildApiClient(
      baseUrl: 'https://example.test',
      authSession: session,
    )..httpClientAdapter = adapter;

    final registered = await session.register(
      dio,
      account: 'lanxin-user',
      password: 'secret123',
      displayName: '蓝心用户',
    );
    await dio.get('/api/users/me');

    expect(registered.userId, 'user-registered');
    expect(registered.isGuest, isFalse);
    expect(adapter.registerRequest?.data, {
      'account': 'lanxin-user',
      'password': 'secret123',
      'displayName': '蓝心用户',
    });
    expect(adapter.authedRequest?.headers['Authorization'], 'Bearer token-register');
    expect(store.saved?['accessToken'], 'token-register');
  });

  test('password login stores returned session for later api requests', () async {
    final adapter = _AuthAdapter();
    final store = _MemoryAuthStore();
    final session = AuthSessionService(store: store);
    final dio = buildApiClient(
      baseUrl: 'https://example.test',
      authSession: session,
    )..httpClientAdapter = adapter;

    final loggedIn = await session.login(
      dio,
      account: 'lanxin-user',
      password: 'secret123',
    );
    await dio.get('/api/users/me');

    expect(loggedIn.userId, 'user-password');
    expect(loggedIn.isGuest, isFalse);
    expect(adapter.loginRequest?.data, {
      'account': 'lanxin-user',
      'password': 'secret123',
    });
    expect(adapter.authedRequest?.headers['Authorization'], 'Bearer token-login');
    expect(store.saved?['accessToken'], 'token-login');
  });
}
