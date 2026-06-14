import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/glass_box.dart';
import '../../shared/widgets/trip_review_card.dart';

/// 旅行复盘页面
class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final review = mockTripReview;

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
                    child: Text('旅行复盘', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // 内容
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingXl),
                children: [
                  // 复盘摘要卡
                  GlassBox(
                    margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingSm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(review.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppTheme.spacingSm),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(review.dateRange, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Row(
                          children: [
                            const Icon(Icons.route_rounded, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Expanded(child: Text(review.route, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.3))),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Row(
                          children: [
                            _SummaryBadge(value: '${review.highlightPhotoCount}', label: '精选照片', icon: Icons.photo_library_rounded),
                            const SizedBox(width: AppTheme.spacingMd),
                            _SummaryBadge(value: '${review.newMemoryCount}', label: '新记忆', icon: Icons.bubble_chart_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 精选照片
                  _SectionHeader(title: '精选瞬间', icon: Icons.photo_camera_rounded),
                  ...review.highlightPhotos.map((p) => TripReviewCard(item: p)),
                  // 新记忆
                  _SectionHeader(title: '新的记忆', icon: Icons.auto_awesome_rounded),
                  ...review.newMemories.map((m) => TripReviewCard(item: m)),
                  // 下次旅行建议
                  _SectionHeader(title: '下次去哪', icon: Icons.explore_rounded),
                  ...review.nextTripSuggestions.map((s) => TripReviewCard(item: s)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.value, required this.label, required this.icon});
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
            Text(value, style: const TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
