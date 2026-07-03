import 'package:flutter/material.dart';
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
import 'data/voice_interaction_service.dart';

/// 聊天页面
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.agentChatService,
    this.memoryRepository,
    this.voiceInteractionService,
  });

  final AgentChatService? agentChatService;
  final MemoryRepository? memoryRepository;
  final VoiceInteractionService? voiceInteractionService;

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
      text: '你好，我是蓝小心。告诉我你的目的地、时间和偏好，我会结合真实画像与后端 Agent 帮你规划。',
      time: '现在',
      avatarState: AvatarState.hello,
    ),
  ];
  late final AgentChatService _agentChatService;
  late final MemoryRepository _memoryRepository;
  late final VoiceInteractionService _voiceInteractionService;
  AppDatabase? _ownedDatabase;
  List<MemoryCandidate> _pendingMemoryCandidates = [];
  Map<String, dynamic>? _memoryConflictSuggestion;
  String? _memoryStatusText;
  String? _voiceNotice;
  bool _isListening = false;
  bool _isSending = false;
  late final String _sessionId;
  late final String _tripId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().millisecondsSinceEpoch;
    _sessionId = 'chat-session-$now';
    _tripId = 'chat-trip-$now';
    _agentChatService = widget.agentChatService ?? AgentChatService();
    _voiceInteractionService =
        widget.voiceInteractionService ?? VoiceInteractionService();
    if (widget.memoryRepository == null) {
      _ownedDatabase = AppDatabase();
      _memoryRepository = MemoryRepository(_ownedDatabase!);
    } else {
      _memoryRepository = widget.memoryRepository!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _ownedDatabase?.close();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() {
      _isSending = true;
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: MessageSender.user,
          text: text,
          time: TimeOfDay.now().format(context),
        ),
      );
    });
    _controller.clear();
    final response = await _agentChatService.sendMessage(
      text,
      sessionId: _sessionId,
      userId: 'guest',
      tripId: _tripId,
    );
    if (!mounted) return;
    latestAgentResponse.value = response;
    setState(() {
      _isSending = false;
      _pendingMemoryCandidates = response.memoryCandidates;
      _memoryConflictSuggestion = _firstSyncSuggestion(
        response.syncSuggestions,
        'memoryConflict',
      );
      _memoryStatusText = null;
      _messages.add(
        ChatMessage(
          id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
          sender: MessageSender.assistant,
          text: response.replyText,
          time: TimeOfDay.now().format(context),
          avatarState: response.avatarState,
        ),
      );
    });
    _scrollToBottom();
    final voiceText =
        response.voiceText.trim().isNotEmpty
            ? response.voiceText
            : response.replyText;
    final spoken = await _voiceInteractionService.speak(voiceText);
    if (!mounted) return;
    setState(() {
      _voiceNotice =
          spoken
              ? null
              : (_voiceInteractionService.lastFailureMessage ??
                  '系统语音播报暂不可用，已保留文字回复');
    });
  }

  Future<void> _listenAndFillInput() async {
    if (_isListening || _isSending) return;
    setState(() {
      _isListening = true;
      _voiceNotice = null;
    });
    final text = await _voiceInteractionService.listenOnce();
    if (!mounted) return;
    setState(() {
      _isListening = false;
      if (text == null || text.isEmpty) {
        _voiceNotice =
            _voiceInteractionService.lastFailureMessage ??
            '未识别到语音内容，请确认麦克风权限或使用文字输入';
        return;
      }
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
      _voiceNotice = '已填入语音识别文本，可编辑后发送';
    });
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
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Image.asset(
                          AvatarState.hello.assetPath,
                          width: 28,
                          height: 28,
                          errorBuilder:
                              (_, __, ___) => const Icon(
                                Icons.smart_toy_rounded,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '蓝小心',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '在线',
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
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => ChatBubble(message: _messages[i]),
                  ),
                ),
                if (_pendingMemoryCandidates.isNotEmpty ||
                    _memoryStatusText != null)
                  _MemoryCandidatePanel(
                    count: _pendingMemoryCandidates.length,
                    candidates: _pendingMemoryCandidates,
                    statusText: _memoryStatusText,
                    onConfirm:
                        _pendingMemoryCandidates.isEmpty
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
                      children: [
                        _QuickChip(
                          label: '规划路线',
                          onTap: () => context.push('/trip'),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        _QuickChip(
                          label: '记忆胶囊',
                          onTap: () => context.push('/memory'),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        _QuickChip(
                          label: '调整行程',
                          onTap: () => context.push('/trip'),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        _QuickChip(
                          label: '生成复盘',
                          onTap: () => context.push('/review'),
                        ),
                      ],
                    ),
                  ),
                ),
                // 输入栏
                if (_voiceNotice != null)
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
                          Icons.volume_up_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _voiceNotice!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
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
                              onPressed:
                                  _isListening || _isSending
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
    final sensitiveCount =
        candidates
            .where((candidate) => candidate.sensitivity == 'sensitive')
            .length;
    final personalCount =
        candidates
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
