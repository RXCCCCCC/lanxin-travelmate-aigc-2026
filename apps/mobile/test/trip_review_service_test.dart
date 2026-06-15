import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/review/data/trip_review_service.dart';

void main() {
  test('TripReviewService posts context and maps P1 review payload', () async {
    RequestOptions? capturedRequest;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        capturedRequest = options;
        handler.resolve(Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'route': '解放碑 → 洪崖洞',
            'highlightPhotos': ['洪崖洞夜景'],
            'newMemories': ['喜欢夜景'],
            'completedTasks': [
              {'id': 'task-night-photo', 'title': '拍一张夜景', 'status': 'completed'}
            ],
            'avatarStatusChanges': ['好感度 +2'],
            'nextTripSuggestions': ['成都慢节奏美食线'],
            'temporaryMemoryPromotions': [
              {'id': 'mem-slow-pace', 'title': '想轻松一点', 'suggestedScope': 'longTerm'}
            ],
          },
        ));
      },
    ));

    final service = TripReviewService(dio: dio);
    final review = await service.generateReview(
      tripId: 'demo-trip',
      completedTasks: const [
        {'id': 'task-night-photo', 'title': '拍一张夜景'}
      ],
      temporaryMemories: const [
        {'id': 'mem-slow-pace', 'title': '想轻松一点'}
      ],
    );

    expect(capturedRequest?.path, '/api/trip/review');
    expect(review.route, contains('洪崖洞'));
    expect(review.completedTasks.single['title'], '拍一张夜景');
    expect(review.temporaryMemoryPromotions.single['suggestedScope'], 'longTerm');
  });

  test('TripReviewService returns fallback review when network fails', () async {
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

    final service = TripReviewService(dio: dio);
    final review = await service.generateReview();

    expect(review.route, contains('离线'));
    expect(review.completedTasks, isNotEmpty);
    expect(review.temporaryMemoryPromotions, isNotEmpty);
  });
}
