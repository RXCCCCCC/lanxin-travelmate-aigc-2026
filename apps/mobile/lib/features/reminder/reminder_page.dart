import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/demo_agent_state.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/glass_box.dart';
import '../../shared/widgets/reminder_card.dart';
import 'data/reminder_trigger_service.dart';

/// 主动提醒页面
class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key, this.reminderTriggerService});

  final ReminderTriggerService? reminderTriggerService;

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  late final ReminderTriggerService _reminderTriggerService;
  List<Map<String, dynamic>> _simulatedReminders = const [];

  @override
  void initState() {
    super.initState();
    _reminderTriggerService = widget.reminderTriggerService ?? ReminderTriggerService();
  }

  Future<void> _simulateTrigger(String triggerType, Map<String, dynamic> eventPayload) async {
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
        final agentReminders = agentCardPayloadList(response, 'reminders');
        final activeAgentReminders = _simulatedReminders.isNotEmpty ? _simulatedReminders : agentReminders;
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
            // 顶部栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                  ),
                  const Expanded(
                    child: Text('主动提醒', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spacingLg, 4, AppTheme.spacingLg, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _TriggerChip(label: '拍照触发', onTap: () => _simulateTrigger('behavior', {'event': 'newPhoto'})),
                  const SizedBox(width: AppTheme.spacingSm),
                  _TriggerChip(label: '状态触发', onTap: () => _simulateTrigger('status', {'energy': 32})),
                  const SizedBox(width: AppTheme.spacingSm),
                  _TriggerChip(label: '天气触发', onTap: () => _simulateTrigger('external', {'event': 'weatherChanged'})),
                ]),
              ),
            ),
            // 提醒列表
            Expanded(
              child: activeAgentReminders.isEmpty
                  ? ListView.builder(
                padding: const EdgeInsets.only(top: AppTheme.spacingSm, bottom: AppTheme.spacingXl),
                itemCount: mockReminders.length,
                itemBuilder: (_, i) => ReminderCard(reminder: mockReminders[i]),
              )
                  : ListView(
                padding: const EdgeInsets.only(top: AppTheme.spacingSm, bottom: AppTheme.spacingXl),
                children: activeAgentReminders.map((reminder) => _AgentReminderCard(reminder: reminder)).toList(),
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

class _TriggerChip extends StatelessWidget {
  const _TriggerChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassBox(
        opacity: 0.18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _AgentReminderCard extends StatelessWidget {
  const _AgentReminderCard({required this.reminder});
  final Map<String, dynamic> reminder;

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingSm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(reminder['title']?.toString() ?? '主动提醒', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('触发：${reminder['triggerType'] ?? 'context'} · 冷却 ${reminder['cooldownMinutes'] ?? 60} 分钟',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ]),
          ),
        ]),
        const SizedBox(height: AppTheme.spacingMd),
        Text(reminder['description']?.toString() ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4)),
      ]),
    );
  }
}
