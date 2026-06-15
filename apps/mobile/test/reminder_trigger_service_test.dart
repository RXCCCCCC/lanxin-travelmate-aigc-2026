import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/reminder/data/reminder_trigger_service.dart';

void main() {
  test('ReminderTriggerService posts trigger and maps returned items', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'items': [
              {
                'id': 'reminder-new-photo',
                'title': '这张照片适合加入旅拍候选',
                'triggerType': 'behavior',
                'description': '可进入复盘。',
              }
            ]
          },
        ));
      },
    ));

    final service = ReminderTriggerService(dio: dio);
    final reminders = await service.trigger(
      'behavior',
      eventPayload: const {'event': 'newPhoto'},
    );

    expect(reminders.single['triggerType'], 'behavior');
    expect(reminders.single['title'], contains('旅拍候选'));
  });

  test('ReminderTriggerService returns fallback reminders when network fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'offline',
        ));
      },
    ));

    final service = ReminderTriggerService(dio: dio);
    final reminders = await service.trigger('external');

    expect(reminders, isNotEmpty);
    expect(reminders.first['triggerType'], 'external');
  });
}
