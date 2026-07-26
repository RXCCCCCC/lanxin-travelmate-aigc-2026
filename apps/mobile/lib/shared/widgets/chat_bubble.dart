import 'package:flutter/material.dart';
import '../../core/constants/avatar_states.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../models/travelmate_models.dart';
import 'glass_box.dart';

/// 聊天气泡组件
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.onOpenTripPlan});

  final ChatMessage message;

  /// 点击行程卡片时回调；为 null 时不渲染行程卡片。
  final VoidCallback? onOpenTripPlan;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final isUser = message.sender == MessageSender.user;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.3),
              child: ClipOval(
                child: Image.asset(
                  (message.avatarState ?? AvatarState.hello).assetPath,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  cacheWidth: 96,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.face_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
          ],
          Flexible(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.96, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: child,
                );
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                child: GlassBox(
                  opacity: isUser ? 0.35 : 0.18,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingMd,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppTheme.radiusLg),
                    topRight: const Radius.circular(AppTheme.radiusLg),
                    bottomLeft: Radius.circular(
                      isUser ? AppTheme.radiusLg : AppTheme.spacingSm,
                    ),
                    bottomRight: Radius.circular(
                      isUser ? AppTheme.spacingSm : AppTheme.radiusLg,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        message.time,
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                      if (!isUser &&
                          message.hasTripPlanCard &&
                          onOpenTripPlan != null) ...[
                        const SizedBox(height: AppTheme.spacingSm),
                        TripPlanSummaryCard(
                          plan: message.tripPlanCard!,
                          onOpen: onOpenTripPlan!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppTheme.spacingSm),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary.withOpacity(0.2),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


/// 聊天气泡内嵌的行程摘要卡片，点击可进入行程页。
class TripPlanSummaryCard extends StatelessWidget {
  const TripPlanSummaryCard({
    super.key,
    required this.plan,
    required this.onOpen,
  });

  final Map<String, dynamic> plan;
  final VoidCallback onOpen;

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final title = _text(plan['title'], '行程建议');
    final destination = _text(plan['destination'], '目的地待确认');
    final days = plan['days'];
    final dayCount = days is List ? days.length : 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      dayCount > 0
                          ? '$destination · $dayCount天行程'
                          : destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
