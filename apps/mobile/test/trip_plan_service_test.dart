import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_plan_service.dart';

void main() {
  test('TripPlanService posts real planning inputs and maps plan', () async {
    Map<String, dynamic>? capturedBody;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = Map<String, dynamic>.from(options.data as Map);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'title': 'Hangzhou family plan',
                  'destination': 'Hangzhou',
                  'dateRange': '2026-07-01 - 2026-07-03',
                  'planningInputs': {
                    'destination': 'Hangzhou',
                    'dateRange': {
                      'startDate': '2026-07-01',
                      'endDate': '2026-07-03',
                    },
                    'budget': 'medium',
                    'companions': ['mother', 'child'],
                    'preferences': ['night view', 'less walking'],
                    'transportMode': 'transit',
                    'tripStyle': 'family_relaxed',
                  },
                  'days': const [],
                  'risks': const [],
                  'profileMatches': const ['medium budget applied'],
                },
              ),
            );
          },
        ),
      );

    final service = TripPlanService(dio: dio);
    final result = await service.createPlan(
      const TripPlanRequestDraft(
        userId: 'guest',
        tripId: 'trip-1',
        message: 'Plan Hangzhou with my family.',
        destination: 'Hangzhou',
        startDate: '2026-07-01',
        endDate: '2026-07-03',
        budget: 'medium',
        companions: ['mother', 'child'],
        preferences: ['night view', 'less walking'],
        transportMode: 'transit',
        tripStyle: 'family_relaxed',
      ),
    );

    expect(capturedBody?['destination'], 'Hangzhou');
    expect(capturedBody?['startDate'], '2026-07-01');
    expect(capturedBody?['companions'], ['mother', 'child']);
    expect(capturedBody?['preferences'], ['night view', 'less walking']);
    expect(capturedBody?['transportMode'], 'transit');
    expect(result.status, 'ok');
    expect(result.plan['title'], 'Hangzhou family plan');
    expect(result.plan['planningInputs']['budget'], 'medium');
  });

  test('TripPlanService returns offline result on network failure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..interceptors.add(
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

    final result = await TripPlanService(dio: dio).createPlan(
      const TripPlanRequestDraft(destination: 'Hangzhou'),
    );

    expect(result.status, 'offline');
    expect(result.plan, isEmpty);
  });
}
