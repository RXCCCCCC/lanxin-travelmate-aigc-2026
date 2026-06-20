import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class GroupMemberDraft {
  const GroupMemberDraft({
    required this.memberId,
    required this.displayName,
    required this.preferences,
    this.sensitivePreferences = const {},
  });

  final String memberId;
  final String displayName;
  final Map<String, Object> preferences;
  final Map<String, Object> sensitivePreferences;

  Map<String, Object> toJson() {
    return {
      'memberId': memberId,
      'displayName': displayName,
      'preferences': preferences,
      if (sensitivePreferences.isNotEmpty)
        'sensitivePreferences': sensitivePreferences,
    };
  }
}

class GroupCoordinationDraft {
  const GroupCoordinationDraft({
    this.userId = 'guest',
    required this.tripId,
    this.destination,
    required this.members,
  });

  final String userId;
  final String tripId;
  final String? destination;
  final List<GroupMemberDraft> members;

  Map<String, Object?> toJson() {
    return {
      'userId': userId,
      'tripId': tripId,
      if (destination != null && destination!.trim().isNotEmpty)
        'destination': destination,
      'members': members.map((member) => member.toJson()).toList(),
    };
  }
}

class GroupCoordinationResult {
  const GroupCoordinationResult({required this.status, required this.payload});

  final String status;
  final Map<String, dynamic> payload;

  factory GroupCoordinationResult.ok(Map<String, dynamic> payload) {
    return GroupCoordinationResult(status: 'ok', payload: payload);
  }

  factory GroupCoordinationResult.offline() {
    return const GroupCoordinationResult(status: 'offline', payload: {});
  }
}

class TripGroupService {
  TripGroupService({Dio? dio}) : _dio = dio ?? buildApiClient();

  final Dio _dio;

  Future<GroupCoordinationResult> coordinate(
    GroupCoordinationDraft draft,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/trip/group/coordinate',
        data: draft.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GroupCoordinationResult.ok(data);
      }
    } on DioException {
      return GroupCoordinationResult.offline();
    }
    return GroupCoordinationResult.offline();
  }
}
