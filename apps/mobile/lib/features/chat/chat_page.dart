import 'package:flutter/material.dart';
import 'dart:async';

import 'package:go_router/go_router.dart';
import '../../core/constants/avatar_states.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/router/navigation_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/agent_response_cache.dart';
import '../../data/local/app_database.dart' hide AvatarState, ChatMessage;
import '../../data/repositories/memory_repository.dart';
import '../../shared/widgets/chat_bubble.dart';
import '../../shared/models/travelmate_models.dart';
import '../../shared/widgets/glass_box.dart';
import 'data/agent_chat_models.dart';
import 'data/agent_chat_service.dart';
import 'data/chat_history_service.dart';
import 'data/voice_interaction_service.dart';

/// 聊天页面
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.agentChatService,
    this.memoryRepository,
    this.voiceInteractionService,
    this.sessionId,
    this.tripId,
  });

  final AgentChatService? agentChatService;
  final MemoryRepository? memoryRepository;
  final VoiceInteractionService? voiceInteractionService;
  final String? sessionId;
  final String? tripId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[
    const ChatMessage(
      id: 'welcome',
      sender: MessageSender.assistant,
      text: '你好，我是蓝小心。告诉我你的目的地、时间和偏好，我会结合你的旅行画像帮你规划。',
      time: '现在',
      avatarState: AvatarState.hello,
    ),
  ];
  late final AgentChatService _agentChatService;
  late final MemoryRepository _memoryRepository;
  late final VoiceInteractionService _voiceInteractionService;
  late final ChatHistoryService _chatHistoryService;
  late final AppDatabase _historyDatabase;
  AppDatabase? _ownedDatabase;
  List<MemoryCandidate> _pendingMemoryCandidates = [];
  Map<String, dynamic>? _memoryConflictSuggestion;
  String? _memoryStatusText;
  String? _statusNotice;
  DateTime? _statusNoticeTime;
  static const _statusNoticeDuration = Duration(seconds: 4);

  bool _isListening = false;
  bool _isSending = false;
  String? _retryText;
  List<Map<String, dynamic>> _nextActions = [];
  String? _sendingStageLabel;
  late String _sessionId;
  late String _tripId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().millisecondsSinceEpoch;
    _sessionId = widget.sessionId ?? 'chat-session-$now';
    _tripId = widget.tripId ?? 'chat-trip-$now';
    _agentChatService = widget.agentChatService ?? AgentChatService();
    _voiceInteractionService =
        widget.voiceInteractionService ?? VoiceInteractionService();
    if (widget.memoryRepository == null) {
      _ownedDatabase = AppDatabase.shared();
      _memoryRepository = MemoryRepository(_ownedDatabase!);
      _historyDatabase = _ownedDatabase!;
    } else {
      _memoryRepository = widget.memoryRepository!;
      _historyDatabase = _memoryRepository.database;
    }
    _chatHistoryService = ChatHistoryService(_historyDatabase);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingSession();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSession() async {
    if (widget.sessionId == null) return;
    final messages = await _chatHistoryService.loadMessages(_sessionId);
    if (!mounted || messages.isEmpty) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(messages);
    });
    _scrollToBottom();
  }

  void _showStatusNotice(String text, {bool important = false}) {
    setState(() {
      _statusNotice = text;
      _statusNoticeTime = DateTime.now();
    });
    if (!important) {
      Future.delayed(_statusNoticeDuration, () {
        if (!mounted) return;
        if (_statusNoticeTime != null &&
            DateTime.now().difference(_statusNoticeTime!) >= _statusNoticeDuration) {
          setState(() => _statusNotice = null);
        }
      });
    }
  }

  void _handleNextAction(Map<String, dynamic> action) {
    final type = action['type']?.toString() ?? '';
    switch (type) {
      case 'openTripPlan':
        context.go('/trip');
      case 'openReview':
        context.go('/review');
      case 'confirmMemory':
        context.push('/memory');
      case 'simulateReminder':
        context.push('/reminder');
      case 'openPhoto':
        context.push('/photo');
      case 'suggestedQuestion':
        final label = action['label']?.toString() ?? '';
        if (label.isNotEmpty) {
          _controller.text = label;
          _controller.selection =
              TextSelection.collapsed(offset: label.length);
        }
      default:
        break;
    }
  }

  static String _quickChipLabel(Map<String, dynamic> action) {
    final label = action['label']?.toString().trim() ?? '';
    if (label.length <= 12) return label;
    return '${label.substring(0, 12)}...';
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();
    await _sendText(text);
  }

  Future<void> _retryLastMessage() async {
    final text = _retryText;
    if (text == null || _isSending) return;
    setState(() {
      _retryText = null;
      _statusNotice = null;
      // 移除上一条离线兜底回复，重试成功后展示真实回复
      if (_messages.isNotEmpty &&
          _messages.last.sender == MessageSender.assistant) {
        _messages.removeLast();
      }
    });
    await _sendText(text, isRetry: true);
  }

  Future<void> _sendText(String text, {bool isRetry = false}) async {
    setState(() {
      _isSending = true;
      _statusNotice = null;
      _retryText = null;
      if (!isRetry) {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: MessageSender.user,
            text: text,
            time: TimeOfDay.now().format(context),
          ),
        );
      }
    });
    AgentChatResponse? response;
    try {
      if (!isRetry) {
        unawaited(
          _chatHistoryService
              .saveMessage(
                sessionId: _sessionId,
                sender: MessageSender.user,
                text: text,
              )
              .catchError((_) {
                if (mounted) {
                  _showStatusNotice('本地聊天记录暂存失败，但消息已继续发送');
                }
              }),
        );
      }
      response = await _agentChatService.sendMessageStreaming(
        text,
        sessionId: _sessionId,
        tripId: _tripId,
        context: {'recentMessages': _recentMessagesContext(excludeLast: true)},
        onStage: (stage) {
          if (!mounted) return;
          setState(() => _sendingStageLabel = stage.label);
        },
      );
    } catch (_) {
      response = AgentChatResponse.fallback(
        '后端暂时连不上，我先用离线模式陪你继续聊。USB 真机请确认 adb reverse，云真机请配置公网 API 地址。',
      );
    }
    if (!mounted) return;
    final resolvedResponse = response;
    latestAgentResponse.value = resolvedResponse;
    final memoryCandidates = resolvedResponse.memoryCandidates.isNotEmpty
        ? resolvedResponse.memoryCandidates
        : _fallbackMemoryCandidatesFromText(text);
    setState(() {
      _pendingMemoryCandidates = memoryCandidates;
      _memoryConflictSuggestion = _firstSyncSuggestion(
        resolvedResponse.syncSuggestions,
        'memoryConflict',
      );
      _memoryStatusText = null;
      _nextActions = resolvedResponse.nextActions;
      _messages.add(
        ChatMessage(
          id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
          sender: MessageSender.assistant,
          text: resolvedResponse.replyText,
          time: TimeOfDay.now().format(context),
          avatarState: resolvedResponse.avatarState,
        ),
      );
      _isSending = false;
      _statusNotice = null;
      _sendingStageLabel = null;
    });
    if (resolvedResponse.errors.any((error) => error['code'] == 'NETWORK_FALLBACK')) {
      setState(() => _retryText = text);
      _showStatusNotice('离线兜底：请检查后端连接后重试', important: true);
    }
    unawaited(
      _chatHistoryService
          .saveMessage(
            sessionId: _sessionId,
            sender: MessageSender.assistant,
            text: resolvedResponse.replyText,
            avatarState: resolvedResponse.avatarState,
          )
          .catchError((_) {
            if (mounted) {
              _showStatusNotice('回复已显示，本地聊天记录暂存失败');
            }
          }),
    );
    _scrollToBottom();
    final voiceText = resolvedResponse.voiceText.trim().isNotEmpty
        ? resolvedResponse.voiceText
        : resolvedResponse.replyText;
    final spoken = await _voiceInteractionService.speak(voiceText);
    if (!mounted) return;
    if (!spoken) {
      _showStatusNotice(
        _voiceInteractionService.lastFailureMessage ?? '系统语音播报暂不可用，已保留文字回复',
      );
    }
  }

  Future<void> _listenAndFillInput() async {
    if (_isListening || _isSending) return;
    setState(() {
      _isListening = true;
      _statusNotice = null;
    });
    final text = await _voiceInteractionService.listenOnce();
    if (!mounted) return;
    setState(() {
      _isListening = false;
      if (text != null && text.isNotEmpty) {
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
      }
    });
    if (text == null || text.isEmpty) {
      _showStatusNotice(
        _voiceInteractionService.lastFailureMessage ?? '未识别到语音内容，请确认麦克风权限或使用文字输入',
      );
    } else {
      _showStatusNotice('已填入语音识别文本，可编辑后发送');
    }
  }

  Map<String, dynamic>? _firstSyncSuggestion(
    List<Map<String, dynamic>> suggestions,
    String type,
  ) {
    for (final suggestion in suggestions) {
      if (suggestion['type'] == type) return suggestion;
    }
    return null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmMemoryCandidates() async {
    final candidates = List<MemoryCandidate>.from(_pendingMemoryCandidates);
    for (final candidate in candidates) {
      await _memoryRepository.saveCandidate(
        candidate,
        scope: candidate.recommendedScope,
      );
    }
    if (!mounted) return;
    setState(() {
      _pendingMemoryCandidates = [];
      _memoryStatusText = '已保存 ${candidates.length} 条记忆胶囊';
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final inputBottom = metrics.safeInsets.bottom + 8;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5FA4FF), Color(0xFFAAD6FF), Color(0xFFE8F7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: AdaptiveContentWidth(
            child: Column(
              children: [
                // 顶部栏
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.horizontalPadding - 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => navigateBackOrHome(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: ClipOval(
                          child: Image.asset(
                            AvatarState.hello.assetPath,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            cacheWidth: 132,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.face_rounded,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '蓝小心纯净模式',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '专注查看完整对话',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 聊天消息列表
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: metrics.cardGap),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (_, i) => i < _messages.length
                        ? ChatBubble(message: _messages[i])
                        : _TypingIndicatorBubble(stageLabel: _sendingStageLabel),
                  ),
                ),
                if (_pendingMemoryCandidates.isNotEmpty ||
                    _memoryStatusText != null)
                  _MemoryCandidatePanel(
                    count: _pendingMemoryCandidates.length,
                    candidates: _pendingMemoryCandidates,
                    statusText: _memoryStatusText,
                    onConfirm: _pendingMemoryCandidates.isEmpty
                        ? null
                        : _confirmMemoryCandidates,
                  ),
                if (_memoryConflictSuggestion != null)
                  _MemoryConflictPanel(suggestion: _memoryConflictSuggestion!),
                // 快捷操作
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.horizontalPadding,
                    vertical: metrics.cardGap,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _nextActions.isNotEmpty
                          ? [
                              for (final action in _nextActions) ...[
                                _QuickChip(
                                  label: _quickChipLabel(action),
                                  onTap: () => _handleNextAction(action),
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                              ],
                            ]
                          : [
                              _QuickChip(
                                label: '规划路线',
                                onTap: () => context.go('/trip'),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              _QuickChip(
                                label: '记忆胶囊',
                                onTap: () => context.push('/memory'),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              _QuickChip(
                                label: '调整行程',
                                onTap: () => context.go('/trip'),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              _QuickChip(
                                label: '生成复盘',
                                onTap: () => context.go('/review'),
                              ),
                            ],
                    ),
                  ),
                ),
                // 输入栏
                if (_statusNotice != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      metrics.horizontalPadding,
                      0,
                      metrics.horizontalPadding,
                      AppTheme.spacingXs,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _statusNotice!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_retryText != null && !_isSending)
                          TextButton.icon(
                            onPressed: _retryLastMessage,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: const Size(0, 28),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                            label: const Text(
                              '重试',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: keyboardInset),
                  child: GlassBox(
                    margin: EdgeInsets.fromLTRB(
                      metrics.horizontalPadding,
                      0,
                      metrics.horizontalPadding,
                      inputBottom,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: metrics.minTouchTarget,
                          height: metrics.minTouchTarget,
                          child: Tooltip(
                            message: '语音输入',
                            child: IconButton(
                              onPressed: _isListening || _isSending
                                  ? null
                                  : _listenAndFillInput,
                              icon: Icon(
                                _isListening
                                    ? Icons.more_horiz_rounded
                                    : Icons.mic_rounded,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: '和蓝小心说点什么...',
                              hintStyle: TextStyle(
                                color: AppTheme.textMuted.withOpacity(0.6),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        GestureDetector(
                          onTap: _isSending ? null : _send,
                          child: Container(
                            width: metrics.minTouchTarget,
                            height: metrics.minTouchTarget,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),
                            child: Icon(
                              _isSending
                                  ? Icons.more_horiz_rounded
                                  : Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryCandidatePanel extends StatelessWidget {
  const _MemoryCandidatePanel({
    required this.count,
    required this.candidates,
    required this.statusText,
    required this.onConfirm,
  });

  final int count;
  final List<MemoryCandidate> candidates;
  final String? statusText;
  final Future<void> Function()? onConfirm;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final sensitiveCount = candidates
        .where((candidate) => candidate.sensitivity == 'sensitive')
        .length;
    final personalCount = candidates
        .where((candidate) => candidate.sensitivity == 'personal')
        .length;
    final requiresExplicitConsent = candidates.any(
      (candidate) => candidate.requiresExplicitConsent,
    );
    final privacyText = _memoryPrivacyText(
      sensitiveCount: sensitiveCount,
      personalCount: personalCount,
      requiresExplicitConsent: requiresExplicitConsent,
    );
    return GlassBox(
      margin: EdgeInsets.fromLTRB(
        metrics.horizontalPadding,
        4,
        metrics.horizontalPadding,
        2,
      ),
      opacity: 0.2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.bubble_chart_rounded,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText ?? '发现 $count 条记忆候选',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (privacyText != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    privacyText,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onConfirm != null)
            GestureDetector(
              onTap: onConfirm,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: metrics.minTouchTarget - 4,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Text(
                  '确认记忆胶囊',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

List<MemoryCandidate> _fallbackMemoryCandidatesFromText(String text) {
  final candidates = <MemoryCandidate>[];
  if (text.contains('香菜')) {
    candidates.add(
      const MemoryCandidate(
        id: 'local-mem-cilantro',
        title: '不吃香菜',
        content: '用户明确表示不吃香菜，后续餐厅和菜品推荐需要避开。',
        category: 'dietary_preference',
        sensitivity: 'personal',
        requiresExplicitConsent: true,
        scopeOptions: ['longTerm', 'currentTrip', 'temporary', 'ignore'],
        recommendedScope: 'longTerm',
        reason: '饮食忌口会长期影响餐饮推荐，但需要用户明确确认后保存。',
      ),
    );
  }
  if (text.contains('轻松') || text.contains('慢游') || text.contains('慢一点') || text.contains('不想太累')) {
    candidates.add(
      const MemoryCandidate(
        id: 'local-mem-slow-pace',
        title: '本次旅行想轻松一点',
        content: '用户希望低强度、轻松慢游，规划时减少密集景点和跨区移动。',
        scopeOptions: ['currentTrip', 'temporary', 'ignore'],
        recommendedScope: 'currentTrip',
        reason: '这是本次旅行的节奏约束，适合先按本次行程保存。',
      ),
    );
  }
  return candidates;
}

String? _memoryPrivacyText({
  required int sensitiveCount,
  required int personalCount,
  required bool requiresExplicitConsent,
}) {
  if (!requiresExplicitConsent && sensitiveCount == 0 && personalCount == 0) {
    return null;
  }
  final parts = <String>[];
  if (sensitiveCount > 0) parts.add('$sensitiveCount 条敏感信息');
  if (personalCount > 0) parts.add('$personalCount 条个人偏好');
  final prefix = parts.isEmpty ? '这些候选' : parts.join('、');
  return '$prefix 需要你显式确认保存范围。';
}

class _MemoryConflictPanel extends StatelessWidget {
  const _MemoryConflictPanel({required this.suggestion});

  final Map<String, dynamic> suggestion;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return GlassBox(
      margin: EdgeInsets.fromLTRB(
        metrics.horizontalPadding,
        4,
        metrics.horizontalPadding,
        2,
      ),
      opacity: 0.22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.compare_arrows_rounded,
            color: AppTheme.accent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion['title']?.toString() ?? '发现记忆变化',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  suggestion['description']?.toString() ??
                      '蓝小心会先按本次行程处理，长期画像等待你确认。',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return GestureDetector(
      onTap: onTap,
      child: GlassBox(
        opacity: 0.18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: metrics.minTouchTarget - 16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble({this.stageLabel});

  final String? stageLabel;

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: ClipOval(
              child: Image.asset(
                AvatarState.thinking.assetPath,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                cacheWidth: 96,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.face_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          GlassBox(
            opacity: 0.18,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusLg),
              topRight: Radius.circular(AppTheme.radiusLg),
              bottomLeft: Radius.circular(AppTheme.spacingSm),
              bottomRight: Radius.circular(AppTheme.radiusLg),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final dots = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final phase = (_controller.value * 3 - index).clamp(0.0, 1.0);
                    final opacity =
                        0.25 + 0.75 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Opacity(
                        opacity: opacity,
                        child: const CircleAvatar(
                          radius: 3.5,
                          backgroundColor: AppTheme.primary,
                        ),
                      ),
                    );
                  }),
                );
                final label = widget.stageLabel;
                if (label == null || label.isEmpty) return dots;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    dots,
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
