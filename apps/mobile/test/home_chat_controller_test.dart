import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/core/constants/avatar_states.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_models.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_service.dart';
import 'package:lanxin_travelmate/features/home/data/home_chat_controller.dart';

class _FakeAgentChatService extends AgentChatService {
  _FakeAgentChatService() : super(dio: Dio());

  final requests = <String>[];
  final completers = <Completer<AgentChatResponse>>[];
  final cancelTokens = <CancelToken?>[];

  @override
  Future<AgentChatResponse> sendMessage(
    String message, {
    String? sessionId,
    String? userId,
    String? tripId,
    Map<String, dynamic>? context,
    CancelToken? cancelToken,
  }) {
    requests.add(message);
    cancelTokens.add(cancelToken);
    final completer = Completer<AgentChatResponse>();
    completers.add(completer);
    cancelToken?.whenCancel.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(const AgentChatCancelledException());
      }
    });
    return completer.future;
  }
}

class _FailingAgentChatService extends AgentChatService {
  _FailingAgentChatService() : super(dio: Dio());

  @override
  Future<AgentChatResponse> sendMessage(
    String message, {
    String? sessionId,
    String? userId,
    String? tripId,
    Map<String, dynamic>? context,
    CancelToken? cancelToken,
  }) {
    return Future<AgentChatResponse>.error(
      DioException(
        requestOptions: RequestOptions(path: '/api/agent/chat'),
        type: DioExceptionType.connectionError,
        error: 'offline',
      ),
    );
  }
}

AgentChatResponse _response(String text) {
  return AgentChatResponse(
    replyText: text,
    voiceText: text,
    avatarState: AvatarState.hello,
    emotion: 'happy',
    cards: const [],
    memoryCandidates: const [],
    toolTrace: const [],
    nextActions: const [],
    syncSuggestions: const [],
    errors: const [],
  );
}

void main() {
  group('HomeChatController', () {
    test('queues extra user input while the agent is thinking', () async {
      final service = _FakeAgentChatService();
      final controller = HomeChatController(agentChatService: service);

      unawaited(controller.send('我想去广州玩'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.isSending, isTrue);
      expect(service.requests, ['我想去广州玩']);

      final queued = await controller.send('再加上不要太累');

      expect(queued, HomeChatSendResult.queued);
      expect(controller.queuedMessage, '再加上不要太累');
      expect(controller.messages.last.text, '再加上不要太累');
      expect(service.requests, ['我想去广州玩']);

      service.completers.first.complete(_response('先给你一个广州轻松方案'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(service.requests, ['我想去广州玩', '再加上不要太累']);
      service.completers.last.complete(_response('我已把节奏放慢'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.isSending, isFalse);
      expect(controller.queuedMessage, isNull);
      expect(controller.messages.last.text, '我已把节奏放慢');
    });

    test(
      'stops the active request and keeps the user message visible',
      () async {
        final service = _FakeAgentChatService();
        final controller = HomeChatController(agentChatService: service);

        unawaited(controller.send('我想去深圳玩'));
        await Future<void>.delayed(Duration.zero);

        controller.stop();
        await Future<void>.delayed(Duration.zero);

        expect(service.cancelTokens.single?.isCancelled, isTrue);
        expect(controller.isSending, isFalse);
        expect(
          controller.messages.any((item) => item.text == '我想去深圳玩'),
          isTrue,
        );
        expect(controller.messages.last.text, contains('已停止'));
      },
    );

    test('surfaces a clear assistant fallback when the home agent fails', () async {
      final controller = HomeChatController(
        agentChatService: _FailingAgentChatService(),
      );

      unawaited(controller.send('首页发消息没回应'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isSending, isFalse);
      expect(
        controller.messages.any((item) => item.text.contains('暂时连不上')),
        isTrue,
      );
      expect(controller.statusMessage, contains('后端暂时连不上'));
    });
  });
}
