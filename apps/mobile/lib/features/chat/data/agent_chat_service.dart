import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'agent_chat_models.dart';

class AgentChatService {
  AgentChatService({Dio? dio}) : _dio = dio ?? buildApiClient();

  final Dio _dio;

  Future<AgentChatResponse> sendMessage(
    String message, {
    String? sessionId,
    String? userId,
    String? tripId,
    Map<String, dynamic>? context,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/agent/chat',
        cancelToken: cancelToken,
        data: {
          'message': message,
          if (sessionId != null) 'sessionId': sessionId,
          if (userId != null) 'userId': userId,
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
