import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/glass_box.dart';

/// 个人画像页面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    const profile = mockUserProfile;

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
                      '个人画像',
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
            // 内容列表
            Expanded(
              child: ListView(
                padding: metrics.listPadding(top: AppTheme.spacingSm),
                children: [
                  // 用户头像和名字
                  GlassBox(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primary.withOpacity(0.2),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingLg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '蓝小心了解你的旅行偏好',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  // 饮食偏好
                  _ProfileCard(
                    icon: Icons.restaurant_rounded,
                    title: '饮食偏好',
                    values: profile.dietaryPreferences,
                  ),
                  // 旅行节奏
                  _ProfileCard(
                    icon: Icons.directions_walk_rounded,
                    title: '旅行节奏',
                    values: [profile.travelPace],
                  ),
                  // 交通偏好
                  _ProfileCard(
                    icon: Icons.directions_bus_rounded,
                    title: '交通偏好',
                    values: [profile.transportPreference],
                  ),
                  // 预算水平
                  _ProfileCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: '预算水平',
                    values: [profile.budgetLevel],
                  ),
                  // 兴趣标签
                  _ProfileCard(
                    icon: Icons.local_offer_rounded,
                    title: '兴趣标签',
                    values: profile.interestTags,
                    isTags: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.values,
    this.isTags = false,
  });
  final IconData icon;
  final String title;
  final List<String> values;
  final bool isTags;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: GlassBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primary),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: metrics.minTouchTarget - 12,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '编辑',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            isTags
                ? Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingSm,
                    children: values
                        .map(
                          (v) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              v,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: values
                        .map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              v,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
