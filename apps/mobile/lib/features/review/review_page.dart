import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/demo_agent_state.dart';
import '../../shared/widgets/glass_box.dart';
import '../../shared/widgets/trip_review_card.dart';
import '../profile/data/profile_service.dart';
import '../trip/data/trip_dashboard_service.dart';
import 'data/trip_review_service.dart';

/// 旅行复盘页面
class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    this.tripReviewService,
    this.dashboardService,
    this.profileService,
  });

  final TripReviewService? tripReviewService;
  final TripDashboardService? dashboardService;
  final ProfileService? profileService;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final TripReviewService _tripReviewService;
  late final TripDashboardService _dashboardService;
  late final ProfileService _profileService;
  late final Future<TripReviewPayload> _generatedReview;
  late final String _localReviewTripId;

  @override
  void initState() {
    super.initState();
    _tripReviewService = widget.tripReviewService ?? TripReviewService();
    _dashboardService = widget.dashboardService ?? TripDashboardService();
    _profileService = widget.profileService ?? ProfileService();
    _localReviewTripId = 'review-trip-${DateTime.now().millisecondsSinceEpoch}';
    _generatedReview = _loadReview();
  }

  Future<TripReviewPayload> _loadReview() async {
    final shouldReadDashboard =
        widget.dashboardService != null || widget.tripReviewService == null;
    String? dashboardTripId;
    if (shouldReadDashboard) {
      final requestedTripId = _tripIdFromAgentResponse();
      final dashboard = await _dashboardService.fetchDashboard(
        tripId: requestedTripId,
      );
      dashboardTripId = _tripIdFromDashboard(dashboard);
      final dashboardReview = _reviewFromDashboard(dashboard.latestReview);
      if (dashboardReview != null) return dashboardReview;
      final dashboardStateReview = _reviewFromDashboardStateEvents(dashboard);
      if (dashboardStateReview != null) return dashboardStateReview;
    }

    final profile = await _profileService.fetchProfile();
    final reviewTripId =
        _tripIdFromAgentResponse() ?? dashboardTripId ?? _localReviewTripId;
    return _tripReviewService.generateReview(
      tripId: reviewTripId,
      completedTasks: const [
        {
          'id': 'task-night-photo',
          'title': '拍一张不是游客照的重庆夜景',
          'status': 'completed',
        },
      ],
      temporaryMemories: const [
        {
          'id': 'mem-slow-pace',
          'title': '本次旅行想轻松一点',
          'content': '本次行程希望低强度，减少跨区移动和密集景点。',
        },
      ],
      profileContext: _reviewProfileContext(profile),
    );
  }

  String? _tripIdFromAgentResponse() {
    final plan = agentCardPayload(latestAgentResponse.value, 'tripPlan');
    return _firstTextValue([
      plan?['tripId'],
      plan?['trip_id'],
      plan?['id'],
      (plan?['planningInputs'] as Map<String, dynamic>?)?['tripId'],
    ]);
  }

  String? _tripIdFromDashboard(TripDashboardPayload dashboard) {
    return _firstTextValue([
      dashboard.tripId,
      dashboard.currentTrip['tripId'],
      dashboard.currentTrip['id'],
    ]);
  }

  String? _firstTextValue(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  TripReviewPayload? _reviewFromDashboard(Map<String, dynamic> latestReview) {
    final review = latestReview['review'];
    if (review is Map<String, dynamic> && review.isNotEmpty) {
      return TripReviewPayload.fromJson(review);
    }
    return null;
  }

  TripReviewPayload? _reviewFromDashboardStateEvents(
    TripDashboardPayload dashboard,
  ) {
    if (dashboard.avatarStateEvents.isEmpty) return null;
    final route = dashboard.routePoints['route']?.toString();
    return TripReviewPayload(
      route: (route == null || route.isEmpty) ? '今日路线' : route,
      highlightPhotos: const [],
      newMemories: const [],
      completedTasks: const [],
      avatarStatusChanges: dashboard.avatarStateEvents
          .map(_avatarStateEventText)
          .where((item) => item.isNotEmpty)
          .toList(),
      nextTripSuggestions: const [],
      temporaryMemoryPromotions: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: latestAgentResponse,
      builder: (context, response, _) {
        final metrics = context.responsive;
        final agentReview = agentCardPayload(response, 'tripReview');
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
                          '旅行复盘',
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
                Expanded(
                  child: agentReview == null
                      ? FutureBuilder<TripReviewPayload>(
                          future: _generatedReview,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return _AgentReviewView(
                                review: snapshot.data!.toJson(),
                              );
                            }
                            if (snapshot.hasError) {
                              return const _ReviewErrorState();
                            }
                            return const _ReviewLoadingState();
                          },
                        )
                      : _AgentReviewView(review: agentReview),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewLoadingState extends StatelessWidget {
  const _ReviewLoadingState();

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
      children: const [
        GlassBox(
          opacity: 0.18,
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '正在聚合真实路线、照片、任务、记忆和蓝小心状态...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewErrorState extends StatelessWidget {
  const _ReviewErrorState();

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
      children: const [
        GlassBox(
          opacity: 0.18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '复盘生成失败。请确认后端服务可用，并且当前旅程已有真实路线、照片、任务或记忆数据。',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgentReviewView extends StatelessWidget {
  const _AgentReviewView({required this.review});
  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final photos = (review['highlightPhotos'] as List<dynamic>? ?? const [])
        .map((e) => e.toString());
    final memories = (review['newMemories'] as List<dynamic>? ?? const []).map(
      (e) => e.toString(),
    );
    final tasks = (review['completedTasks'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final states = (review['avatarStatusChanges'] as List<dynamic>? ?? const [])
        .map((e) => e.toString());
    final suggestions =
        (review['nextTripSuggestions'] as List<dynamic>? ?? const []).map(
          (e) => e.toString(),
        );
    final promotions =
        (review['temporaryMemoryPromotions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();

    return ListView(
      padding: EdgeInsets.only(bottom: metrics.listBottomPadding),
      children: [
        if (_reviewProfileContextText(review).isNotEmpty)
          _ReviewProfileContext(text: _reviewProfileContextText(review)),
        GlassBox(
          margin: EdgeInsets.symmetric(
            horizontal: metrics.horizontalPadding,
            vertical: AppTheme.spacingSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agent 旅行复盘',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                review['route']?.toString() ?? '今日路线',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const _SectionHeader(title: '精选瞬间', icon: Icons.photo_camera_rounded),
        ...photos.map((item) => TripReviewCard(item: item)),
        const _SectionHeader(title: '新增记忆', icon: Icons.auto_awesome_rounded),
        ...memories.map((item) => TripReviewCard(item: item)),
        if (tasks.isNotEmpty) ...[
          const _SectionHeader(title: '完成任务', icon: Icons.task_alt_rounded),
          ...tasks.map(
            (item) =>
                TripReviewCard(item: item['title']?.toString() ?? '已完成旅行任务'),
          ),
        ],
        const _SectionHeader(title: '蓝小心状态变化', icon: Icons.mood_rounded),
        ...states.map((item) => TripReviewCard(item: item)),
        const _SectionHeader(title: '下次去哪', icon: Icons.explore_rounded),
        ...suggestions.map((item) => TripReviewCard(item: item)),
        if (promotions.isNotEmpty) ...[
          const _SectionHeader(title: '可沉淀为长期记忆', icon: Icons.upgrade_rounded),
          ...promotions.map(
            (item) => TripReviewCard(item: item['title']?.toString() ?? '临时记忆'),
          ),
        ],
      ],
    );
  }
}

String _avatarStateEventText(Map<String, dynamic> event) {
  final title = event['title']?.toString() ?? '';
  final deltas = event['deltas'];
  if (deltas is! Map<String, dynamic> || deltas.isEmpty) return title;
  final deltaText = deltas.entries
      .map((entry) {
        final value = entry.value;
        if (value is num) {
          final sign = value >= 0 ? '+' : '';
          return '${entry.key} $sign$value';
        }
        return '${entry.key} $value';
      })
      .join('、');
  return title.isEmpty ? deltaText : '$title（$deltaText）';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.horizontalPadding + 8,
        20,
        metrics.horizontalPadding + 8,
        8,
      ),
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

Map<String, dynamic> _reviewProfileContext(ProfilePayload profile) {
  return {
    'travelPace': profile.travelPace,
    'dietaryPreferences': profile.dietaryPreferences,
    'interestTags': profile.interestTags,
    'transportPreferences': profile.transportPreferences,
    'budgetPreference': profile.budgetPreference,
  };
}

String _reviewProfileContextText(Map<String, dynamic> review) {
  final context = review['profileContext'];
  if (context is! Map<String, dynamic> || context.isEmpty) return '';
  final tags = <String>[
    context['travelPace']?.toString() ?? '',
    ...((context['interestTags'] as List<dynamic>? ?? const []).map(
      (e) => e.toString(),
    )),
    ...((context['dietaryPreferences'] as List<dynamic>? ?? const []).map(
      (e) => e.toString(),
    )),
  ].where((item) => item.trim().isNotEmpty).toList(growable: false);
  return tags.isEmpty ? '' : '复盘画像 · ${tags.join(' / ')}';
}

class _ReviewProfileContext extends StatelessWidget {
  const _ReviewProfileContext({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return GlassBox(
      opacity: 0.2,
      margin: EdgeInsets.fromLTRB(
        metrics.horizontalPadding,
        AppTheme.spacingSm,
        metrics.horizontalPadding,
        AppTheme.spacingSm,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.person_search_rounded,
            color: AppTheme.primary,
            size: 18,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
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
