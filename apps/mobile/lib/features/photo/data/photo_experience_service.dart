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
        data: {'photoIds': photoIds, 'persona': persona, 'style': style},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return _fallbackCopywriting();
    } on DioException {
      return _fallbackCopywriting();
    }
  }

  Future<Map<String, dynamic>> createUploadMetadata({
    String userId = 'guest',
    required String filename,
    String contentType = 'image/jpeg',
    String? localPath,
    String? remoteUrl,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/photo/upload-metadata',
        data: {
          'userId': userId,
          'filename': filename,
          'contentType': contentType,
          if (localPath != null) 'localPath': localPath,
          if (remoteUrl != null) 'remoteUrl': remoteUrl,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return _fallbackUploadMetadata(filename: filename, remoteUrl: remoteUrl);
    } on DioException {
      return _fallbackUploadMetadata(filename: filename, remoteUrl: remoteUrl);
    }
  }

  Future<Map<String, dynamic>> createCandidate({
    String userId = 'guest',
    String? id,
    String? tripId,
    String? remoteUrl,
    required String location,
    required double score,
    required String description,
    List<String> tags = const [],
    bool canAddToReview = true,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/photo/candidates',
        data: {
          if (id != null) 'id': id,
          'userId': userId,
          if (tripId != null) 'tripId': tripId,
          if (remoteUrl != null) 'remoteUrl': remoteUrl,
          'location': location,
          'score': score,
          'description': description,
          'tags': tags,
          'canAddToReview': canAddToReview,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return _fallbackCreatedCandidate(
        id: id,
        location: location,
        score: score,
        description: description,
        tags: tags,
        remoteUrl: remoteUrl,
      );
    } on DioException {
      return _fallbackCreatedCandidate(
        id: id,
        location: location,
        score: score,
        description: description,
        tags: tags,
        remoteUrl: remoteUrl,
      );
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

  Map<String, dynamic> _fallbackUploadMetadata({
    required String filename,
    String? remoteUrl,
  }) {
    return {
      'id': 'offline-upload-$filename',
      'filename': filename,
      'contentType': 'image/jpeg',
      'localPath': null,
      'remoteUrl': remoteUrl,
      'privacy': {'localPathStored': false},
      'offline': true,
    };
  }

  Map<String, dynamic> _fallbackCreatedCandidate({
    String? id,
    required String location,
    required double score,
    required String description,
    required List<String> tags,
    String? remoteUrl,
  }) {
    return {
      'id': id ?? 'offline-photo',
      'location': location,
      'score': score,
      'description': description,
      'tags': tags,
      'localUri': null,
      'remoteUrl': remoteUrl,
      'canAddToReview': true,
      'offline': true,
    };
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
      },
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
