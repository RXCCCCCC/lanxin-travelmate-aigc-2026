import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_session_service.dart';
import 'agent_chat_models.dart';

/// 流式聊天过程中的阶段事件。
class AgentChatStageEvent {
  const AgentChatStageEvent({required this.node, required this.label});

  final String node;
  final String label;
}

class AgentChatService {
  AgentChatService({Dio? dio, AuthSessionService? authSession})
    : _authSession = authSession ?? AuthSessionService(),
      _dio = dio ?? buildApiClient(authSession: authSession ?? AuthSessionService());

  final Dio _dio;
  final AuthSessionService _authSession;

  /// SSE 流式发送：逐阶段回调 onStage，返回最终完整响应。
  /// 失败时自动降级到非流式 sendMessage。
  Future<AgentChatResponse> sendMessageStreaming(
    String message, {
    String? sessionId,
    String? userId,
    String? tripId,
    Map<String, dynamic>? context,
    CancelToken? cancelToken,
    void Function(AgentChatStageEvent stage)? onStage,
  }) async {
    final resolvedUserId =
        userId ?? (await _authSession.currentSession())?.userId ?? 'guest';
    try {
      final response = await _dio.post<ResponseBody>(
        '/api/agent/chat/stream',
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 120),
        ),
        data: {
          'message': message,
          if (sessionId != null) 'sessionId': sessionId,
          'userId': resolvedUserId,
          if (tripId != null) 'tripId': tripId,
          if (context != null) 'context': context,
        },
      );
      final body = response.data;
      if (body == null) {
        throw StateError('empty stream body');
      }
      AgentChatResponse? finalResponse;
      String? currentEvent;
      final lines = body.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
        } else if (line.startsWith('data:') && currentEvent != null) {
          final raw = line.substring(5).trim();
          if (raw.isEmpty) continue;
          final decoded = jsonDecode(raw);
          if (decoded is! Map<String, dynamic>) continue;
          switch (currentEvent) {
            case 'stage':
              onStage?.call(
                AgentChatStageEvent(
                  node: decoded['node']?.toString() ?? '',
                  label: decoded['label']?.toString() ?? '',
                ),
              );
            case 'final':
              finalResponse = AgentChatResponse.fromJson(decoded);
            case 'error':
              throw StateError(decoded['message']?.toString() ?? 'stream error');
          }
        }
      }
      if (finalResponse != null) {
        return finalResponse;
      }
      throw StateError('stream ended without final event');
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        throw AgentChatCancelledException();
      }
      // 流式端点不可用时降级到非流式
      return sendMessage(
        message,
        sessionId: sessionId,
        userId: userId,
        tripId: tripId,
        context: context,
        cancelToken: cancelToken,
      );
    } on Object {
      return sendMessage(
        message,
        sessionId: sessionId,
        userId: userId,
        tripId: tripId,
        context: context,
        cancelToken: cancelToken,
      );
    }
  }

  Future<AgentChatResponse> sendMessage(
    String message, {
    String? sessionId,
    String? userId,
    String? tripId,
    Map<String, dynamic>? context,
    CancelToken? cancelToken,
  }) async {
    final resolvedUserId =
        userId ?? (await _authSession.currentSession())?.userId ?? 'guest';
    try {
      final response = await _dio.post<dynamic>(
        '/api/agent/chat',
        cancelToken: cancelToken,
        data: {
          'message': message,
          if (sessionId != null) 'sessionId': sessionId,
          'userId': resolvedUserId,
          if (tripId != null) 'tripId': tripId,
          if (context != null) 'context': context,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AgentChatResponse.fromJson(data);
      }
      return AgentChatResponse.fallback('后端返回格式异常，我先用离线模式陪你继续规划。');
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        throw AgentChatCancelledException();
      }
      return AgentChatResponse.fallback('后端暂时连不上，我先用离线模式陪你继续规划。');
    }
  }
}

class AgentChatCancelledException implements Exception {
  const AgentChatCancelledException();
}
