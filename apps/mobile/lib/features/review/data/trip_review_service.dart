import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class TripReviewPayload {
  const TripReviewPayload({
    required this.route,
    required this.highlightPhotos,
    required this.newMemories,
    required this.completedTasks,
    required this.avatarStatusChanges,
    required this.nextTripSuggestions,
    required this.temporaryMemoryPromotions,
    this.profileContext = const {},
  });

  final String route;
  final List<String> highlightPhotos;
  final List<String> newMemories;
  final List<Map<String, dynamic>> completedTasks;
  final List<String> avatarStatusChanges;
  final List<String> nextTripSuggestions;
  final List<Map<String, dynamic>> temporaryMemoryPromotions;
  final Map<String, dynamic> profileContext;

  factory TripReviewPayload.fromJson(Map<String, dynamic> json) {
    return TripReviewPayload(
      route: json['route'] as String? ?? '今日路线',
      highlightPhotos: _stringList(json['highlightPhotos']),
      newMemories: _stringList(json['newMemories']),
      completedTasks: _mapList(json['completedTasks']),
      avatarStatusChanges: _stringList(json['avatarStatusChanges']),
      nextTripSuggestions: _stringList(json['nextTripSuggestions']),
      temporaryMemoryPromotions: _mapList(json['temporaryMemoryPromotions']),
      profileContext: _map(json['profileContext']),
    );
  }

  factory TripReviewPayload.fallback() {
    return const TripReviewPayload(
      route: '离线复盘：解放碑 → 山城步道 → 洪崖洞',
      highlightPhotos: ['洪崖洞夜景'],
      newMemories: ['喜欢夜景', '本次旅行想轻松一点'],
      completedTasks: [
        {
          'id': 'task-night-photo',
          'title': '拍一张不是游客照的重庆夜景',
          'status': 'completed',
          'reward': '好感度 +2',
        },
      ],
      avatarStatusChanges: ['默契值 +1', '好感度 +2'],
      nextTripSuggestions: ['成都慢节奏美食线', '长沙夜景与小吃线'],
      temporaryMemoryPromotions: [
        {
          'id': 'mem-slow-pace',
          'title': '本次旅行想轻松一点',
          'suggestedScope': 'longTerm',
          'reason': '这条临时记忆已经影响本次规划，建议转为长期偏好。',
        },
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route': route,
      'highlightPhotos': highlightPhotos,
      'newMemories': newMemories,
      'completedTasks': completedTasks,
      'avatarStatusChanges': avatarStatusChanges,
      'nextTripSuggestions': nextTripSuggestions,
      'temporaryMemoryPromotions': temporaryMemoryPromotions,
      'profileContext': profileContext,
    };
  }
}

class TripReviewService {
  TripReviewService({Dio? dio}) : _dio = dio ?? buildApiClient();

  final Dio _dio;

  Future<TripReviewPayload> generateReview({
    String message = '生成今天旅行复盘',
    String? tripId,
    List<Map<String, dynamic>> completedTasks = const [],
    List<Map<String, dynamic>> temporaryMemories = const [],
    Map<String, dynamic> profileContext = const {},
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/trip/review',
        data: {
          'message': message,
          if (tripId != null) 'tripId': tripId,
          'completedTasks': completedTasks,
          'temporaryMemories': temporaryMemories,
          if (profileContext.isNotEmpty) 'profileContext': profileContext,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TripReviewPayload.fromJson({
          ...data,
          if (profileContext.isNotEmpty && data['profileContext'] == null)
            'profileContext': profileContext,
        });
      }
      return TripReviewPayload.fallback();
    } on DioException {
      return TripReviewPayload.fallback();
    }
  }
}

List<String> _stringList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .map((item) => item.toString())
      .toList();
}

List<Map<String, dynamic>> _mapList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();
}

Map<String, dynamic> _map(Object? value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}
