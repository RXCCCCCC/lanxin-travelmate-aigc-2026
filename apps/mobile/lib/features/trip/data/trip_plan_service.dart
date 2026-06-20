import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class TripPlanRequestDraft {
  const TripPlanRequestDraft({
    this.userId = 'guest',
    this.tripId,
    this.message,
    required this.destination,
    this.startDate,
    this.endDate,
    this.budget,
    this.companions = const [],
    this.preferences = const [],
    this.transportMode,
    this.tripStyle,
    this.replanReason,
    this.groupCoordination,
  });

  final String userId;
  final String? tripId;
  final String? message;
  final String destination;
  final String? startDate;
  final String? endDate;
  final String? budget;
  final List<String> companions;
  final List<String> preferences;
  final String? transportMode;
  final String? tripStyle;
  final String? replanReason;
  final Map<String, dynamic>? groupCoordination;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      if (_hasText(tripId)) 'tripId': tripId,
      if (_hasText(message)) 'message': message,
      'destination': destination,
      if (_hasText(startDate)) 'startDate': startDate,
      if (_hasText(endDate)) 'endDate': endDate,
      if (_hasText(budget)) 'budget': budget,
      if (companions.isNotEmpty) 'companions': companions,
      if (preferences.isNotEmpty) 'preferences': preferences,
      if (_hasText(transportMode)) 'transportMode': transportMode,
      if (_hasText(tripStyle)) 'tripStyle': tripStyle,
      if (_hasText(replanReason)) 'replanReason': replanReason,
      if (groupCoordination != null && groupCoordination!.isNotEmpty)
        'groupCoordination': groupCoordination,
    };
  }
}

class TripPlanResult {
  const TripPlanResult({required this.status, required this.plan});

  final String status;
  final Map<String, dynamic> plan;

  factory TripPlanResult.ok(Map<String, dynamic> plan) {
    return TripPlanResult(status: 'ok', plan: plan);
  }

  factory TripPlanResult.offline() {
    return const TripPlanResult(status: 'offline', plan: {});
  }
}

class TripPlanService {
  TripPlanService({Dio? dio}) : _dio = dio ?? buildApiClient();

  final Dio _dio;

  Future<TripPlanResult> createPlan(TripPlanRequestDraft draft) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/trip/plan',
        data: draft.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TripPlanResult.ok(data);
      }
    } on DioException {
      return TripPlanResult.offline();
    }
    return TripPlanResult.offline();
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
