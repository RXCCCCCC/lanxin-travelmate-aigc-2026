import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/glass_box.dart';
import '../../shared/widgets/trip_plan_card.dart';

/// 出行规划页面
class TripPage extends StatelessWidget {
  const TripPage({super.key});

  @override
  Widget build(BuildContext context) {
    final plan = mockTripPlan;

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
                    child: Text('出行规划', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
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
                  // 当前行程信息卡
                  GlassBox(
                    margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingSm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('当前行程', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(plan.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppTheme.spacingXs),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(plan.dateRange, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            const SizedBox(width: AppTheme.spacingLg),
                            const Icon(Icons.place_rounded, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(plan.destination, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 每日行程时间线
                  ...plan.days.map((day) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Text(day.dayLabel, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                      ),
                      ...List.generate(day.items.length, (i) => TripPlanCard(item: day.items[i], index: i)),
                    ],
                  )),
                  // 风险提示
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                        const SizedBox(width: 6),
                        const Text('风险提示', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  ...plan.risks.map((risk) => GlassBox(
                    margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingXs),
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingMd),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(child: Text(risk, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
