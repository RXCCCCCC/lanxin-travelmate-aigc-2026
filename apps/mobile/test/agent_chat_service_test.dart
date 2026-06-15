import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_models.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_service.dart';

void main() {
  test('AgentChatResponse parses backend camelCase payload', () {
    final response = AgentChatResponse.fromJson({
      'replyText': '我会按轻松节奏安排重庆夜景路线。',
      'voiceText': '我会按轻松节奏安排重庆夜景路线。',
      'avatarState': 'planning',
      'emotion': 'curious',
      'cards': [
        {'type': 'tripPlan'}
      ],
      'memoryCandidates': [
        {'id': 'mem-cilantro', 'title': '不吃香菜'}
      ],
      'toolTrace': [
        {'tool': 'weather_tool'}
      ],
      'nextActions': [
        {'type': 'confirmMemory'}
      ],
      'syncSuggestions': [],
      'errors': [],
    });

    expect(response.replyText, contains('重庆'));
    expect(response.avatarState.name, 'planning');
    expect(response.memoryCandidates.single.title, '不吃香菜');
    expect(response.cards.single['type'], 'tripPlan');
  });

  test('AgentChatService posts message and maps response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'replyText': '后端 Mock 回复',
            'voiceText': '后端 Mock 回复',
            'avatarState': 'planning',
            'emotion': 'curious',
            'cards': [],
            'memoryCandidates': [],
            'toolTrace': [],
            'nextActions': [],
            'syncSuggestions': [],
            'errors': [],
          },
        ));
      },
    ));

    final service = AgentChatService(dio: dio);
    final response = await service.sendMessage('你好');

    expect(response.replyText, '后端 Mock 回复');
    expect(response.avatarState.name, 'planning');
  });

  test('AgentChatService returns fallback response when network fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'offline',
        ));
      },
    ));

    final service = AgentChatService(dio: dio);
    final response = await service.sendMessage('你好');

    expect(response.replyText, contains('离线'));
    expect(response.avatarState.name, 'thinking');
    expect(response.errors.single['code'], 'NETWORK_FALLBACK');
  });
}
