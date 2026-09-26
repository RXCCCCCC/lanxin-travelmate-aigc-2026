import 'package:flutter/material.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../models/travelmate_models.dart';
import 'glass_box.dart';

/// 出行规划时间线卡片组件
class TripPlanCard extends StatelessWidget {
  const TripPlanCard({super.key, required this.item, required this.index});

  final TripItem item;
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
          // 时间线指示器
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: AppTheme.primary.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.spacingMd),
          // 内容区
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.location,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  item.activity,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: AppTheme.accent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.reason,
                          style: TextStyle(
                            color: AppTheme.accent.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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
