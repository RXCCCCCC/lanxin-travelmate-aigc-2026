import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/demo_agent_state.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/glass_box.dart';
import '../../shared/widgets/trip_plan_card.dart';
import '../profile/data/profile_service.dart';
import 'data/trip_dashboard_service.dart';
import 'data/trip_plan_service.dart';

/// 出行规划页面
class TripPage extends StatefulWidget {
  const TripPage({
    super.key,
    this.dashboardService,
    this.planService,
    this.profileService,
  });

  final TripDashboardService? dashboardService;
  final TripPlanService? planService;
  final ProfileService? profileService;

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  late final TripDashboardService _dashboardService;
  late final TripPlanService _planService;
  late final ProfileService _profileService;
  final _destinationController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _companionsController = TextEditingController();
  final _preferencesController = TextEditingController();
  Map<String, dynamic>? _dashboardPlan;
  Map<String, dynamic>? _createdPlan;
  ProfilePayload? _profile;
  Map<String, dynamic> _dashboardRoutePoints = const {};
  String _budget = 'medium';
  String _transportMode = 'walking';
  bool _creatingPlan = false;
  String? _planError;

  @override
  void initState() {
    super.initState();
    _dashboardService = widget.dashboardService ?? TripDashboardService();
    _planService = widget.planService ?? TripPlanService();
    _profileService = widget.profileService ?? ProfileService();
    _loadDashboardPlan();
    if (agentCardPayload(latestAgentResponse.value, 'tripPlan') == null) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _companionsController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardPlan() async {
    if (agentCardPayload(latestAgentResponse.value, 'tripPlan') != null) {
      return;
    }
    final dashboard = await _dashboardService.fetchDashboard();
    final currentTrip = dashboard.currentTrip;
    final plan = currentTrip['plan'];
    if (!mounted || plan is! Map<String, dynamic> || plan.isEmpty) return;
    setState(() {
      _dashboardPlan = plan;
      _dashboardRoutePoints = dashboard.routePoints;
    });
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.fetchProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _budget = _normalizeBudget(profile.budgetPreference);
      _transportMode = _normalizeTransport(profile.transportPreferences);
    });
  }

  Future<void> _createPlan({String? replanReason}) async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      setState(() => _planError = '请输入目的地');
      return;
    }
    setState(() {
      _creatingPlan = true;
      _planError = null;
    });
    final result = await _planService.createPlan(
      TripPlanRequestDraft(
        destination: destination,
        startDate: _emptyToNull(_startDateController.text),
        endDate: _emptyToNull(_endDateController.text),
        budget: _budget,
        companions: _splitCsv(_companionsController.text),
        preferences: _combinedPreferences(),
        transportMode: _transportMode,
        tripStyle: 'custom',
        replanReason: replanReason,
        message: 'Create a travel plan for $destination.',
      ),
    );
    if (!mounted) return;
    setState(() {
      _creatingPlan = false;
      if (result.status == 'ok') {
        _createdPlan = result.plan;
      } else {
        _planError = '规划失败，请检查网络后重试';
      }
    });
  }

  List<String> _combinedPreferences() {
    final values = <String>{
      ..._splitCsv(_preferencesController.text),
      if (_profile != null && _profile!.travelPace.trim() != 'light')
        _profile!.travelPace.trim(),
      ...?_profile?.interestTags,
      ...?_profile?.dietaryPreferences,
    };
    return values.where((item) => item.trim().isNotEmpty).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final plan = mockTripPlan;

    return ValueListenableBuilder(
      valueListenable: latestAgentResponse,
      builder: (context, response, _) {
        final metrics = context.responsive;
        final agentPlan = agentCardPayload(response, 'tripPlan');
        final livePlan = agentPlan ?? _createdPlan ?? _dashboardPlan;
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
                  child: livePlan == null
                      ? ListView(
                          padding: EdgeInsets.only(
                            bottom: metrics.listBottomPadding,
                          ),
                          children: [
                            _TripPlanInputCard(
                              destinationController: _destinationController,
                              startDateController: _startDateController,
                              endDateController: _endDateController,
                              companionsController: _companionsController,
                              preferencesController: _preferencesController,
                              budget: _budget,
                              transportMode: _transportMode,
                              loading: _creatingPlan,
                              errorText: _planError,
                              onBudgetChanged: (value) {
                                setState(() => _budget = value);
                              },
                              onTransportChanged: (value) {
                                setState(() => _transportMode = value);
                              },
                              onCreatePlan: _createPlan,
                            ),
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
                      : _AgentTripPlanView(
                          plan: livePlan,
                          onWeatherReplan: _createdPlan == null
                              ? null
                              : () => _createPlan(replanReason: 'weather_risk'),
                          routePoints: agentPlan == null
                              ? _dashboardRoutePoints
                              : const {},
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

class _TripPlanInputCard extends StatelessWidget {
  const _TripPlanInputCard({
    required this.destinationController,
    required this.startDateController,
    required this.endDateController,
    required this.companionsController,
    required this.preferencesController,
    required this.budget,
    required this.transportMode,
    required this.loading,
    required this.onBudgetChanged,
    required this.onTransportChanged,
    required this.onCreatePlan,
    this.errorText,
  });

  final TextEditingController destinationController;
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final TextEditingController companionsController;
  final TextEditingController preferencesController;
  final String budget;
  final String transportMode;
  final bool loading;
  final String? errorText;
  final ValueChanged<String> onBudgetChanged;
  final ValueChanged<String> onTransportChanged;
  final VoidCallback onCreatePlan;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return Material(
      type: MaterialType.transparency,
      child: GlassBox(
        margin: EdgeInsets.symmetric(
          horizontal: metrics.horizontalPadding,
          vertical: AppTheme.spacingSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
            '创建真实行程',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _PlanTextField(
            keyValue: 'trip-destination-input',
            controller: destinationController,
            label: '目的地',
            hint: '例如 Hangzhou',
          ),
          Row(
            children: [
              Expanded(
                child: _PlanTextField(
                  keyValue: 'trip-start-date-input',
                  controller: startDateController,
                  label: '开始日期',
                  hint: '2026-07-01',
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _PlanTextField(
                  keyValue: 'trip-end-date-input',
                  controller: endDateController,
                  label: '结束日期',
                  hint: '2026-07-03',
                ),
              ),
            ],
          ),
          _PlanTextField(
            keyValue: 'trip-companions-input',
            controller: companionsController,
            label: '同行人',
            hint: 'mother, child',
          ),
          _PlanTextField(
            keyValue: 'trip-preferences-input',
            controller: preferencesController,
            label: '偏好',
            hint: 'night view, less walking',
          ),
          _OptionRow(
            label: '预算',
            selected: budget,
            options: const {
              'light': '轻量',
              'medium': '适中',
              'premium': '舒适',
            },
            keyPrefix: 'trip-budget',
            onChanged: onBudgetChanged,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          _OptionRow(
            label: '交通',
            selected: transportMode,
            options: const {
              'walking': '步行',
              'transit': '公交',
              'driving': '驾车',
            },
            keyPrefix: 'trip-transport',
            onChanged: onTransportChanged,
          ),
          if (errorText != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              errorText!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('trip-create-plan-button'),
              onPressed: loading ? null : onCreatePlan,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(loading ? '生成中' : '生成行程'),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _PlanTextField extends StatelessWidget {
  const _PlanTextField({
    required this.keyValue,
    required this.controller,
    required this.label,
    required this.hint,
  });

  final String keyValue;
  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: TextField(
        key: ValueKey(keyValue),
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: Colors.white.withOpacity(0.74),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.options,
    required this.keyPrefix,
    required this.onChanged,
  });

  final String label;
  final String selected;
  final Map<String, String> options;
  final String keyPrefix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            return ChoiceChip(
              key: ValueKey('$keyPrefix-${entry.key}'),
              label: Text(entry.value),
              selected: selected == entry.key,
              onSelected: (_) => onChanged(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _splitCsv(String value) {
  return value
      .split(RegExp(r'[,，]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _normalizeBudget(String value) {
  final normalized = value.trim();
  if (normalized.contains('light') || normalized.contains('轻')) {
    return 'light';
  }
  if (normalized.contains('premium') || normalized.contains('舒')) {
    return 'premium';
  }
  return 'medium';
}

String _normalizeTransport(List<String> values) {
  final joined = values.join(' ').toLowerCase();
  if (joined.contains('driving') || joined.contains('drive') || joined.contains('car')) {
    return 'driving';
  }
  if (joined.contains('transit') || joined.contains('bus') || joined.contains('metro')) {
    return 'transit';
  }
  return 'walking';
}

class _AgentTripPlanView extends StatelessWidget {
  const _AgentTripPlanView({
    required this.plan,
    this.routePoints = const {},
    this.onWeatherReplan,
  });

  final Map<String, dynamic> plan;
  final Map<String, dynamic> routePoints;
  final VoidCallback? onWeatherReplan;

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
        if (onWeatherReplan != null) ...[
          _ReplanActionCard(onWeatherReplan: onWeatherReplan!),
        ],
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
        if (_hasRoutePoints(routePoints)) ...[
          const _SectionHeader(icon: Icons.timeline_rounded, title: '真实轨迹'),
          _RoutePointsCard(routePoints: routePoints),
        ],
      ],
    );
  }
}

bool _hasRoutePoints(Map<String, dynamic> routePoints) {
  final route = routePoints['route']?.toString() ?? '';
  final points = routePoints['points'];
  return route.isNotEmpty || (points is List && points.isNotEmpty);
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

class _ReplanActionCard extends StatelessWidget {
  const _ReplanActionCard({required this.onWeatherReplan});

  final VoidCallback onWeatherReplan;

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
          const Icon(Icons.sync_rounded, color: AppTheme.primary, size: 18),
          const SizedBox(width: AppTheme.spacingSm),
          const Expanded(
            child: Text(
              '根据天气变化重新规划',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            key: const ValueKey('trip-replan-weather-risk'),
            onPressed: onWeatherReplan,
            child: const Text('重规划'),
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

class _RoutePointsCard extends StatelessWidget {
  const _RoutePointsCard({required this.routePoints});

  final Map<String, dynamic> routePoints;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final route = routePoints['route']?.toString() ?? '';
    final points = (routePoints['points'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
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
          if (route.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.route_rounded,
                  size: 17,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    route,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
          ],
          ...List.generate(points.length, (index) {
            final point = points[index];
            final label = point['label']?.toString() ?? '轨迹点 ${index + 1}';
            final time =
                point['time']?.toString() ??
                point['createdAt']?.toString() ??
                '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.primary.withOpacity(0.14),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      time.isEmpty ? label : '$time · $label',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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
