import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/profile/data/profile_service.dart';

void main() {
  test('ProfileService fetches persisted profile fields', () async {
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
                'userId': 'user-a',
                'travelPace': 'slow',
                'dietaryPreferences': ['no cilantro'],
                'interestTags': ['night views'],
                'transportPreferences': ['transit'],
                'budgetPreference': 'medium',
              },
            ),
          );
        },
      ),
    );

    final service = ProfileService(dio: dio);
    final profile = await service.fetchProfile(userId: 'user-a');

    expect(capturedRequest?.path, '/api/profile/me');
    expect(capturedRequest?.queryParameters['userId'], 'user-a');
    expect(profile.travelPace, 'slow');
    expect(profile.dietaryPreferences, ['no cilantro']);
    expect(profile.interestTags, ['night views']);
    expect(profile.transportPreferences, ['transit']);
    expect(profile.budgetPreference, 'medium');
  });

  test('ProfileService returns fallback when network fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          );
        },
      ),
    );

    final profile = await ProfileService(
      dio: dio,
    ).fetchProfile(userId: 'user-a');

    expect(profile.userId, 'user-a');
    expect(profile.travelPace, isNotEmpty);
  });

  test('ProfileService updates persisted settings fields', () async {
    RequestOptions? capturedRequest;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          capturedRequest = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'userId': 'user-a',
                ...Map<String, dynamic>.from(options.data as Map),
              },
            ),
          );
        },
      ),
    );

    final updated = await ProfileService(dio: dio).updateProfile(
      userId: 'user-a',
      profile: const ProfilePayload(
        userId: 'user-a',
        travelPace: 'slow',
        dietaryPreferences: ['no cilantro'],
        interestTags: ['night views'],
        transportPreferences: ['transit'],
        budgetPreference: 'medium',
        personality: 'quiet_planner',
        proactivityLevel: 'quiet',
        syncStrategy: 'selectedOnly',
        notificationEnabled: false,
        voiceEnabled: false,
        textModePreferred: true,
        customPrompt: 'Keep it concise.',
      ),
    );

    expect(capturedRequest?.method, 'PUT');
    expect(capturedRequest?.path, '/api/profile/me');
    expect(capturedRequest?.queryParameters['userId'], 'user-a');
    expect(capturedRequest?.data['personality'], 'quiet_planner');
    expect(capturedRequest?.data['proactivityLevel'], 'quiet');
    expect(capturedRequest?.data['syncStrategy'], 'selectedOnly');
    expect(capturedRequest?.data['notificationEnabled'], false);
    expect(updated.personality, 'quiet_planner');
    expect(updated.customPrompt, 'Keep it concise.');
  });
}
