import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/demo_agent_state.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/glass_box.dart';
import '../../shared/widgets/trip_review_card.dart';
import 'data/trip_review_service.dart';

/// 旅行复盘页面
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, this.tripReviewService});

  final TripReviewService? tripReviewService;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final TripReviewService _tripReviewService;
  late final Future<TripReviewPayload> _generatedReview;

  @override
  void initState() {
    super.initState();
    _tripReviewService = widget.tripReviewService ?? TripReviewService();
    _generatedReview = _tripReviewService.generateReview(
      tripId: 'demo-chongqing-weekend',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final review = mockTripReview;

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
                              return _AgentReviewView(
                                review: TripReviewPayload.fallback().toJson(),
                              );
                            }
                            return ListView(
                              padding: EdgeInsets.only(
                                bottom: metrics.listBottomPadding,
                              ),
                              children: [
                                // 复盘摘要卡
                                GlassBox(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: metrics.horizontalPadding,
                                    vertical: AppTheme.spacingSm,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.title,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppTheme.spacingSm,
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 14,
                                            color: AppTheme.textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            review.dateRange,
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: AppTheme.spacingSm,
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.route_rounded,
                                            size: 14,
                                            color: AppTheme.textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              review.route,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 13,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: AppTheme.spacingMd,
                                      ),
                                      Row(
                                        children: [
                                          _SummaryBadge(
                                            value:
                                                '${review.highlightPhotoCount}',
                                            label: '精选照片',
                                            icon: Icons.photo_library_rounded,
                                          ),
                                          const SizedBox(
                                            width: AppTheme.spacingMd,
                                          ),
                                          _SummaryBadge(
                                            value: '${review.newMemoryCount}',
                                            label: '新记忆',
                                            icon: Icons.bubble_chart_rounded,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // 精选照片
                                _SectionHeader(
                                  title: '精选瞬间',
                                  icon: Icons.photo_camera_rounded,
                                ),
                                ...review.highlightPhotos.map(
                                  (p) => TripReviewCard(item: p),
                                ),
                                // 新记忆
                                _SectionHeader(
                                  title: '新的记忆',
                                  icon: Icons.auto_awesome_rounded,
                                ),
                                ...review.newMemories.map(
                                  (m) => TripReviewCard(item: m),
                                ),
                                // 下次旅行建议
                                _SectionHeader(
                                  title: '下次去哪',
                                  icon: Icons.explore_rounded,
                                ),
                                ...review.nextTripSuggestions.map(
                                  (s) => TripReviewCard(item: s),
                                ),
                              ],
                            );
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

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
