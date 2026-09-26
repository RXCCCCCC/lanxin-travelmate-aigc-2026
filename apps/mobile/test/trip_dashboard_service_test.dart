import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_dashboard_service.dart';

void main() {
  test('TripDashboardService fetches dashboard with user and trip filters', () async {
    RequestOptions? capturedRequest;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        capturedRequest = options;
        handler.resolve(Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'userId': 'user-a',
            'tripId': 'trip-a',
            'currentTrip': {
              'tripId': 'trip-a',
              'status': 'planning',
              'destination': 'Hangzhou',
              'plan': {'title': 'West Lake slow route'},
            },
            'routePoints': {
              'route': 'Hotel -> West Lake',
              'points': [
                {'label': 'Hotel'},
                {'label': 'West Lake'},
              ],
            },
            'reminderHistory': {
              'items': [
                {'historyId': 'reminder-a', 'triggerType': 'location'},
              ],
            },
            'blindBoxTasks': {
              'items': [
                {'id': 'task-photo-night', 'status': 'completed'},
              ],
            },
            'avatarStateEvents': {
              'items': [
                {'eventType': 'memory_confirmed', 'title': 'Confirmed memory'},
              ],
            },
            'latestReview': {
              'reviewId': 'review-a',
              'review': {'route': 'Hotel -> West Lake'},
            },
            'photoCandidates': {
              'items': [
                {'id': 'photo-a', 'location': 'West Lake'},
              ],
            },
            'memories': {
              'items': [
                {'id': 'memory-a', 'title': 'Prefers night views'},
              ],
            },
          },
        ));
      },
    ));

    final service = TripDashboardService(dio: dio);
    final dashboard = await service.fetchDashboard(userId: 'user-a', tripId: 'trip-a');

    expect(capturedRequest?.path, '/api/trip/dashboard');
    expect(capturedRequest?.queryParameters['userId'], 'user-a');
    expect(capturedRequest?.queryParameters['tripId'], 'trip-a');
    expect(dashboard.tripId, 'trip-a');
    expect(dashboard.currentTrip['destination'], 'Hangzhou');
    expect(dashboard.routePoints['route'], contains('West Lake'));
    expect(dashboard.reminderHistory, hasLength(1));
    expect(dashboard.blindBoxTasks.single['status'], 'completed');
    expect(dashboard.avatarStateEvents.single['eventType'], 'memory_confirmed');
    expect(dashboard.latestReview['reviewId'], 'review-a');
    expect(dashboard.photoCandidates.single['location'], 'West Lake');
    expect(dashboard.memories.single['title'], 'Prefers night views');
  });

  test('TripDashboardService returns empty fallback when network fails', () async {
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

    final service = TripDashboardService(dio: dio);
    final dashboard = await service.fetchDashboard(userId: 'user-a');

    expect(dashboard.userId, 'user-a');
    expect(dashboard.currentTrip['status'], 'offline');
    expect(dashboard.reminderHistory, isEmpty);
    expect(dashboard.photoCandidates, isEmpty);
  });
}
