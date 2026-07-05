import 'dart:async';

// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/avatar_states.dart';
import '../../../data/agent_response_cache.dart';
import '../../../shared/models/travelmate_models.dart';
import '../../chat/data/agent_chat_service.dart';
import '../../chat/data/chat_history_service.dart';

enum HomeChatSendResult { sent, queued, ignored }

class HomeChatController extends ChangeNotifier {
  HomeChatController({
    AgentChatService? agentChatService,
    ChatHistoryService? chatHistoryService,
    String? sessionId,
    String? tripId,
  }) : _agentChatService = agentChatService ?? AgentChatService(),
       _chatHistoryService = chatHistoryService,
       sessionId =
           sessionId ?? 'home-session-${DateTime.now().millisecondsSinceEpoch}',
       tripId = tripId ?? 'home-trip-${DateTime.now().millisecondsSinceEpoch}';

  final AgentChatService _agentChatService;
  final ChatHistoryService? _chatHistoryService;
  final List<ChatMessage> _messages = [
    const ChatMessage(
      id: 'home-welcome',
      sender: MessageSender.assistant,
      text: '告诉我目的地、时间和偏好，我在首页直接陪你规划。',
      time: '现在',
      avatarState: AvatarState.hello,
    ),
  ];

  CancelToken? _cancelToken;
  Future<void>? _activeRequest;
  String? _queuedMessage;
  String? _statusMessage;

  String sessionId;
  String tripId;
  AvatarState avatarState = AvatarState.hello;
  bool isSending = false;
  int memoryCandidateCount = 0;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get queuedMessage => _queuedMessage;
  String? get statusMessage => _statusMessage;

  Future<void> bindInitialSession() async {
    await _chatHistoryService?.bindSessionToTrip(
      sessionId: sessionId,
      tripTitle: '未绑定行程',
      tripId: tripId,
    );
  }

  void switchSession({
    required String nextSessionId,
    required String nextTripId,
  }) {
    stop(showStatus: false);
    sessionId = nextSessionId;
    tripId = nextTripId;
    _messages
      ..clear()
      ..add(
        const ChatMessage(
          id: 'home-welcome',
          sender: MessageSender.assistant,
          text: '已切换到这段行程的对话，你可以继续补充目的地、时间和偏好。',
          time: '现在',
          avatarState: AvatarState.hello,
        ),
      );
    notifyListeners();
  }

  void replaceMessages(List<ChatMessage> messages) {
    _messages
      ..clear()
      ..addAll(messages);
    avatarState = _messages.lastOrNull?.avatarState ?? AvatarState.hello;
    memoryCandidateCount = 0;
    notifyListeners();
  }

  Future<HomeChatSendResult> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return HomeChatSendResult.ignored;
    if (isSending) {
      _queuedMessage = _mergeQueuedMessage(_queuedMessage, trimmed);
      _addUserMessage(trimmed);
      await _saveMessage(MessageSender.user, trimmed);
      _setStatus('已加入下一轮思考');
      notifyListeners();
      return HomeChatSendResult.queued;
    }
    _activeRequest = _sendToAgent(trimmed, addUserMessage: true);
    unawaited(_activeRequest);
    return HomeChatSendResult.sent;
  }

  void stop({bool showStatus = true}) {
    _cancelToken?.cancel('user_stopped_generation');
    _cancelToken = null;
    _activeRequest = null;
    _queuedMessage = null;
    isSending = false;
    if (showStatus) {
      _addAssistantMessage('已停止生成，你可以继续补充目的地、预算、同行人或时间。');
      _setStatus('已停止生成');
    }
    notifyListeners();
  }

  void clearStatus() {
    if (_statusMessage == null) return;
    _statusMessage = null;
    notifyListeners();
  }

  Future<void> _sendToAgent(String text, {required bool addUserMessage}) async {
    if (addUserMessage) {
      _addUserMessage(text);
      await _saveMessage(MessageSender.user, text);
    }
    isSending = true;
    _cancelToken = CancelToken();
    notifyListeners();

    try {
      final response = await _agentChatService.sendMessage(
        text,
        sessionId: sessionId,
        userId: 'guest',
        tripId: tripId,
        context: {
          'entry': 'home_companion',
          'surface': 'avatar_home',
          if (_queuedMessage != null) 'queuedSupplement': _queuedMessage,
        },
        cancelToken: _cancelToken,
      );
      latestAgentResponse.value = response;
      avatarState = response.avatarState;
      memoryCandidateCount = response.memoryCandidates.length;
      _addAssistantMessage(
        response.replyText,
        avatarState: response.avatarState,
      );
      await _saveMessage(
        MessageSender.assistant,
        response.replyText,
        avatarState: response.avatarState,
      );
    } on AgentChatCancelledException {
      return;
    } catch (_) {
      const fallbackText = '后端暂时连不上，我先用离线模式陪你继续规划。';
      avatarState = AvatarState.thinking;
      _addAssistantMessage(fallbackText, avatarState: avatarState);
      await _saveMessage(
        MessageSender.assistant,
        fallbackText,
        avatarState: avatarState,
      );
      _setStatus('后端暂时连不上，已显示离线回复');
    } finally {
      isSending = false;
      _cancelToken = null;
      notifyListeners();
    }

    final next = _queuedMessage;
    if (next != null && next.trim().isNotEmpty) {
      _queuedMessage = null;
      _activeRequest = _sendToAgent(next, addUserMessage: false);
      unawaited(_activeRequest);
    }
  }

  void _addUserMessage(String text) {
    _messages.add(
      ChatMessage(
        id: 'home-user-${DateTime.now().microsecondsSinceEpoch}',
        sender: MessageSender.user,
        text: text,
        time: _timeText(),
      ),
    );
  }

  void _addAssistantMessage(String text, {AvatarState? avatarState}) {
    _messages.add(
      ChatMessage(
        id: 'home-assistant-${DateTime.now().microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        text: text,
        time: _timeText(),
        avatarState: avatarState ?? AvatarState.hello,
      ),
    );
  }

  Future<void> _saveMessage(
    MessageSender sender,
    String text, {
    AvatarState? avatarState,
  }) async {
    await _chatHistoryService?.saveMessage(
      sessionId: sessionId,
      sender: sender,
      text: text,
      avatarState: avatarState,
    );
  }

  void _setStatus(String message) {
    _statusMessage = message;
  }

  String _timeText() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _mergeQueuedMessage(String? existing, String next) {
    if (existing == null || existing.trim().isEmpty) return next;
    return '$existing\n$next';
  }
}
