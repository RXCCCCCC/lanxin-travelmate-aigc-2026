import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_group_service.dart';

void main() {
  test('TripGroupService posts members and maps coordination result', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'coordinationId': 'group-a',
                'tripId': 'trip-a',
                'conflicts': [
                  {'type': 'pace', 'title': '节奏冲突'},
                ],
                'compromisePlan': {
                  'pace': 'balanced_slow',
                  'budget': 'low_first',
                  'sharedInterests': ['夜景'],
                },
                'privacySummary': {'publicRule': '只展示汇总后的协调依据。'},
              },
            ),
          );
        },
      ),
    );

    final result = await TripGroupService(dio: dio).coordinate(
      const GroupCoordinationDraft(
        userId: 'guest',
        tripId: 'trip-a',
        destination: '重庆',
        members: [
          GroupMemberDraft(
            memberId: 'member-a',
            displayName: '小林',
            preferences: {
              'pace': 'slow',
              'interests': ['夜景'],
            },
          ),
          GroupMemberDraft(
            memberId: 'member-b',
            displayName: '阿远',
            preferences: {
              'budget': 'low',
              'interests': ['夜景', '山城步道'],
            },
          ),
        ],
      ),
    );

    expect(captured?.path, '/api/trip/group/coordinate');
    expect(captured?.data['destination'], '重庆');
    expect(captured?.data['members'], hasLength(2));
    expect(result.status, 'ok');
    expect(result.payload['compromisePlan']['pace'], 'balanced_slow');
  });

  test('TripGroupService returns offline result on network failure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.unknown,
            ),
          );
        },
      ),
    );

    final result = await TripGroupService(dio: dio).coordinate(
      const GroupCoordinationDraft(
        tripId: 'trip-a',
        members: [
          GroupMemberDraft(
            memberId: 'a',
            displayName: 'A',
            preferences: {'pace': 'slow'},
          ),
          GroupMemberDraft(
            memberId: 'b',
            displayName: 'B',
            preferences: {'pace': 'packed'},
          ),
        ],
      ),
    );

    expect(result.status, 'offline');
    expect(result.payload, isEmpty);
  });
}
