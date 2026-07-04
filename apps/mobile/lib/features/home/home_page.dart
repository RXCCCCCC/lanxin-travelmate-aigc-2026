import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/avatar_states.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../data/agent_response_cache.dart';
import '../../data/local/app_database.dart' hide AvatarState, ChatMessage;
import '../../shared/models/travelmate_models.dart';
import '../../shared/widgets/glass_box.dart';
import '../chat/data/agent_chat_service.dart';
import '../chat/data/chat_history_service.dart';
import '../chat/widgets/trip_chat_history_sheet.dart';
import '../trip/data/trip_dashboard_service.dart';

/// 首页 — 完全复刻参考图
/// 上方 65%：天空渐变背景 + 蓝小心立绘浮动 + 浮动状态卡 + 品牌/天气/旅行胶囊
/// 下方 35%：磨砂玻璃聊天面板 + 输入栏 + 快捷指令
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.dashboardService});

  final TripDashboardService? dashboardService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final TripDashboardService _dashboardService;
  late final AgentChatService _agentChatService;
  late final AppDatabase _database;
  late final ChatHistoryService _chatHistoryService;
  final _chatController = TextEditingController();
  final _chatFocusNode = FocusNode();
  final _panelScrollController = ScrollController();
  final _messages = <ChatMessage>[
    const ChatMessage(
      id: 'home-welcome',
      sender: MessageSender.assistant,
      text: '告诉我目的地、时间和偏好，我在首页直接陪你规划。',
      time: '现在',
      avatarState: AvatarState.hello,
    ),
  ];
  _HomeDashboardSummary _dashboardSummary = const _HomeDashboardSummary();
  AvatarState _avatarState = AvatarState.hello;
  bool _showHeroAvatar = false;
  bool _isSending = false;
  int _memoryCandidateCount = 0;
  double _panelHeightRatio = 0.37;
  late String _sessionId;
  late String _tripId;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
    _dashboardService = widget.dashboardService ?? TripDashboardService();
    _agentChatService = AgentChatService();
    _database = AppDatabase();
    _chatHistoryService = ChatHistoryService(_database);
    final now = DateTime.now().millisecondsSinceEpoch;
    _sessionId = 'home-session-$now';
    _tripId = 'home-trip-$now';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showHeroAvatar = true);
      Future<void>.delayed(
        const Duration(milliseconds: 600),
        _loadDashboardSummary,
      );
    });
  }

  Future<void> _ensureInitialSession() async {
    await _chatHistoryService.bindSessionToTrip(
      sessionId: _sessionId,
      tripTitle: '未绑定行程',
      tripId: _tripId,
    );
  }

  Future<void> _loadDashboardSummary() async {
    final dashboard = await _dashboardService.fetchDashboard();
    if (!mounted) return;
    setState(
      () => _dashboardSummary = _HomeDashboardSummary.fromDashboard(dashboard),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _chatController.dispose();
    _chatFocusNode.dispose();
    _panelScrollController.dispose();
    _database.close();
    super.dispose();
  }

  Future<void> _sendHomeMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() {
      _isSending = true;
      _messages.add(
        ChatMessage(
          id: 'home-user-${DateTime.now().millisecondsSinceEpoch}',
          sender: MessageSender.user,
          text: text,
          time: TimeOfDay.now().format(context),
        ),
      );
    });
    _chatController.clear();
    await _chatHistoryService.saveMessage(
      sessionId: _sessionId,
      sender: MessageSender.user,
      text: text,
    );
    _scrollPanelToBottom();

    final response = await _agentChatService.sendMessage(
      text,
      sessionId: _sessionId,
      userId: 'guest',
      tripId: _tripId,
      context: {'entry': 'home_companion', 'surface': 'avatar_home'},
    );
    if (!mounted) return;
    latestAgentResponse.value = response;
    setState(() {
      _isSending = false;
      _avatarState = response.avatarState;
      _memoryCandidateCount = response.memoryCandidates.length;
      _messages.add(
        ChatMessage(
          id: 'home-assistant-${DateTime.now().millisecondsSinceEpoch}',
          sender: MessageSender.assistant,
          text: response.replyText,
          time: TimeOfDay.now().format(context),
          avatarState: response.avatarState,
        ),
      );
    });
    await _chatHistoryService.saveMessage(
      sessionId: _sessionId,
      sender: MessageSender.assistant,
      text: response.replyText,
      avatarState: response.avatarState,
    );
    _scrollPanelToBottom();
  }

  Future<void> _showChatHistorySheet() async {
    await _ensureInitialSession();
    final groups = await _chatHistoryService.listGroupedSessions(
      userId: 'guest',
      includeEmptySessionId: _sessionId,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF06224E).withOpacity(0.28),
      builder: (sheetContext) => TripChatHistorySheet(
        groups: groups,
        currentSessionId: _sessionId,
        onNewSession: () async {
          final sessionId = await _chatHistoryService.createSession(
            userId: 'guest',
          );
          if (!mounted) return;
          setState(() {
            _sessionId = sessionId;
            _tripId = 'home-trip-${DateTime.now().millisecondsSinceEpoch}';
            _messages
              ..clear()
              ..add(_welcomeMessage());
            _memoryCandidateCount = 0;
            _avatarState = AvatarState.hello;
          });
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
        onSelectSession: (session) async {
          final loaded = await _chatHistoryService.loadMessages(
            session.sessionId,
          );
          if (!mounted) return;
          setState(() {
            _sessionId = session.sessionId;
            _tripId =
                session.tripId ??
                'home-trip-${DateTime.now().millisecondsSinceEpoch}';
            _messages
              ..clear()
              ..addAll(loaded.isEmpty ? [_welcomeMessage()] : loaded);
            _avatarState =
                _messages.last.avatarState ??
                (loaded.isEmpty ? AvatarState.hello : _avatarState);
          });
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          _scrollPanelToBottom();
        },
        onOpenPureMode: (session) {
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          final tripId = session.tripId ?? _tripId;
          context.push('/chat?sessionId=${session.sessionId}&tripId=$tripId');
        },
      ),
    );
  }

  ChatMessage _welcomeMessage() {
    return const ChatMessage(
      id: 'home-welcome',
      sender: MessageSender.assistant,
      text: '告诉我目的地、时间和偏好，我在首页直接陪你规划。',
      time: '现在',
      avatarState: AvatarState.hello,
    );
  }

  Future<void> _openPureMode() async {
    await _ensureInitialSession();
    if (!mounted) return;
    context.push('/chat?sessionId=$_sessionId&tripId=$_tripId');
  }

  void _resizeChatPanel(double delta, double viewportHeight) {
    if (viewportHeight <= 0) return;
    setState(() {
      _panelHeightRatio = (_panelHeightRatio - delta / viewportHeight).clamp(
        0.32,
        0.62,
      );
    });
  }

  void _scrollPanelToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_panelScrollController.hasClients) return;
      _panelScrollController.animateTo(
        _panelScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, c) {
            final metrics = context.responsive;
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            final keyboardVisible = keyboardInset > 0;
            final viewportHeight = c.maxHeight;
            final h = metrics.isLandscape
                ? math.max(viewportHeight, 700.0)
                : viewportHeight;
            final topSafe = metrics.safeInsets.top;
            final sidePadding = metrics.horizontalPadding;
            final compact = metrics.isCompactPhone || metrics.hasLargeText;
            final ratio = math.max(_panelHeightRatio, compact ? 0.38 : 0.36);
            final panelHeight = (h * ratio)
                .clamp(250.0, compact ? 430.0 : 520.0)
                .toDouble();
            final effectivePanelHeight = keyboardVisible
                ? math.min(panelHeight, compact ? 250.0 : 250.0)
                : panelHeight;
            final avatarHeight = h * (compact ? 0.46 : 0.54);
            final avatarBottom = effectivePanelHeight * (compact ? 0.28 : 0.34);

            final content = Stack(
              children: [
                // ── 天空渐变背景 ──
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF5FA4FF),
                          Color(0xFF89C2FF),
                          Color(0xFFB8DEFF),
                          Color(0xFFDCEEFF),
                          Color(0xFFE8F7FF),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.2, 0.45, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── 品牌标题（左上）──
                Positioned(
                  top: topSafe + 8,
                  left: sidePadding,
                  child: _BrandBlock(compact: compact),
                ),

                // ── 联调状态 + 消息（右上）──
                Positioned(
                  top: topSafe + 8,
                  right: sidePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _showChatHistorySheet,
                        child: _IntegrationButton(
                          compact: compact,
                          label: '聊天历史',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!compact) const _NoticePill(),
                    ],
                  ),
                ),

                // ── 模式切换（顶部中间）──
                Positioned(
                  top: topSafe + 66,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _PureModeButton(
                      onTap: () {
                        _openPureMode();
                      },
                    ),
                  ),
                ),

                // ── 蓝小心立绘（中央浮动，占 ~58% 高度）──
                AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (context, child) {
                    final t = math.sin(_floatCtrl.value * math.pi * 2);
                    return Positioned(
                      bottom: avatarBottom + t * 6,
                      left: -8,
                      right: -8,
                      height: avatarHeight,
                      child: child!,
                    );
                  },
                  child: IgnorePointer(
                    child: _showHeroAvatar
                        ? Image.asset(
                            _avatarState.assetPath,
                            fit: BoxFit.contain,
                            cacheWidth: 720,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.person,
                                size: 120,
                                color: Color(0xFF4C8DFF),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.person,
                              size: 120,
                              color: Color(0xFF4C8DFF),
                            ),
                          ),
                  ),
                ),

                // ── 旅行胶囊 ──
                Positioned(
                  top: topSafe + 82,
                  left: sidePadding,
                  child: _TripPill(label: _dashboardSummary.tripLabel),
                ),

                // ── 天气卡片 ──
                Positioned(
                  top: topSafe + 146,
                  left: sidePadding,
                  child: const _WeatherCard(),
                ),

                // ── 右侧浮动状态卡 ──
                if (compact) ...[
                  Positioned(
                    top: topSafe + 150,
                    right: sidePadding,
                    child: _FloatingStatusColumn(
                      spacing: 12,
                      children: [
                        const _CompactStatusBadge(),
                        _DashboardSummaryBadge(summary: _dashboardSummary),
                      ],
                    ),
                  ),
                ] else ...[
                  Positioned(
                    top: topSafe + 188,
                    right: sidePadding,
                    child: _FloatingStatusColumn(
                      spacing: 15,
                      children: [
                        const _AffinityCard(),
                        const _MoodEnergyCard(),
                        const _PlanningBadge(),
                      ],
                    ),
                  ),
                ],

                // ── 底部磨砂玻璃聊天面板（~37%）──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  left: sidePadding,
                  right: sidePadding,
                  bottom: 10 + keyboardInset,
                  height: effectivePanelHeight,
                  child: _ChatGlassPanel(
                    controller: _chatController,
                    focusNode: _chatFocusNode,
                    scrollController: _panelScrollController,
                    messages: _messages,
                    isSending: _isSending,
                    memoryCandidateCount: _memoryCandidateCount,
                    onSend: _sendHomeMessage,
                    onFocusInput: () => _chatFocusNode.requestFocus(),
                    onResize: (delta) => _resizeChatPanel(delta, h),
                    onOpenTrip: () => context.go('/trip'),
                    onOpenMemory: () => context.go('/memory'),
                    onOpenReview: () => context.go('/review'),
                  ),
                ),
              ],
            );
            if (!metrics.isLandscape) return content;
            return SingleChildScrollView(
              child: SizedBox(height: h, child: content),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 子组件
// ══════════════════════════════════════════════════════════

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 168 : 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFF124EBC), Color(0xFF2D72E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(r),
            child: Text(
              '蓝小心',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 27 : 32,
                fontWeight: FontWeight.w900,
                height: 0.92,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '全旅程智能伙伴',
            style: TextStyle(
              color: const Color(0xFF1B4FAD).withOpacity(0.90),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PureModeButton extends StatelessWidget {
  const _PureModeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.34),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.72), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF215ECA).withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fullscreen_rounded, color: Color(0xFF215ECA), size: 17),
            SizedBox(width: 5),
            Text(
              '纯净模式',
              style: TextStyle(
                color: Color(0xFF174C9F),
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDashboardSummary {
  const _HomeDashboardSummary({
    this.tripLabel = '等待真实旅程',
    this.memoryCount = 0,
    this.reminderCount = 0,
  });

  final String tripLabel;
  final int memoryCount;
  final int reminderCount;

  factory _HomeDashboardSummary.fromDashboard(TripDashboardPayload dashboard) {
    final destination = dashboard.currentTrip['destination']?.toString().trim();
    return _HomeDashboardSummary(
      tripLabel: destination == null || destination.isEmpty
          ? '当前旅程'
          : '$destination 旅程',
      memoryCount: dashboard.memories.length,
      reminderCount: dashboard.reminderHistory.fold<int>(0, (count, history) {
        final items = history['items'];
        return count + (items is List ? items.length : 1);
      }),
    );
  }

  String get summaryLine {
    if (memoryCount == 0 && reminderCount == 0) return '等待真实旅程数据';
    return '$memoryCount 条记忆 · $reminderCount 条提醒';
  }
}

class _TripPill extends StatelessWidget {
  const _TripPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: Color(0xFF5F9BFF),
            size: 19,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2B5BA9),
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF326BCA),
            size: 19,
          ),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      width: 132,
      opacity: 0.24,
      borderColor: Colors.white.withOpacity(0.72),
      padding: const EdgeInsets.fromLTRB(13, 11, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_rounded,
                color: Color(0xFFFFFFFF),
                size: 20,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    '等待天气',
                    style: TextStyle(
                      color: Color(0xFF175BC4),
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFFDF73),
                size: 14,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '等待工具数据',
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFF245EB8),
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntegrationButton extends StatelessWidget {
  const _IntegrationButton({this.compact = false, this.label = '真实联调'});
  final bool compact;
  final String label;
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(25),
      padding: EdgeInsets.fromLTRB(compact ? 10 : 12, 8, compact ? 10 : 12, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
          if (!compact) const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          if (!compact) const SizedBox(width: 4),
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 17),
        ],
      ),
    );
  }
}

