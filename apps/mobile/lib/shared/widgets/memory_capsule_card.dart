import 'package:flutter/material.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../models/travelmate_models.dart';
import 'glass_box.dart';

/// 记忆胶囊卡片组件
class MemoryCapsuleCard extends StatelessWidget {
  const MemoryCapsuleCard({super.key, required this.capsule});

  final MemoryCapsule capsule;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (capsule.scope) {
      MemoryScope.longTerm => (AppTheme.primary, '长期'),
      MemoryScope.currentTrip => (AppTheme.accent, '本次'),
      MemoryScope.temporary => (AppTheme.textMuted, '临时'),
    };

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (capsule.isNew) ...[
                const SizedBox(width: AppTheme.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '新',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                capsule.createdAt,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            capsule.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            capsule.content,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (capsule.tags.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              children: capsule.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
