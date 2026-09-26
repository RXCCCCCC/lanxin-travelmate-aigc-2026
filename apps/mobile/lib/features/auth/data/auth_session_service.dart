import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'authMode': authMode,
      'isGuest': isGuest,
      'accessToken': accessToken,
    };
  }
}

typedef DeviceIdProvider = Future<String> Function();

abstract class AuthSessionStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> json);
  Future<void> clear();
}

class FileAuthSessionStore implements AuthSessionStore {
  const FileAuthSessionStore();

  @override
  Future<Map<String, dynamic>?> read() async {
    try {
      final file = await _sessionFile();
      if (!await file.exists()) return null;
      final text = (await file.readAsString()).trim();
      if (text.isEmpty) return null;
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(Map<String, dynamic> json) async {
    try {
      final file = await _sessionFile();
      await file.writeAsString(jsonEncode(json), flush: true);
    } catch (_) {
      // The app can still operate with an in-memory session if disk fails.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _sessionFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore local cleanup failures; the next successful login overwrites it.
    }
  }

  Future<File> _sessionFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}lanxin_auth_session.json');
  }
}

class AuthSessionService {
  AuthSessionService({
    DeviceIdProvider? deviceIdProvider,
    AuthSessionStore? store,
    this.displayName = '蓝心同行游客',
  })  : _deviceIdProvider = deviceIdProvider ?? _defaultDeviceId,
        _store = store ?? const FileAuthSessionStore();

  final DeviceIdProvider _deviceIdProvider;
  final AuthSessionStore _store;
  final String displayName;
  static AuthSession? _sharedSession;
  static Future<AuthSession>? _sharedPending;
  static final ValueNotifier<AuthSession?> _sharedSessionListenable =
      ValueNotifier<AuthSession?>(null);
  ValueNotifier<AuthSession?> get sessionListenable => _sharedSessionListenable;

  Future<AuthSession> ensureGuestSession(Dio dio) async {
    final current = _sharedSession;
    if (current != null && current.accessToken.isNotEmpty) {
      return current;
    }
    final stored = await _readStoredSession();
    if (stored != null && stored.accessToken.isNotEmpty) {
      _sharedSession = stored;
      sessionListenable.value = stored;
      return stored;
    }
    final pending = _sharedPending;
    if (pending != null) return pending;
    final future = _createGuestSession(dio);
    _sharedPending = future;
    return future.whenComplete(() => _sharedPending = null);
  }

  Future<String?> accessToken(Dio dio) async {
    final session = await ensureGuestSession(dio);
    return session.accessToken.isEmpty ? null : session.accessToken;
  }

  Future<AuthSession?> currentSession() async {
    final current = _sharedSession;
    if (current != null && current.accessToken.isNotEmpty) {
      return current;
    }
    final stored = await _readStoredSession();
    if (stored != null && stored.accessToken.isNotEmpty) {
      _sharedSession = stored;
      sessionListenable.value = stored;
      return stored;
    }
    return null;
  }

  Future<AuthSession> upgradeGuest(
    Dio dio, {
    required String account,
    required String password,
    required String displayName,
  }) async {
    final guest = await ensureGuestSession(dio);
    final response = await dio.post<Map<String, dynamic>>(
      '/api/auth/upgrade-guest',
      data: {
        'account': account,
        'password': password,
        'displayName': displayName,
      },
      options: Options(headers: {'Authorization': 'Bearer ${guest.accessToken}'}),
    );
    return _setSession(AuthSession.fromJson(response.data ?? <String, dynamic>{}));
  }

  Future<AuthSession> register(
    Dio dio, {
    required String account,
    required String password,
    required String displayName,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'account': account,
        'password': password,
        'displayName': displayName,
      },
    );
    return _setSession(AuthSession.fromJson(response.data ?? <String, dynamic>{}));
  }

  Future<AuthSession> login(
    Dio dio, {
    required String account,
    required String password,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'account': account, 'password': password},
    );
    return _setSession(AuthSession.fromJson(response.data ?? <String, dynamic>{}));
  }

  Future<void> logout() async {
    _sharedSession = null;
    sessionListenable.value = null;
    await _store.clear();
  }

  Future<AuthSession> _createGuestSession(Dio dio) async {
    final deviceId = await _deviceIdProvider();
    final response = await dio.post<Map<String, dynamic>>(
      '/api/auth/guest',
      data: {'deviceId': deviceId, 'displayName': displayName},
    );
    final data = response.data ?? <String, dynamic>{};
    final session = AuthSession.fromJson(data);
    return _setSession(session);
  }

  Future<AuthSession?> _readStoredSession() async {
    final data = await _store.read();
    if (data == null) return null;
    final session = AuthSession.fromJson(data);
    if (session.accessToken.isEmpty) return null;
    return session;
  }

  Future<AuthSession> _setSession(AuthSession session) async {
    _sharedSession = session;
    sessionListenable.value = session;
    await _store.write(session.toJson());
    return session;
  }

  @visibleForTesting
  Future<void> debugSetSession(AuthSession? session) async {
    _sharedSession = session;
    sessionListenable.value = session;
    if (session == null) {
      await _store.clear();
    } else {
      await _store.write(session.toJson());
    }
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
