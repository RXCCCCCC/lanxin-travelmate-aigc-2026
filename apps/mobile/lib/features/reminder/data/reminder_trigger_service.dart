import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

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

  List<Map<String, dynamic>> _fallback(String triggerType) {
    return [
      {
        'id': 'fallback-$triggerType',
        'title': '离线模式提醒',
        'triggerType': triggerType,
        'description': '后端暂不可用，蓝小心先用本地规则给出提醒。',
        'cooldownMinutes': 60,
      }
    ];
  }
}

List<Map<String, dynamic>> _mapList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();
}
