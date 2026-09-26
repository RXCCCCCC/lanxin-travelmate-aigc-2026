import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class ReminderEvaluateDraft {
  const ReminderEvaluateDraft({
    this.userId = 'guest',
    this.tripId,
    this.proactivityLevel = 'standard',
    this.currentTime,
    this.location,
    this.status = const {},
    this.external = const {},
  });

  final String userId;
  final String? tripId;
  final String proactivityLevel;
  final String? currentTime;
  final String? location;
  final Map<String, dynamic> status;
  final Map<String, dynamic> external;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      if (tripId != null) 'tripId': tripId,
      'proactivityLevel': proactivityLevel,
      if (currentTime != null) 'currentTime': currentTime,
      if (location != null) 'location': location,
      'status': status,
      'external': external,
    };
  }
}

class ReminderEvaluateResult {
  const ReminderEvaluateResult({
    required this.triggered,
    required this.historyId,
    required this.items,
    required this.suppressedReason,
    required this.cooldownRemainingSeconds,
  });

  final bool triggered;
  final String? historyId;
  final List<Map<String, dynamic>> items;
  final String? suppressedReason;
  final int cooldownRemainingSeconds;

  factory ReminderEvaluateResult.fromJson(Map<String, dynamic> json) {
    return ReminderEvaluateResult(
      triggered: json['triggered'] as bool? ?? false,
      historyId: json['historyId'] as String?,
      items: _mapList(json['items']),
      suppressedReason: json['suppressedReason'] as String?,
      cooldownRemainingSeconds: json['cooldownRemainingSeconds'] as int? ?? 0,
    );
  }

  factory ReminderEvaluateResult.fallback({String reason = 'offline'}) {
    return ReminderEvaluateResult(
      triggered: false,
      historyId: null,
      items: const [],
      suppressedReason: reason,
      cooldownRemainingSeconds: 0,
    );
  }
}

class ReminderTriggerService {
  ReminderTriggerService({Dio? dio}) : _dio = dio ?? buildApiClient();

  final Dio _dio;

  Future<List<Map<String, dynamic>>> trigger(
    String triggerType, {
    String? location,
    Map<String, dynamic> eventPayload = const {},
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/trip/reminders/trigger',
        data: {
          'triggerType': triggerType,
          if (location != null) 'location': location,
          'eventPayload': eventPayload,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return _mapList(data['items']);
      }
      return _fallback(triggerType);
    } on DioException {
      return _fallback(triggerType);
    }
  }

  Future<ReminderEvaluateResult> evaluate(ReminderEvaluateDraft draft) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/trip/reminders/evaluate',
        data: draft.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ReminderEvaluateResult.fromJson(data);
      }
      return ReminderEvaluateResult.fallback(reason: 'invalid_response');
    } on DioException {
      return ReminderEvaluateResult.fallback();
    }
  }

  List<Map<String, dynamic>> _fallback(String triggerType) {
    return [
      {
        'id': 'fallback-$triggerType',
        'title': '离线模式提醒',
        'triggerType': triggerType,
        'description': '后端暂不可用，蓝小心先用本地规则给出提醒。',
        'cooldownMinutes': 60,
      },
    ];
  }
}

List<Map<String, dynamic>> _mapList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();
}
