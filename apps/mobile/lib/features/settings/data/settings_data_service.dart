import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_session_service.dart';

class PrivacyPermissionInfo {
  const PrivacyPermissionInfo({
    required this.permission,
    required this.label,
    required this.purpose,
    required this.fallback,
  });

  final String permission;
  final String label;
  final String purpose;
  final String fallback;

  factory PrivacyPermissionInfo.fromJson(Map<String, dynamic> json) {
    return PrivacyPermissionInfo(
      permission: json['permission'] as String? ?? '',
      label: json['label'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      fallback: json['fallback'] as String? ?? '',
    );
  }
}

class PrivacySummaryPayload {
  const PrivacySummaryPayload({
    required this.principles,
    required this.permissions,
    required this.userControls,
  });

  final List<String> principles;
  final List<PrivacyPermissionInfo> permissions;
  final Map<String, dynamic> userControls;

  factory PrivacySummaryPayload.fromJson(Map<String, dynamic> json) {
    return PrivacySummaryPayload(
      principles: _stringList(json['principles']),
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PrivacyPermissionInfo.fromJson)
          .toList(),
      userControls: Map<String, dynamic>.from(
        json['userControls'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  factory PrivacySummaryPayload.fallback() {
    return const PrivacySummaryPayload(
      principles: ['本地网络不可用时，仍保留端侧隐私控制入口。'],
      permissions: [],
      userControls: {},
    );
  }
}

class DataActionResult {
  const DataActionResult({
    required this.status,
    this.deleted = 0,
    this.itemCount = 0,
    this.revoked = const {},
  });

  final String status;
  final int deleted;
  final int itemCount;
  final Map<String, dynamic> revoked;
}

class SyncMemoryDraft {
  const SyncMemoryDraft({
    required this.id,
    required this.title,
    required this.content,
    required this.scope,
    this.category = 'travel_preference',
    this.status = 'confirmed',
    this.confidence = 1.0,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final String scope;
  final String category;
  final String status;
  final double confidence;
  final String? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'scope': scope,
      'category': category,
      'status': status,
      'confidence': confidence,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

class SyncConflictInfo {
  const SyncConflictInfo({
    required this.entityType,
    required this.entityId,
    required this.resolution,
    required this.server,
    required this.client,
    this.clientUpdatedAt,
    this.serverUpdatedAt,
  });

  final String entityType;
  final String entityId;
  final String resolution;
  final Map<String, dynamic> server;
  final Map<String, dynamic> client;
  final String? clientUpdatedAt;
  final String? serverUpdatedAt;

  factory SyncConflictInfo.fromJson(Map<String, dynamic> json) {
    return SyncConflictInfo(
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      resolution: json['resolution'] as String? ?? '',
      server: Map<String, dynamic>.from(
        json['server'] as Map<String, dynamic>? ?? const {},
      ),
      client: Map<String, dynamic>.from(
        json['client'] as Map<String, dynamic>? ?? const {},
      ),
      clientUpdatedAt: json['clientUpdatedAt'] as String?,
      serverUpdatedAt: json['serverUpdatedAt'] as String?,
    );
  }
}

class SyncPushResult {
  const SyncPushResult({
    required this.status,
    this.pushed = const {},
    this.conflicts = const [],
  });

  final String status;
  final Map<String, dynamic> pushed;
  final List<SyncConflictInfo> conflicts;

  factory SyncPushResult.fromJson(Map<String, dynamic> json) {
    return SyncPushResult(
      status: json['status'] as String? ?? 'ok',
      pushed: Map<String, dynamic>.from(
        json['pushed'] as Map<String, dynamic>? ?? const {},
      ),
      conflicts: (json['conflicts'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SyncConflictInfo.fromJson)
          .toList(),
    );
  }

  factory SyncPushResult.offline() => const SyncPushResult(status: 'offline');
}

class AccountActionResult {
  const AccountActionResult({
    required this.status,
    this.session,
    this.message,
  });

  final String status;
  final AuthSession? session;
  final String? message;

  bool get ok => status == 'ok' && session != null;

  factory AccountActionResult.offline() {
    return const AccountActionResult(
      status: 'offline',
      message: '账号服务暂时不可用，请确认后端连接后重试',
    );
  }

  factory AccountActionResult.failed(String message) {
    return AccountActionResult(status: 'failed', message: message);
  }
}

class SettingsDataService {
  SettingsDataService({Dio? dio, AuthSessionService? authSession})
      : _authSession = authSession ?? AuthSessionService() {
    _dio = dio ?? buildApiClient(authSession: _authSession);
  }

  late final Dio _dio;
  final AuthSessionService _authSession;

  Future<AuthSession?> readCurrentSession() => _authSession.currentSession();

  Future<PrivacySummaryPayload> fetchPrivacySummary() async {
    try {
      final response = await _dio.get<dynamic>('/api/privacy/summary');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PrivacySummaryPayload.fromJson(data);
      }
    } on DioException {
      return PrivacySummaryPayload.fallback();
    }
    return PrivacySummaryPayload.fallback();
  }

  Future<DataActionResult> exportMemories({String userId = 'guest'}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/memory/export',
        queryParameters: {'userId': userId},
      );
      final data = response.data;
      final items = data is Map<String, dynamic>
          ? data['items'] as List<dynamic>? ?? const []
          : const [];
      return DataActionResult(status: 'ok', itemCount: items.length);
    } on DioException {
      return const DataActionResult(status: 'offline');
    }
  }

  Future<DataActionResult> clearAllMemories({String userId = 'guest'}) async {
    return _deleteCount('/api/memory/capsules', userId: userId);
  }

  Future<DataActionResult> clearCurrentTrip({String userId = 'guest'}) async {
    return _deleteCount('/api/trip/current', userId: userId);
  }

  Future<DataActionResult> revokeCloudSync({
    String userId = 'guest',
    List<String> memoryIds = const [],
    bool revokeProfile = false,
    List<String> tripIds = const [],
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/sync/revoke',
        data: {
          'userId': userId,
          'memories': memoryIds,
          'profile': revokeProfile,
          'trips': tripIds,
        },
      );
      final data = response.data;
      return DataActionResult(
        status: 'ok',
        revoked: data is Map<String, dynamic>
            ? Map<String, dynamic>.from(
                data['revoked'] as Map<String, dynamic>? ?? const {},
              )
            : const {},
      );
    } on DioException {
      return const DataActionResult(status: 'offline');
    }
  }

  Future<SyncPushResult> pushSync({
    String userId = 'guest',
    String conflictStrategy = 'serverWins',
    List<SyncMemoryDraft> memories = const [],
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/sync/push',
        data: {
          'userId': userId,
          'conflictStrategy': conflictStrategy,
          'memories': memories.map((item) => item.toJson()).toList(),
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return SyncPushResult.fromJson(data);
      }
    } on DioException {
      return SyncPushResult.offline();
    }
    return SyncPushResult.offline();
  }

  Future<AccountActionResult> upgradeGuestAccount({
    required String account,
    required String password,
    required String displayName,
  }) async {
    try {
      final session = await _authSession.upgradeGuest(
        _dio,
        account: account,
        password: password,
        displayName: displayName,
      );
      return AccountActionResult(status: 'ok', session: session);
    } on DioException catch (error) {
      return AccountActionResult.failed(_authErrorMessage(error));
    }
  }

  Future<AccountActionResult> registerPasswordAccount({
    required String account,
    required String password,
    required String displayName,
  }) async {
    try {
      final session = await _authSession.register(
        _dio,
        account: account,
        password: password,
        displayName: displayName,
      );
      return AccountActionResult(status: 'ok', session: session);
    } on DioException catch (error) {
      return AccountActionResult.failed(_authErrorMessage(error));
    }
  }

  Future<AccountActionResult> loginPasswordAccount({
    required String account,
    required String password,
  }) async {
    try {
      final session = await _authSession.login(
        _dio,
        account: account,
        password: password,
      );
      return AccountActionResult(status: 'ok', session: session);
    } on DioException catch (error) {
      return AccountActionResult.failed(_authErrorMessage(error));
    }
  }

  Future<void> logout() => _authSession.logout();

  Future<DataActionResult> _deleteCount(
    String path, {
    required String userId,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        queryParameters: {'userId': userId},
      );
      final data = response.data;
      final deleted = data is Map<String, dynamic>
          ? (data['deleted'] as num?)?.toInt() ?? 0
          : 0;
      return DataActionResult(status: 'ok', deleted: deleted);
    } on DioException {
      return const DataActionResult(status: 'offline');
    }
  }
}

String _authErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 401) return '账号或密码不正确';
  if (status == 409) return '账号已存在，请直接登录或换一个用户名';
  if (status == null) return '账号服务暂时不可用，请确认后端连接后重试';
  return '账号操作失败（$status），请稍后重试';
}

List<String> _stringList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .map((item) => item.toString())
      .toList();
}
