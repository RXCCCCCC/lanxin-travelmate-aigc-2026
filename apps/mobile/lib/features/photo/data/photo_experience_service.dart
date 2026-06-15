import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class PhotoExperienceService {
  PhotoExperienceService({Dio? dio}) : _dio = dio ?? buildApiClient();

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchCandidates() async {
    try {
      final response = await _dio.get<dynamic>('/api/photo/candidates');
      final data = response.data;
      if (data is Map<String, dynamic>) return _mapList(data['items']);
      return _fallbackCandidates();
    } on DioException {
      return _fallbackCandidates();
    }
  }

  Future<Map<String, dynamic>> generateCopywriting({
    List<String> photoIds = const [],
    String persona = '活泼向导',
    String style = '轻松',
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/photo/copywriting',
        data: {
          'photoIds': photoIds,
          'persona': persona,
          'style': style,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return _fallbackCopywriting();
    } on DioException {
      return _fallbackCopywriting();
    }
  }

  Future<List<Map<String, dynamic>>> fetchBlindBoxTasks() async {
    try {
      final response = await _dio.get<dynamic>('/api/trip/blind-box/tasks');
      final data = response.data;
      if (data is Map<String, dynamic>) return _mapList(data['items']);
      return _fallbackTasks();
    } on DioException {
      return _fallbackTasks();
    }
  }

  List<Map<String, dynamic>> _fallbackCandidates() {
    return const [
      {
        'id': 'photo-night',
        'location': '洪崖洞',
        'score': 9.3,
        'description': '夜景灯光层次明显，适合做今日高光。',
        'tags': ['夜景', '高光照片'],
        'canAddToReview': true,
      }
    ];
  }

  Map<String, dynamic> _fallbackCopywriting() {
    return const {
      'moments': '朋友圈文案：重庆夜色刚刚好，今天慢慢走也很值得。',
      'xiaohongshu': '小红书文案：重庆两天一夜轻松夜景线。',
      'diary': '旅行日记：今天的高光留给洪崖洞。',
      'vlogNarration': 'Vlog 旁白：灯亮起时，山城的夜晚开始了。',
    };
  }

  List<Map<String, dynamic>> _fallbackTasks() {
    return const [
      {'id': 'task-photo', 'type': 'photo', 'title': '拍一张不是游客照的重庆夜景'},
    ];
  }
}

List<Map<String, dynamic>> _mapList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();
}
