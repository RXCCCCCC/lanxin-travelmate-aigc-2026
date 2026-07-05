import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_session_service.dart';

class TripPlanRequestDraft {
  const TripPlanRequestDraft({
    this.userId = 'guest',
    this.tripId,
    this.message,
    required this.destination,
    this.originCoordinate,
    this.destinationCoordinate,
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
  final Map<String, double>? originCoordinate;
  final Map<String, double>? destinationCoordinate;
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
      if (originCoordinate != null && originCoordinate!.isNotEmpty)
        'originCoordinate': originCoordinate,
      if (destinationCoordinate != null && destinationCoordinate!.isNotEmpty)
        'destinationCoordinate': destinationCoordinate,
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
  TripPlanService({Dio? dio, AuthSessionService? authSession})
    : _authSession = authSession ?? AuthSessionService(),
      _dio = dio ?? buildApiClient(authSession: authSession ?? AuthSessionService());

  final Dio _dio;
  final AuthSessionService _authSession;

  Future<TripPlanResult> createPlan(TripPlanRequestDraft draft) async {
    final resolvedUserId =
        draft.userId == 'guest'
            ? (await _authSession.currentSession())?.userId ?? draft.userId
            : draft.userId;
    try {
      final response = await _dio.post<dynamic>(
        '/api/trip/plan',
        data: TripPlanRequestDraft(
          userId: resolvedUserId,
          tripId: draft.tripId,
          message: draft.message,
          destination: draft.destination,
          originCoordinate: draft.originCoordinate,
          destinationCoordinate: draft.destinationCoordinate,
          startDate: draft.startDate,
          endDate: draft.endDate,
          budget: draft.budget,
          companions: draft.companions,
          preferences: draft.preferences,
          transportMode: draft.transportMode,
          tripStyle: draft.tripStyle,
          replanReason: draft.replanReason,
          groupCoordination: draft.groupCoordination,
        ).toJson(),
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
