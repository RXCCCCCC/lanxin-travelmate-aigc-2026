import 'package:flutter/material.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import 'glass_box.dart';

/// 聊天气泡组件
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final isUser = message.sender == MessageSender.user;

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
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
          ],
          Flexible(
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
