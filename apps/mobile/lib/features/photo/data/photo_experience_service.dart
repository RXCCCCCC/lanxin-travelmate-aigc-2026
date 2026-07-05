import 'dart:convert';
import 'dart:typed_data';

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
      return const [];
    } on DioException {
      return const [];
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

  Future<Map<String, dynamic>> analyzePhoto({
    String userId = 'guest',
    String? tripId,
    required String filename,
    required String contentType,
    required Uint8List previewBytes,
    String source = 'gallery',
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/photo/analyze',
        data: {
          'userId': userId,
          if (tripId != null) 'tripId': tripId,
          'filename': filename,
          'contentType': contentType,
          'imageBase64': base64Encode(previewBytes),
          'source': source,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
    } on DioException {
      return _fallbackPhotoAnalysis(source: source);
    }
    return _fallbackPhotoAnalysis(source: source);
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
      return const [];
    } on DioException {
      return const [];
    }
  }

  Future<Map<String, dynamic>> updateBlindBoxTaskStatus({
    String userId = 'guest',
    required String tripId,
    required String taskId,
    required String status,
    String? note,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/trip/blind-box/tasks/$taskId/status',
        data: {
          'userId': userId,
          'tripId': tripId,
          'status': status,
          if (note != null && note.trim().isNotEmpty) 'note': note,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
    } on DioException {
      return _fallbackBlindBoxTaskStatus(
        taskId: taskId,
        status: 'offline',
        note: '盲盒任务状态同步失败，请检查后端连接后重试。',
      );
    }
    return _fallbackBlindBoxTaskStatus(
      taskId: taskId,
      status: 'offline',
      note: '盲盒任务状态响应无效，请稍后重试。',
    );
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

  Map<String, dynamic> _fallbackPhotoAnalysis({required String source}) {
    return {
      'location': source == 'camera' ? '相机拍摄照片' : '系统相册照片',
      'score': 7.2,
      'description': '图片分析暂不可用，已保留真实预览，可稍后重试分析。',
      'tags': [source == 'camera' ? '相机拍摄' : '相册导入', '分析失败，可重试'],
      'reviewSuggestion': '分析失败时建议重试后再加入复盘高光。',
      'canAddToReview': false,
      'offline': true,
    };
  }

  Map<String, dynamic> _fallbackBlindBoxTaskStatus({
    required String taskId,
    required String status,
    String? note,
  }) {
    return {
      'id': 'offline-$taskId',
      'taskId': taskId,
      'status': status,
      'title': taskId,
      'rewardApplied': false,
      if (note != null) 'note': note,
      'offline': true,
    };
  }

  Map<String, dynamic> _fallbackCopywriting() {
    return const {
      'moments': '文案生成暂不可用，请检查后端或模型配置后重试。',
      'xiaohongshu': '文案生成暂不可用，请检查后端或模型配置后重试。',
      'diary': '文案生成暂不可用，请检查后端或模型配置后重试。',
      'vlogNarration': '文案生成暂不可用，请检查后端或模型配置后重试。',
      'offline': true,
    };
  }
}

List<Map<String, dynamic>> _mapList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();
}
