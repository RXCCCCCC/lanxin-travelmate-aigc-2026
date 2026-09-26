import 'dart:async';

// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/avatar_states.dart';
import '../../../data/agent_response_cache.dart';
import '../../../shared/models/travelmate_models.dart';
import '../../auth/data/auth_session_service.dart';
import '../../chat/data/agent_chat_service.dart';
import '../../chat/data/chat_history_service.dart';

enum HomeChatSendResult { sent, queued, ignored }

class HomeChatController extends ChangeNotifier {
  HomeChatController({
    AgentChatService? agentChatService,
    ChatHistoryService? chatHistoryService,
    AuthSessionService? authSessionService,
    String? sessionId,
    String? tripId,
  }) : _authSessionService = authSessionService ?? AuthSessionService(),
       _agentChatService =
           agentChatService ??
           AgentChatService(
             authSession: authSessionService ?? AuthSessionService(),
           ),
       _chatHistoryService = chatHistoryService,
       sessionId =
           sessionId ?? 'home-session-${DateTime.now().millisecondsSinceEpoch}',
       tripId = tripId ?? 'home-trip-${DateTime.now().millisecondsSinceEpoch}';

  final AgentChatService _agentChatService;
  final AuthSessionService _authSessionService;
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
  String? sendingStageLabel;

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

  /// 进入首页时恢复最近一次有内容的会话，实现「保存对话状态、延续上次对话」。
  /// 无历史或加载失败时回退到全新欢迎会话。
  Future<void> restoreLatestSession() async {
    final service = _chatHistoryService;
    if (service == null) {
      await bindInitialSession();
      return;
    }
    try {
      final userId =
          (await _authSessionService.currentSession())?.userId ?? 'guest';
      final latest = await service.latestSession(userId: userId);
      if (latest == null) {
        await bindInitialSession();
        return;
      }
      final loaded = await service.loadMessages(latest.sessionId);
      if (loaded.isEmpty) {
        await bindInitialSession();
        return;
      }
      stop(showStatus: false);
      sessionId = latest.sessionId;
      tripId = latest.tripId ?? tripId;
      _messages
        ..clear()
        ..addAll(loaded);
      avatarState = _messages.lastOrNull?.avatarState ?? AvatarState.hello;
      memoryCandidateCount = 0;
      notifyListeners();
    } catch (_) {
      // 恢复失败不应阻断首页，退回默认欢迎会话。
      await bindInitialSession();
    }
  }

  Future<void> resetForSessionChange() async {
    stop(showStatus: false);
    final now = DateTime.now().millisecondsSinceEpoch;
    sessionId = 'home-session-$now';
    tripId = 'home-trip-$now';
    _queuedMessage = null;
    _statusMessage = null;
    memoryCandidateCount = 0;
    avatarState = AvatarState.hello;
    _messages
      ..clear()
      ..add(
        const ChatMessage(
          id: 'home-welcome',
          sender: MessageSender.assistant,
          text: '账号已切换，可以继续告诉我目的地、时间和偏好。',
          time: '现在',
          avatarState: AvatarState.hello,
        ),
      );
    await bindInitialSession();
    notifyListeners();
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
      _setStatus('已加入下一轮思考');
      notifyListeners();
      unawaited(_saveMessage(MessageSender.user, trimmed).catchError((_) {}));
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

  List<Map<String, String>> _recentMessagesContext({bool excludeLast = false}) {
    final source = excludeLast && _messages.isNotEmpty
        ? _messages.sublist(0, _messages.length - 1)
        : List<ChatMessage>.from(_messages);
    final recent = source.length > 8 ? source.sublist(source.length - 8) : source;
    return recent
        .where((m) => m.text.trim().isNotEmpty)
        .map(
          (m) => {
            'role': m.sender == MessageSender.user ? 'user' : 'assistant',
            'text': m.text.length > 200 ? m.text.substring(0, 200) : m.text,
          },
        )
        .toList();
  }

  Future<void> _sendToAgent(String text, {required bool addUserMessage}) async {
    if (addUserMessage) {
      _addUserMessage(text);
    }
    isSending = true;
    _cancelToken = CancelToken();
    notifyListeners();
    if (addUserMessage) {
      unawaited(_saveMessage(MessageSender.user, text).catchError((_) {}));
    }

    try {
      final response = await _agentChatService.sendMessageStreaming(
        text,
        sessionId: sessionId,
        userId: (await _authSessionService.currentSession())?.userId,
        tripId: tripId,
        context: {
          'entry': 'home_companion',
          'surface': 'avatar_home',
          'recentMessages': _recentMessagesContext(excludeLast: true),
          if (_queuedMessage != null) 'queuedSupplement': _queuedMessage,
        },
        cancelToken: _cancelToken,
        onStage: (stage) {
          sendingStageLabel = stage.label;
          notifyListeners();
        },
      );
      latestAgentResponse.value = response;
      avatarState = response.avatarState;
      memoryCandidateCount = response.memoryCandidates.length;
      final tripPlanCard = agentCardPayload(response, 'tripPlan');
      _addAssistantMessage(
        response.replyText,
        avatarState: response.avatarState,
        tripPlanCard: tripPlanCard,
      );
      isSending = false;
      notifyListeners();
      unawaited(
        _saveMessage(
          MessageSender.assistant,
          response.replyText,
          avatarState: response.avatarState,
          tripPlanCard: tripPlanCard,
        ).catchError((_) {}),
      );
    } on AgentChatCancelledException {
      return;
    } catch (_) {
      const fallbackText = '后端暂时连不上，我先用离线模式陪你继续规划。';
      avatarState = AvatarState.thinking;
      _addAssistantMessage(fallbackText, avatarState: avatarState);
      isSending = false;
      notifyListeners();
      _setStatus('后端暂时连不上，已显示离线回复');
      unawaited(
        _saveMessage(
          MessageSender.assistant,
          fallbackText,
          avatarState: avatarState,
        ).catchError((_) {}),
      );
    } finally {
      isSending = false;
      sendingStageLabel = null;
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

  void _addAssistantMessage(
    String text, {
    AvatarState? avatarState,
    Map<String, dynamic>? tripPlanCard,
  }) {
    _messages.add(
      ChatMessage(
        id: 'home-assistant-${DateTime.now().microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        text: text,
        time: _timeText(),
        avatarState: avatarState ?? AvatarState.hello,
        tripPlanCard: tripPlanCard,
      ),
    );
  }

  Future<void> _saveMessage(
    MessageSender sender,
    String text, {
    AvatarState? avatarState,
    Map<String, dynamic>? tripPlanCard,
  }) async {
    await _chatHistoryService?.saveMessage(
      sessionId: sessionId,
      sender: sender,
      text: text,
      avatarState: avatarState,
      tripPlanCard: tripPlanCard,
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
