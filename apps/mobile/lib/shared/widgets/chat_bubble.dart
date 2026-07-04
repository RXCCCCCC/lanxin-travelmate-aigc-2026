import 'package:flutter/material.dart';
import '../../core/constants/avatar_states.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../models/travelmate_models.dart';
import 'glass_box.dart';

/// 聊天气泡组件
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

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