class _NoticePill extends StatelessWidget {
  const _NoticePill();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, color: Colors.white, size: 17),
          SizedBox(width: 6),
          Text(
            '消息',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingStatusColumn extends StatelessWidget {
  const _FloatingStatusColumn({required this.children, this.spacing = 12});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          children[i],
        ],
      ],
    );
  }
}

class _AffinityCard extends StatelessWidget {
  const _AffinityCard();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      width: 126,
      opacity: 0.26,
      borderColor: Colors.white.withOpacity(0.74),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.favorite_rounded, color: Color(0xFFFF8CCF), size: 18),
              SizedBox(width: 7),
              Text(
                '默契值',
                style: TextStyle(
                  color: Color(0xFF173F91),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                '12',
                style: TextStyle(
                  color: Color(0xFF175BC4),
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.sync_rounded,
                color: const Color(0xFF4C83D9).withOpacity(0.65),
                size: 17,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 4.5,
              value: 0.42,
              backgroundColor: Colors.white.withOpacity(0.20),
              color: const Color(0xFF6F98FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodEnergyCard extends StatelessWidget {
  const _MoodEnergyCard();
  @override
  Widget build(BuildContext context) {
    final ls = TextStyle(
      color: const Color(0xFF42699E),
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
    );
    const vs = TextStyle(
      color: Color(0xFF175BC4),
      fontSize: 16,
      fontWeight: FontWeight.w900,
    );

    return GlassBox(
      width: 126,
      opacity: 0.26,
      borderColor: Colors.white.withOpacity(0.74),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.mood_rounded,
                color: Color(0xFFFFDA7D),
                size: 17,
              ),
              const SizedBox(width: 6),
              Text('心情', style: ls),
              const Spacer(),
              const Text('开心', style: vs),
            ],
          ),
          const SizedBox(height: 9),
          Divider(height: 1, color: const Color(0xFF5B8CDA).withOpacity(0.22)),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFFFD953),
                size: 17,
              ),
              const SizedBox(width: 6),
              Text('精力', style: ls),
              const Spacer(),
              const Text('90', style: vs),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactStatusBadge extends StatelessWidget {
  const _CompactStatusBadge();

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(22),
      opacity: 0.25,
      borderColor: Colors.white.withOpacity(0.72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: Color(0xFFFF8CCF), size: 16),
          SizedBox(width: 5),
          Text(
            '默契 12',
            style: TextStyle(
              color: Color(0xFF175BC4),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.bolt_rounded, color: Color(0xFFFFD953), size: 16),
          SizedBox(width: 5),
          Text(
            '精力 90',
            style: TextStyle(
              color: Color(0xFF175BC4),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSummaryBadge extends StatelessWidget {
  const _DashboardSummaryBadge({required this.summary});

  final _HomeDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(18),
      opacity: 0.25,
      borderColor: Colors.white.withOpacity(0.72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Text(
        summary.summaryLine,
        style: const TextStyle(
          color: Color(0xFF245EB8),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PlanningBadge extends StatelessWidget {
  const _PlanningBadge();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(18),
      opacity: 0.25,
      borderColor: Colors.white.withOpacity(0.72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '等待真实行程',
            style: const TextStyle(
              color: Color(0xFF245EB8),
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.graphic_eq_rounded,
            color: Color(0xFFA6D9FF),
            size: 15,
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _MemoryCapsuleBadge extends StatelessWidget {
  const _MemoryCapsuleBadge({required this.summary});

  final _HomeDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      showGlow: true,
      glowColor: const Color(0xFF4A9FFF),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6FB3FF), Color(0xFF4A8DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A8DFF).withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '记忆胶囊同步',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '由真实数据更新 ›',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 10.5,
                ),
              ),
              Text(
                summary.summaryLine,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 底部磨砂玻璃聊天面板
// ══════════════════════════════════════════════════════════

class _ChatGlassPanel extends StatelessWidget {
  const _ChatGlassPanel({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.messages,
    required this.isSending,
    required this.memoryCandidateCount,
    required this.onSend,
    required this.onFocusInput,
    required this.onResize,
    required this.onOpenTrip,
    required this.onOpenMemory,
    required this.onOpenReview,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final bool isSending;
  final int memoryCandidateCount;
  final VoidCallback onSend;
  final VoidCallback onFocusInput;
  final ValueChanged<double> onResize;
  final VoidCallback onOpenTrip;
  final VoidCallback onOpenMemory;
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final visibleMessages = messages.length <= 2
        ? messages
        : messages.sublist(messages.length - 2);
    return GlassBox(
      borderRadius: BorderRadius.circular(30),
      padding: EdgeInsets.fromLTRB(
        metrics.isCompactPhone ? 12 : 16,
        metrics.isCompactPhone ? 12 : 14,
        metrics.isCompactPhone ? 12 : 16,
        10,
      ),
      opacity: 0.20,
      blur: 30.0,
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) => onResize(details.delta.dy),
            onVerticalDragUpdate: (details) => onResize(details.delta.dy),
            child: SizedBox(
              height: 32,
              width: double.infinity,
              child: Center(
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D8ED6).withOpacity(0.88),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.48),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.forum_rounded,
                color: Color(0xFF215ECA),
                size: 18,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '和蓝小心直接聊',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF06224E),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (memoryCandidateCount > 0)
                _TinySignal(label: '$memoryCandidateCount 条记忆'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: EdgeInsets.zero,
              itemCount: visibleMessages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final message = visibleMessages[index];
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _ChatBubble(
                    key: ValueKey(message.id),
                    isUser: message.sender == MessageSender.user,
                    text: message.text,
                    avatarPath:
                        (message.avatarState ?? AvatarState.hello).assetPath,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onFocusInput,
            child: GlassBox(
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              opacity: 0.12,
              blur: 16,
              child: Row(
                children: [
                  const Icon(
                    Icons.mic_rounded,
                    color: Color(0xFF5F8FBF),
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 2,
                      textInputAction: TextInputAction.send,
                      onTap: onFocusInput,
                      onSubmitted: (_) => onSend(),
                      style: const TextStyle(
                        color: Color(0xFF06224E),
                        fontSize: 14,
                        height: 1.25,
                      ),
                      decoration: InputDecoration(
                        hintText: isSending ? '蓝小心正在思考...' : '在首页直接告诉蓝小心...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF7B98B8),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: isSending ? null : onSend,
                      tooltip: '发送',
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isSending
                            ? Icons.more_horiz_rounded
                            : Icons.send_rounded,
                        color: const Color(0xFF215ECA),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _QuickChip(
                icon: Icons.route_rounded,
                label: '规划路线',
                onTap: onOpenTrip,
              ),
              const SizedBox(width: 6),
              _QuickChip(
                icon: Icons.bubble_chart_rounded,
                label: '记忆胶囊',
                onTap: onOpenMemory,
              ),
              const SizedBox(width: 6),
              _QuickChip(
                icon: Icons.tune_rounded,
                label: '调整行程',
                onTap: onOpenTrip,
              ),
              const SizedBox(width: 6),
              _QuickChip(
                icon: Icons.auto_stories_rounded,
                label: '生成复盘',
                onTap: onOpenReview,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    super.key,
    required this.isUser,
    required this.text,
    this.avatarPath,
  });
  final bool isUser;
  final String text;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = math.min(
      252.0,
      MediaQuery.sizeOf(context).width - 112,
    );
    if (isUser) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Spacer(),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4C8DFF).withOpacity(0.75),
                    const Color(0xFF6FA8FF).withOpacity(0.65),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.30),
                  width: 0.8,
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.32,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
          ),
          child: ClipOval(
            child: avatarPath != null
                ? Image.asset(
                    avatarPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.smart_toy,
                      size: 18,
                      color: Color(0xFF4C8DFF),
                    ),
                  )
                : const Icon(
                    Icons.smart_toy,
                    size: 18,
                    color: Color(0xFF4C8DFF),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.35),
                  Colors.white.withOpacity(0.22),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 0.8,
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF06224E),
                fontSize: 13,
                height: 1.32,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TinySignal extends StatelessWidget {
  const _TinySignal({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.32), width: 0.8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF215ECA),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.24),
                Colors.white.withOpacity(0.13),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 0.8,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: const Color(0xFF4A7FCC)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF2B5BA9),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
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
