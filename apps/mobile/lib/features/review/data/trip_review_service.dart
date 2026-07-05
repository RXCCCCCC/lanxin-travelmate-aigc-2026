import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class TripReviewPayload {
  const TripReviewPayload({
    required this.route,
    required this.highlightPhotos,
    required this.newMemories,
    required this.completedTasks,
    required this.reminderHighlights,
    required this.avatarStatusChanges,
    required this.nextTripSuggestions,
    required this.temporaryMemoryPromotions,
    this.profileContext = const {},
  });

  final String route;
  final List<String> highlightPhotos;
  final List<String> newMemories;
  final List<Map<String, dynamic>> completedTasks;
  final List<Map<String, dynamic>> reminderHighlights;
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
      reminderHighlights: _mapList(json['reminderHighlights']),
      avatarStatusChanges: _stringList(json['avatarStatusChanges']),
      nextTripSuggestions: _stringList(json['nextTripSuggestions']),
      temporaryMemoryPromotions: _mapList(json['temporaryMemoryPromotions']),
      profileContext: _map(json['profileContext']),
    );
  }

  factory TripReviewPayload.fallback() {
    return const TripReviewPayload(
      route: '离线复盘：暂无可复盘路线',
      highlightPhotos: ['离线模式下可先整理今天最满意的一张照片'],
      newMemories: ['离线模式下会先保留本机复盘草稿'],
      completedTasks: [
        {
          'id': 'offline-review-task',
          'title': '整理今日路线和高光瞬间',
          'status': 'pending',
        },
      ],
      reminderHighlights: [],
      avatarStatusChanges: ['蓝小心进入离线陪伴模式'],
      nextTripSuggestions: ['后端恢复后重新生成真实路线复盘'],
      temporaryMemoryPromotions: [
        {
          'id': 'offline-memory-candidate',
          'title': '离线复盘待同步',
          'suggestedScope': 'temporary',
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
      'reminderHighlights': reminderHighlights,
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

  Future<TripReviewPayload?> fetchReview({required String tripId}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/trip/review',
        queryParameters: {'tripId': tripId},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final review = data['review'];
        if (review is Map<String, dynamic> && review.isNotEmpty) {
          return TripReviewPayload.fromJson(review);
        }
      }
      return null;
    } on DioException {
      return null;
    }
  }

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
