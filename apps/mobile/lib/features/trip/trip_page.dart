import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/demo_agent_state.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/glass_box.dart';
import '../../shared/widgets/trip_plan_card.dart';

/// 出行规划页面
class TripPage extends StatelessWidget {
  const TripPage({super.key});

  @override
  Widget build(BuildContext context) {
    final plan = mockTripPlan;

    return ValueListenableBuilder(
      valueListenable: latestAgentResponse,
      builder: (context, response, _) {
        final metrics = context.responsive;
        final agentPlan = agentCardPayload(response, 'tripPlan');
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
                          '出行规划',
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
                // 内容
                Expanded(
                  child: agentPlan == null
                      ? ListView(
                          padding: EdgeInsets.only(
                            bottom: metrics.listBottomPadding,
                          ),
                          children: [
                            // 当前行程信息卡
                            GlassBox(
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(
                                            0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          '当前行程',
                                          style: TextStyle(
                                            color: AppTheme.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingSm),
                                  Text(
                                    plan.title,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingXs),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14,
                                        color: AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        plan.dateRange,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spacingLg),
                                      const Icon(
                                        Icons.place_rounded,
                                        size: 14,
                                        color: AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        plan.destination,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // 每日行程时间线
                            ...plan.days.map(
                              (day) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      16,
                                      24,
                                      8,
                                    ),
                                    child: Text(
                                      day.dayLabel,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  ...List.generate(
                                    day.items.length,
                                    (i) => TripPlanCard(
                                      item: day.items[i],
                                      index: i,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 风险提示
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '风险提示',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...plan.risks.map(
                              (risk) => GlassBox(
                                margin: EdgeInsets.symmetric(
                                  horizontal: metrics.horizontalPadding,
                                  vertical: AppTheme.spacingXs,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingLg,
                                  vertical: AppTheme.spacingMd,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: AppTheme.spacingSm),
                                    Expanded(
                                      child: Text(
                                        risk,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : _AgentTripPlanView(plan: agentPlan),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AgentTripPlanView extends StatelessWidget {
  const _AgentTripPlanView({required this.plan});

  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final days = (plan['days'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final risks = (plan['risks'] as List<dynamic>? ?? const []).map(
      (e) => e.toString(),
    );
    final matches = (plan['profileMatches'] as List<dynamic>? ?? const []).map(
      (e) => e.toString(),
    );
    final alternatives = (plan['alternatives'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final navigationLinks =
        (plan['navigationLinks'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
    final adjustment = plan['dynamicAdjustment'] as Map<String, dynamic>?;

    return ListView(
      padding: EdgeInsets.only(bottom: metrics.listBottomPadding),
      children: [
        GlassBox(
          margin: EdgeInsets.symmetric(
            horizontal: metrics.horizontalPadding,
            vertical: AppTheme.spacingSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agent 实时规划',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                plan['title']?.toString() ?? '蓝小心规划',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                '${plan['destination'] ?? '目的地'} · ${plan['dateRange'] ?? '行程时间'}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (matches.isNotEmpty) ...[
          const _SectionHeader(icon: Icons.psychology_rounded, title: '画像匹配解释'),
          ...matches.map(
            (item) =>
                _SimpleInfoCard(text: item, icon: Icons.auto_awesome_rounded),
          ),
        ],
        ...days.map((day) {
          final items = (day['items'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  day['dayLabel']?.toString() ?? '行程日',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...List.generate(
                items.length,
                (index) => _AgentTripItemCard(item: items[index], index: index),
              ),
            ],
          );
        }),
        if (adjustment != null) ...[
          const _SectionHeader(icon: Icons.alt_route_rounded, title: '动态调整'),
          _SimpleInfoCard(
            text: '${adjustment['trigger']}：${adjustment['suggestion']}',
            icon: Icons.sync_rounded,
          ),
        ],
        if (risks.isNotEmpty) ...[
          const _SectionHeader(
            icon: Icons.warning_amber_rounded,
            title: '风险提示',
          ),
          ...risks.map(
            (risk) =>
                _SimpleInfoCard(text: risk, icon: Icons.info_outline_rounded),
          ),
        ],
        if (alternatives.isNotEmpty) ...[
          const _SectionHeader(icon: Icons.swap_calls_rounded, title: '备选方案'),
          ...alternatives.map((item) => _AlternativePlanCard(item: item)),
        ],
        if (navigationLinks.isNotEmpty) ...[
          const _SectionHeader(icon: Icons.navigation_rounded, title: '地图导航'),
          ...navigationLinks.map((item) => _NavigationLinkCard(item: item)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleInfoCard extends StatelessWidget {
  const _SimpleInfoCard({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return GlassBox(
      margin: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: AppTheme.spacingXs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativePlanCard extends StatelessWidget {
  const _AlternativePlanCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return GlassBox(
      margin: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: AppTheme.spacingXs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['title']?.toString() ?? '备选方案',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['summary']?.toString() ?? '',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (item['bestFor'] != null) ...[
            const SizedBox(height: 8),
            Text(
              '适合：${item['bestFor']}',
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavigationLinkCard extends StatelessWidget {
  const _NavigationLinkCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return GlassBox(
      margin: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: AppTheme.spacingXs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['label']?.toString() ?? '打开地图导航',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['url']?.toString() ?? '高德地图跳转链接',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
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

class _AgentTripItemCard extends StatelessWidget {
  const _AgentTripItemCard({required this.item, required this.index});

  final Map<String, dynamic> item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return GlassBox(
      margin: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary.withOpacity(0.15),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['time']?.toString() ?? '',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['location']?.toString() ?? '',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  item['activity']?.toString() ?? '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  '因为：${item['reason'] ?? ''}',
                  style: const TextStyle(color: AppTheme.accent, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
