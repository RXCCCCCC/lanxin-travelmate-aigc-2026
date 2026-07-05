import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/avatar_states.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../data/local/app_database.dart' hide AvatarState, ChatMessage;
import '../../shared/models/travelmate_models.dart';
import '../../shared/widgets/glass_box.dart';
import '../chat/data/chat_history_service.dart';
import '../chat/widgets/trip_chat_history_sheet.dart';
import 'data/home_chat_controller.dart';
import 'data/home_weather_service.dart';
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
  static final AppDatabase _homeDatabase = AppDatabase();
  static final ChatHistoryService _homeHistoryService = ChatHistoryService(
    _homeDatabase,
  );
  static final HomeChatController _homeChatController = HomeChatController(
    chatHistoryService: _homeHistoryService,
  );

  late final AnimationController _floatCtrl;
  late final TripDashboardService _dashboardService;
  late final HomeWeatherService _weatherService;
  final _chatController = TextEditingController();
  final _chatFocusNode = FocusNode();
  final _panelScrollController = ScrollController();
  _HomeDashboardSummary _dashboardSummary = const _HomeDashboardSummary();
  HomeWeatherSummary _weatherSummary = HomeWeatherSummary.idle;
  AvatarState _avatarState = AvatarState.hello;
  bool _showHeroAvatar = false;
  bool _isPureMode = false;
  bool _statusExpanded = false;
  double _panelHeightRatio = 0.30;

  @override
  void initState() {
    super.initState();
    _avatarState = _homeChatController.avatarState;
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
    _dashboardService = widget.dashboardService ?? TripDashboardService();
    _weatherService = HomeWeatherService();
    _homeChatController.addListener(_handleHomeChatChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showHeroAvatar = true);
      Future<void>.delayed(
        const Duration(milliseconds: 600),
        _loadDashboardSummary,
      );
      Future<void>.delayed(
        const Duration(milliseconds: 900),
        _loadCurrentWeather,
      );
    });
  }

  Future<void> _ensureInitialSession() async {
    await _homeChatController.bindInitialSession();
  }

  Future<void> _loadDashboardSummary() async {
    final dashboard = await _dashboardService.fetchDashboard();
    if (!mounted) return;
    setState(
      () => _dashboardSummary = _HomeDashboardSummary.fromDashboard(dashboard),
    );
  }

  Future<void> _loadCurrentWeather() async {
    if (!mounted) return;
    setState(() => _weatherSummary = HomeWeatherSummary.loading);
    final weather = await _weatherService.fetchCurrentWeather();
    if (!mounted) return;
    setState(() => _weatherSummary = weather);
  }

  void _handleHomeChatChanged() {
    if (!mounted) return;
    final status = _homeChatController.statusMessage;
    setState(() {
      _avatarState = _homeChatController.avatarState;
    });
    if (status != null && status.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _homeChatController.clearStatus();
    }
    _scrollPanelToBottom();
  }

  @override
  void dispose() {
    _homeChatController.removeListener(_handleHomeChatChanged);
    _floatCtrl.dispose();
    _chatController.dispose();
    _chatFocusNode.dispose();
    _panelScrollController.dispose();
    super.dispose();
  }

  Future<void> _sendHomeMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    await _homeChatController.send(text);
    _scrollPanelToBottom();
  }

  Future<void> _showChatHistorySheet() async {
    await _ensureInitialSession();
    final groups = await _homeHistoryService.listGroupedSessions(
      userId: 'guest',
      includeEmptySessionId: _homeChatController.sessionId,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF06224E).withOpacity(0.28),
      builder: (sheetContext) => TripChatHistorySheet(
        groups: groups,
        currentSessionId: _homeChatController.sessionId,
        onNewSession: () async {
          final sessionId = await _homeHistoryService.createSession(
            userId: 'guest',
          );
          if (!mounted) return;
          _homeChatController.switchSession(
            nextSessionId: sessionId,
            nextTripId: 'home-trip-${DateTime.now().millisecondsSinceEpoch}',
          );
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
        onSelectSession: (session) async {
          final loaded = await _homeHistoryService.loadMessages(
            session.sessionId,
          );
          if (!mounted) return;
          _homeChatController.switchSession(
            nextSessionId: session.sessionId,
            nextTripId:
                session.tripId ??
                'home-trip-${DateTime.now().millisecondsSinceEpoch}',
          );
          _homeChatController.replaceMessages(
            loaded.isEmpty ? [_welcomeMessage()] : loaded,
          );
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          _scrollPanelToBottom();
        },
        onOpenPureMode: (session) {
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          final tripId = session.tripId ?? _homeChatController.tripId;
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

  Future<void> _togglePureMode() async {
    setState(() => _isPureMode = !_isPureMode);
    if (!_isPureMode) {
      FocusScope.of(context).unfocus();
    }
    unawaited(_ensureInitialSession());
  }

  void _resizeChatPanel(double delta, double viewportHeight) {
    if (viewportHeight <= 0) return;
    setState(() {
      _panelHeightRatio = (_panelHeightRatio - delta / viewportHeight).clamp(
        0.16,
        0.72,
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
            final weatherTop = topSafe + 2;
            final controlsLeft = 8.0;
            final controlWidth = compact ? 154.0 : 162.0;
            final actionsTop = topSafe + 36;
            final tripTop = topSafe + 82;
            final purePanelTop = topSafe + 128;
            final statusDrawerTop = tripTop + 18;
            final companionPanelTopLimit = statusDrawerTop + 140;
            final minPanelHeight = compact ? 166.0 : 178.0;
            final maxPanelHeight = math.max(
              minPanelHeight,
              h -
                  (_isPureMode ? purePanelTop : companionPanelTopLimit) -
                  10 -
                  keyboardInset,
            );
            final ratio = _panelHeightRatio;
            final panelHeight = (h * ratio)
                .clamp(minPanelHeight, maxPanelHeight)
                .toDouble();
            final effectivePanelHeight = keyboardVisible
                ? math.min(panelHeight, compact ? 230.0 : 240.0)
                : panelHeight;
            final avatarHeight = h * (compact ? 0.54 : 0.62);
            final avatarBottom = compact ? 46.0 : 58.0;

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

                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      opacity: _isPureMode ? 0.10 : 0,
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),

                // ── 顶部天气长条 ──
                Positioned(
                  top: weatherTop,
                  left: 4,
                  right: 4,
                  child: _WeatherStrip(
                    summary: _weatherSummary,
                    onTap: _loadCurrentWeather,
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
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        opacity: _isPureMode ? 0 : 1,
                        child: child!,
                      ),
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
                  top: tripTop,
                  left: controlsLeft,
                  child: _TripPill(
                    label: _dashboardSummary.tripLabel,
                    width: controlWidth,
                    onTap: () => context.go('/trip'),
                  ),
                ),

                // ── 记忆气泡浮在蓝小心左侧 ──
                if (_dashboardSummary.memoryCount > 0 && !_isPureMode)
                  Positioned(
                    top: h * 0.38,
                    left: sidePadding + 6,
                    child: _MemoryFloatBadge(
                      count: _dashboardSummary.memoryCount,
                    ),
                  ),

                // ── 右侧蓝小心状态抽屉 ──
                Positioned(
                  top: statusDrawerTop,
                  right: 0,
                  child: _ModeExitBubble(
                    hidden: _isPureMode,
                    direction: AxisDirection.right,
                    child: _StatusDrawer(
                      expanded: _statusExpanded,
                      onToggle: () =>
                          setState(() => _statusExpanded = !_statusExpanded),
                    ),
                  ),
                ),

                // ── 底部磨砂玻璃聊天面板（~37%）──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  right: 0,
                  top: _isPureMode ? purePanelTop : null,
                  bottom: keyboardInset,
                  height: _isPureMode ? null : effectivePanelHeight,
                  child: _ChatGlassPanel(
                    controller: _chatController,
                    focusNode: _chatFocusNode,
                    scrollController: _panelScrollController,
                    messages: _homeChatController.messages,
                    isSending: _homeChatController.isSending,
                    queuedMessage: _homeChatController.queuedMessage,
                    memoryCandidateCount:
                        _homeChatController.memoryCandidateCount,
                    onSend: _sendHomeMessage,
                    onStop: () => _homeChatController.stop(),
                    onFocusInput: () => _chatFocusNode.requestFocus(),
                    onResize: (delta) => _resizeChatPanel(delta, h),
                    onOpenTrip: () => context.go('/trip'),
                    onOpenMemory: () => context.go('/memory'),
                    onOpenReview: () => context.go('/review'),
                  ),
                ),

                // ── 顶部主操作。放在最后，保证触控优先级最高。 ──
                Positioned(
                  top: actionsTop,
                  left: controlsLeft,
                  child: _PureModeButton(
                    isPureMode: _isPureMode,
                    onTap: _togglePureMode,
                    compact: compact,
                    width: controlWidth,
                  ),
                ),
                Positioned(
                  top: actionsTop,
                  right: sidePadding + 60,
                  child: _TopIconPill(
                    icon: Icons.notifications_none_rounded,
                    label: '消息',
                    onTap: () => context.push('/reminder'),
                  ),
                ),
                Positioned(
                  top: actionsTop,
                  right: sidePadding,
                  child: _TopIconPill(
                    icon: Icons.history_rounded,
                    label: '聊天历史',
                    onTap: _showChatHistorySheet,
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

class _PureModeButton extends StatelessWidget {
  const _PureModeButton({
    required this.isPureMode,
    required this.onTap,
    required this.compact,
    required this.width,
  });

  final bool isPureMode;
  final VoidCallback onTap;
  final bool compact;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        constraints: BoxConstraints(minHeight: 39),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 11,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.34),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.78), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF215ECA).withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPureMode
                  ? Icons.auto_awesome_motion_rounded
                  : Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF215ECA),
              size: 18,
            ),
            const SizedBox(width: 5),
            Text(
              isPureMode ? '切换到陪伴模式' : '切换到纯净模式',
              style: const TextStyle(
                color: Color(0xFF174C9F),
                fontWeight: FontWeight.w900,
                fontSize: 12.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconPill extends StatelessWidget {
  const _TopIconPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: GlassBox(
                width: 44,
                borderRadius: BorderRadius.circular(22),
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeExitBubble extends StatelessWidget {
  const _ModeExitBubble({
    required this.hidden,
    required this.direction,
    required this.child,
  });

  final bool hidden;
  final AxisDirection direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final offset = switch (direction) {
      AxisDirection.left => const Offset(-1.35, 0),
      AxisDirection.right => const Offset(1.35, 0),
      AxisDirection.up => const Offset(0, -1.0),
      AxisDirection.down => const Offset(0, 1.0),
    };
    return IgnorePointer(
      ignoring: hidden,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        offset: hidden ? offset : Offset.zero,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          opacity: hidden ? 0 : 1,
          child: child,
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
  const _TripPill({
    required this.label,
    required this.width,
    required this.onTap,
  });

  final String label;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '当前旅程',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: GlassBox(
          width: width,
          borderRadius: BorderRadius.circular(22),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF5F9BFF),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF2B5BA9),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.4,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF326BCA),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherStrip extends StatelessWidget {
  const _WeatherStrip({required this.summary, required this.onTap});

  final HomeWeatherSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLoading = summary.state == HomeWeatherState.loading;
    final location = (summary.city == null || summary.city!.isEmpty)
        ? summary.title
        : summary.city!;
    final weather = (summary.condition == null || summary.condition!.isEmpty)
        ? (isLoading ? '定位中' : '天气')
        : summary.condition!;
    final weatherIcon = _weatherIconFor(weather, summary.state);
    final temperature = summary.temperatureC == null
        ? '--°C'
        : '${summary.temperatureC}°C';
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: GlassBox(
        height: 30,
        borderRadius: BorderRadius.circular(15),
        opacity: 0.20,
        borderColor: Colors.white.withOpacity(0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF174C9F),
                  fontWeight: FontWeight.w900,
                  fontSize: 12.4,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(weatherIcon, color: Colors.white, size: 15),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        weather,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF174C9F),
                          fontWeight: FontWeight.w900,
                          fontSize: 12.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Text(
                temperature,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF174C9F),
                  fontWeight: FontWeight.w900,
                  fontSize: 12.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _weatherIconFor(String condition, HomeWeatherState state) {
    if (state == HomeWeatherState.loading) return Icons.my_location_rounded;
    if (state == HomeWeatherState.failure) return Icons.cloud_off_rounded;
    if (condition.contains('雨')) return Icons.water_drop_rounded;
    if (condition.contains('雪')) return Icons.ac_unit_rounded;
    if (condition.contains('晴')) return Icons.wb_sunny_rounded;
    if (condition.contains('阴')) return Icons.cloud_rounded;
    if (condition.contains('云')) return Icons.wb_cloudy_rounded;
    return Icons.cloud_queue_rounded;
  }
}

class _StatusDrawer extends StatelessWidget {
  const _StatusDrawer({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 124,
          child: GlassBox(
            height: 54,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(24),
            ),
            opacity: 0.22,
            borderColor: Colors.white.withOpacity(0.70),
            padding: EdgeInsets.zero,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 3),
                child: Icon(
                  Icons.keyboard_arrow_left_rounded,
                  color: Color(0xFF215ECA),
                  size: 19,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 124,
        child: GlassBox(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(24),
          ),
          opacity: 0.27,
          borderColor: Colors.white.withOpacity(0.74),
          padding: const EdgeInsets.fromLTRB(22, 9, 8, 9),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: -20,
                child: const Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: Color(0xFF215ECA),
                  size: 19,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: const Column(
                  key: ValueKey('status-panel'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusMetric(
                      icon: Icons.favorite_rounded,
                      label: '默契',
                      value: '12',
                      color: Color(0xFFFF8CCF),
                    ),
                    SizedBox(height: 9),
                    _StatusMetric(
                      icon: Icons.mood_rounded,
                      label: '心情',
                      value: '开心',
                      color: Color(0xFFFFDA7D),
                    ),
                    SizedBox(height: 9),
                    _StatusMetric(
                      icon: Icons.bolt_rounded,
                      label: '精力',
                      value: '90',
                      color: Color(0xFFFFD953),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF42699E),
            fontSize: 11.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF175BC4),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MemoryFloatBadge extends StatelessWidget {
  const _MemoryFloatBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(20),
      opacity: 0.26,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bubble_chart_rounded,
            color: Color(0xFF215ECA),
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            '$count 条记忆',
            style: const TextStyle(
              color: Color(0xFF174C9F),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
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
    required this.queuedMessage,
    required this.memoryCandidateCount,
    required this.onSend,
    required this.onStop,
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
  final String? queuedMessage;
  final int memoryCandidateCount;
  final VoidCallback onSend;
  final VoidCallback onStop;
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
    final itemCount = visibleMessages.length + (isSending ? 1 : 0);
    return GlassBox(
      borderRadius: BorderRadius.circular(30),
      padding: EdgeInsets.fromLTRB(
        metrics.isCompactPhone ? 7 : 9,
        6,
        metrics.isCompactPhone ? 7 : 9,
        5,
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
              height: 18,
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
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: EdgeInsets.zero,
              itemCount: itemCount,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, index) {
                if (index >= visibleMessages.length) {
                  return _ThinkingBubble(
                    queuedMessage: queuedMessage,
                    avatarPath: AvatarState.thinking.assetPath,
                  );
                }
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
          const SizedBox(height: 3),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onFocusInput,
            child: GlassBox(
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
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
                        hintText: isSending ? '可继续补充信息...' : '在首页直接告诉蓝小心...',
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
                    width: 36,
                    height: 36,
                    child: IconButton(
                      onPressed: onSend,
                      tooltip: isSending ? '追加信息' : '发送',
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isSending ? Icons.add_rounded : Icons.send_rounded,
                        color: const Color(0xFF215ECA),
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSending) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    queuedMessage == null
                        ? '正在调用真实 Agent，可停止或补充信息'
                        : '补充信息会进入下一轮思考',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5F7EA8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop_circle_rounded, size: 16),
                  label: const Text('停止'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF215ECA),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 3),
          SizedBox(
            height: 30,
            child: Row(
              children: [
                Expanded(
                  child: _QuickChip(
                    icon: Icons.route_rounded,
                    label: '规划路线',
                    onTap: onOpenTrip,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _QuickChip(
                    icon: Icons.bubble_chart_rounded,
                    label: '记忆胶囊',
                    onTap: onOpenMemory,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _QuickChip(
                    icon: Icons.tune_rounded,
                    label: '调整行程',
                    onTap: onOpenTrip,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _QuickChip(
                    icon: Icons.auto_stories_rounded,
                    label: '生成复盘',
                    onTap: onOpenReview,
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
      330.0,
      MediaQuery.sizeOf(context).width - 76,
    );
    if (isUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            fit: FlexFit.loose,
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
          const SizedBox(width: 6),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF5C8DFF), Color(0xFF9BC7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.62)),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 17,
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
        Flexible(
          fit: FlexFit.loose,
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

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble({
    required this.queuedMessage,
    required this.avatarPath,
  });

  final String? queuedMessage;
  final String avatarPath;

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble> {
  Timer? _timer;
  int _dotCount = 3;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (!mounted) return;
      setState(() => _dotCount = _dotCount >= 6 ? 1 : _dotCount + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = math.min(
      330.0,
      MediaQuery.sizeOf(context).width - 76,
    );
    final dots = List.filled(_dotCount, '.').join();
    final text = widget.queuedMessage == null
        ? '正在思考中$dots'
        : '已收到补充，继续思考中$dots';
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
            child: Image.asset(
              widget.avatarPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.smart_toy,
                size: 18,
                color: Color(0xFF4C8DFF),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          fit: FlexFit.loose,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.40),
                  Colors.white.withOpacity(0.24),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.48),
                width: 0.8,
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF06224E),
                fontSize: 13,
                height: 1.32,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.24),
              Colors.white.withOpacity(0.13),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 0.8),
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
    );
  }
}
