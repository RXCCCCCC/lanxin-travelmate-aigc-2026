import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/demo_agent_state.dart';
import '../../shared/widgets/glass_box.dart';
import '../profile/data/profile_service.dart';
import '../trip/data/trip_dashboard_service.dart';
import 'data/reminder_trigger_service.dart';

/// 主动提醒页面
class ReminderPage extends StatefulWidget {
  const ReminderPage({
    super.key,
    this.reminderTriggerService,
    this.dashboardService,
    this.profileService,
  });

  final ReminderTriggerService? reminderTriggerService;
  final TripDashboardService? dashboardService;
  final ProfileService? profileService;

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  late final ReminderTriggerService _reminderTriggerService;
  late final TripDashboardService _dashboardService;
  late final ProfileService _profileService;
  ProfilePayload? _profile;
  List<Map<String, dynamic>> _simulatedReminders = const [];
  List<Map<String, dynamic>> _dashboardReminders = const [];
  List<Map<String, dynamic>> _evaluatedReminders = const [];
  String? _suppressedReason;
  int _cooldownRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _reminderTriggerService =
        widget.reminderTriggerService ?? ReminderTriggerService();
    _dashboardService = widget.dashboardService ?? TripDashboardService();
    _profileService = widget.profileService ?? ProfileService();
    _loadDashboardReminders();
    _loadProfileAndEvaluate();
  }

  Future<void> _loadDashboardReminders() async {
    final dashboard = await _dashboardService.fetchDashboard();
    final reminders = <Map<String, dynamic>>[];
    for (final history in dashboard.reminderHistory) {
      final items = history['items'];
      if (items is List) {
        for (final item in items.whereType<Map<String, dynamic>>()) {
          reminders.add({
            'triggerType': history['triggerType'],
            'location': history['location'],
            ...item,
          });
        }
      }
    }
    if (!mounted || reminders.isEmpty) return;
    setState(() => _dashboardReminders = reminders);
  }

  Future<void> _loadProfileAndEvaluate() async {
    final profile = await _profileService.fetchProfile();
    final result = await _reminderTriggerService.evaluate(
      ReminderEvaluateDraft(
        userId: profile.userId,
        proactivityLevel: profile.proactivityLevel,
        currentTime: DateTime.now().toIso8601String(),
        location: '洪崖洞',
        status: {'energy': 32, 'travelPace': profile.travelPace},
        external: {
          'interestTags': profile.interestTags,
          'dietaryPreferences': profile.dietaryPreferences,
          'transportPreferences': profile.transportPreferences,
        },
      ),
    );
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _evaluatedReminders = result.items;
      _suppressedReason = result.suppressedReason;
      _cooldownRemainingSeconds = result.cooldownRemainingSeconds;
    });
  }

  Future<void> _simulateTrigger(
    String triggerType,
    Map<String, dynamic> eventPayload,
  ) async {
    final reminders = await _reminderTriggerService.trigger(
      triggerType,
      location: '洪崖洞',
      eventPayload: eventPayload,
    );
    if (!mounted) return;
    setState(() => _simulatedReminders = reminders);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: latestAgentResponse,
      builder: (context, response, _) {
        final metrics = context.responsive;
        final agentReminders = agentCardPayloadList(response, 'reminders');
        final activeAgentReminders = _simulatedReminders.isNotEmpty
            ? _simulatedReminders
            : (agentReminders.isNotEmpty
                  ? agentReminders
                  : (_dashboardReminders.isNotEmpty
                        ? _dashboardReminders
                        : _evaluatedReminders));
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5FA4FF), Color(0xFFAAD6FF), Color(0xFFE8F7FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.horizontalPadding - 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          '主动提醒',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                if (_profile != null)
                  _ProfileReminderContext(
                    profile: _profile!,
                    suppressedReason: _suppressedReason,
                    cooldownRemainingSeconds: _cooldownRemainingSeconds,
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.horizontalPadding,
                    4,
                    metrics.horizontalPadding,
                    8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TriggerChip(
                          label: '拍照触发',
                          onTap: () => _simulateTrigger('behavior', {
                            'event': 'newPhoto',
                          }),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        _TriggerChip(
                          label: '状态触发',
                          onTap: () =>
                              _simulateTrigger('status', {'energy': 32}),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        _TriggerChip(
                          label: '天气触发',
                          onTap: () => _simulateTrigger('external', {
                            'event': 'weatherChanged',
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: activeAgentReminders.isEmpty
                      ? _EmptyReminderState(onRetry: _loadProfileAndEvaluate)
                      : ListView(
                          padding: EdgeInsets.only(
                            top: AppTheme.spacingSm,
                            bottom: metrics.listBottomPadding,
                          ),
                          children: activeAgentReminders
                              .map(
                                (reminder) =>
                                    _AgentReminderCard(reminder: reminder),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyReminderState extends StatelessWidget {
  const _EmptyReminderState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return ListView(
      padding: EdgeInsets.only(
        left: metrics.horizontalPadding,
        right: metrics.horizontalPadding,
        top: AppTheme.spacingSm,
        bottom: metrics.listBottomPadding,
      ),
      children: [
        GlassBox(
          opacity: 0.18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '暂无主动提醒',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              const Text(
                '当前画像、时间和情境没有触发提醒。你可以使用上方触发按钮走后端评估，也可以稍后重试。',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  key: const ValueKey('reminder-retry-evaluate'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重试评估'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileReminderContext extends StatelessWidget {
  const _ProfileReminderContext({
    required this.profile,
    required this.suppressedReason,
    required this.cooldownRemainingSeconds,
  });

  final ProfilePayload profile;
  final String? suppressedReason;
  final int cooldownRemainingSeconds;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final tags = <String>[
      profile.proactivityLevel,
      profile.travelPace,
      ...profile.interestTags.take(2),
      ...profile.dietaryPreferences.take(1),
    ];
    final status = suppressedReason == 'cooldown'
        ? '冷却 ${cooldownRemainingSeconds ~/ 60} 分钟'
        : '实时评估';
    return GlassBox(
      opacity: 0.2,
      margin: EdgeInsets.fromLTRB(
        metrics.horizontalPadding,
        0,
        metrics.horizontalPadding,
        AppTheme.spacingSm,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 18),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              '画像提醒 · ${tags.join(' / ')} · $status',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriggerChip extends StatelessWidget {
  const _TriggerChip({required this.label, required this.onTap});

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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgentReminderCard extends StatelessWidget {
  const _AgentReminderCard({required this.reminder});
  final Map<String, dynamic> reminder;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return GlassBox(
      margin: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder['title']?.toString() ?? '主动提醒',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '触发：${reminder['triggerType'] ?? 'context'} · 冷却 ${reminder['cooldownMinutes'] ?? 60} 分钟',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            reminder['description']?.toString() ?? '',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
