import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_session_service.dart';
import 'agent_chat_models.dart';

class AgentChatService {
  AgentChatService({Dio? dio, AuthSessionService? authSession})
    : _authSession = authSession ?? AuthSessionService(),
      _dio = dio ?? buildApiClient(authSession: authSession ?? AuthSessionService());

  final Dio _dio;
  final AuthSessionService _authSession;

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
