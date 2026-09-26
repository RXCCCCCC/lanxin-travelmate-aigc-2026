import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_session_service.dart';

class TripDashboardPayload {
  const TripDashboardPayload({
    required this.userId,
    this.tripId,
    required this.currentTrip,
    required this.routePoints,
    required this.reminderHistory,
    required this.blindBoxTasks,
    required this.avatarStateEvents,
    required this.latestReview,
    required this.photoCandidates,
    required this.memories,
  });

  final String userId;
  final String? tripId;
  final Map<String, dynamic> currentTrip;
  final Map<String, dynamic> routePoints;
  final List<Map<String, dynamic>> reminderHistory;
  final List<Map<String, dynamic>> blindBoxTasks;
  final List<Map<String, dynamic>> avatarStateEvents;
  final Map<String, dynamic> latestReview;
  final List<Map<String, dynamic>> photoCandidates;
  final List<Map<String, dynamic>> memories;

  factory TripDashboardPayload.fromJson(Map<String, dynamic> json) {
    return TripDashboardPayload(
      userId: json['userId'] as String? ?? 'guest',
      tripId: json['tripId'] as String?,
      currentTrip: _map(json['currentTrip']),
      routePoints: _map(json['routePoints']),
      reminderHistory: _items(json['reminderHistory']),
      blindBoxTasks: _items(json['blindBoxTasks']),
      avatarStateEvents: _items(json['avatarStateEvents']),
      latestReview: _map(json['latestReview']),
      photoCandidates: _items(json['photoCandidates']),
      memories: _items(json['memories']),
    );
  }

  factory TripDashboardPayload.fallback({required String userId, String? tripId}) {
    return TripDashboardPayload(
      userId: userId,
      tripId: tripId,
      currentTrip: {
        'tripId': tripId,
        'userId': userId,
        'status': 'offline',
        'plan': <String, dynamic>{},
      },
      routePoints: const {'points': <Map<String, dynamic>>[], 'route': ''},
      reminderHistory: const [],
      blindBoxTasks: const [],
      avatarStateEvents: const [],
      latestReview: const {'reviewId': null, 'review': <String, dynamic>{}},
      photoCandidates: const [],
      memories: const [],
    );
  }
}

class TripDashboardService {
  TripDashboardService({Dio? dio, AuthSessionService? authSession})
    : _authSession = authSession ?? AuthSessionService(),
      _dio = dio ?? buildApiClient(authSession: authSession ?? AuthSessionService());

  final Dio _dio;
  final AuthSessionService _authSession;

  Future<TripDashboardPayload> fetchDashboard({
    String? userId,
    String? tripId,
  }) async {
    final resolvedUserId =
        userId ?? (await _authSession.currentSession())?.userId ?? 'guest';
    try {
      final response = await _dio.get<dynamic>(
        '/api/trip/dashboard',
        queryParameters: {
          'userId': resolvedUserId,
          if (tripId != null) 'tripId': tripId,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TripDashboardPayload.fromJson(data);
      }
      return TripDashboardPayload.fallback(userId: resolvedUserId, tripId: tripId);
    } on DioException {
      return TripDashboardPayload.fallback(userId: resolvedUserId, tripId: tripId);
    }
  }
}

Map<String, dynamic> _map(Object? value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

List<Map<String, dynamic>> _items(Object? value) {
  final data = _map(value)['items'];
  return (data as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();
}
