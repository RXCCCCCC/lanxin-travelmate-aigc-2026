import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/reminder/data/reminder_trigger_service.dart';

void main() {
  test(
    'ReminderTriggerService posts trigger and maps returned items',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'items': [
                    {
                      'id': 'reminder-new-photo',
                      'title': '这张照片适合加入旅拍候选',
                      'triggerType': 'behavior',
                      'description': '可进入复盘。',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final service = ReminderTriggerService(dio: dio);
      final reminders = await service.trigger(
        'behavior',
        eventPayload: const {'event': 'newPhoto'},
      );

      expect(reminders.single['triggerType'], 'behavior');
      expect(reminders.single['title'], contains('旅拍候选'));
    },
  );

  test(
    'ReminderTriggerService returns fallback reminders when network fails',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: 'offline',
              ),
            );
          },
        ),
      );

      final service = ReminderTriggerService(dio: dio);
      final reminders = await service.trigger('external');

      expect(reminders, isNotEmpty);
      expect(reminders.first['triggerType'], 'external');
    },
  );
  test(
    'ReminderTriggerService posts evaluate context and maps suppression fields',
    () async {
      RequestOptions? capturedRequest;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'triggered': false,
                  'historyId': null,
                  'items': [],
                  'suppressedReason': 'cooldown',
                  'cooldownRemainingSeconds': 120,
                },
              ),
            );
          },
        ),
      );

      final service = ReminderTriggerService(dio: dio);
      final result = await service.evaluate(
        const ReminderEvaluateDraft(
          userId: 'guest',
          tripId: 'trip-a',
          proactivityLevel: 'quiet',
          currentTime: '2026-06-20T18:20:00+08:00',
          location: '洪崖洞',
          status: {'energy': 31, 'travelPace': 'light'},
          external: {
            'interestTags': ['夜景'],
          },
        ),
      );

      expect(capturedRequest?.path, '/api/trip/reminders/evaluate');
      expect(capturedRequest?.data['proactivityLevel'], 'quiet');
      expect(capturedRequest?.data['status']['travelPace'], 'light');
      expect(capturedRequest?.data['external']['interestTags'], ['夜景']);
      expect(result.triggered, isFalse);
      expect(result.suppressedReason, 'cooldown');
      expect(result.cooldownRemainingSeconds, 120);
    },
  );

  test(
    'ReminderTriggerService evaluate returns fallback result when network fails',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: 'offline',
              ),
            );
          },
        ),
      );

      final result = await ReminderTriggerService(
        dio: dio,
      ).evaluate(const ReminderEvaluateDraft(proactivityLevel: 'active'));

      expect(result.triggered, isFalse);
      expect(result.items, isEmpty);
      expect(result.suppressedReason, 'offline');
    },
  );
}
