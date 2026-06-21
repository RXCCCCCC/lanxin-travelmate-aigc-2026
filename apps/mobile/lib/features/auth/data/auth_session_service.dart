import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.displayName,
    required this.authMode,
    required this.isGuest,
    required this.accessToken,
  });

  final String userId;
  final String displayName;
  final String authMode;
  final bool isGuest;
  final String accessToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'] as String? ?? 'guest',
      displayName: json['displayName'] as String? ?? '游客',
      authMode: json['authMode'] as String? ?? 'guest',
      isGuest: json['isGuest'] as bool? ?? true,
      accessToken: json['accessToken'] as String? ?? '',
    );
  }
}

typedef DeviceIdProvider = Future<String> Function();

class AuthSessionService {
  AuthSessionService({
    DeviceIdProvider? deviceIdProvider,
    this.displayName = '蓝心同行游客',
  }) : _deviceIdProvider = deviceIdProvider ?? _defaultDeviceId;

  final DeviceIdProvider _deviceIdProvider;
  final String displayName;
  AuthSession? _session;
  Future<AuthSession>? _pending;

  Future<AuthSession> ensureGuestSession(Dio dio) {
    final current = _session;
    if (current != null && current.accessToken.isNotEmpty) {
      return Future.value(current);
    }
    final pending = _pending;
    if (pending != null) return pending;
    final future = _createGuestSession(dio);
    _pending = future;
    return future.whenComplete(() => _pending = null);
  }

  Future<String?> accessToken(Dio dio) async {
    final session = await ensureGuestSession(dio);
    return session.accessToken.isEmpty ? null : session.accessToken;
  }

  Future<AuthSession> _createGuestSession(Dio dio) async {
    final deviceId = await _deviceIdProvider();
    final response = await dio.post<Map<String, dynamic>>(
      '/api/auth/guest',
      data: {'deviceId': deviceId, 'displayName': displayName},
    );
    final data = response.data ?? <String, dynamic>{};
    final session = AuthSession.fromJson(data);
    _session = session;
    return session;
  }

  static Future<String> _defaultDeviceId() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File(
        '${dir.path}${Platform.pathSeparator}lanxin_device_id.txt',
      );
      if (await file.exists()) {
        final value = (await file.readAsString()).trim();
        if (value.isNotEmpty) return value;
      }
      final value = _newDeviceId();
      await file.writeAsString(value, flush: true);
      return value;
    } catch (_) {
      return _newDeviceId();
    }
  }

  static String _newDeviceId() {
    final random = Random.secure();
    final millis = DateTime.now().millisecondsSinceEpoch;
    final suffix = List<int>.generate(
      8,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return 'device-$millis-$suffix';
  }
}
