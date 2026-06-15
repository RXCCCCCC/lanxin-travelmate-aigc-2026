import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';

class AdaptiveTopBar extends StatelessWidget {
  const AdaptiveTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return AdaptiveContentWidth(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mathMax(4, metrics.horizontalPadding - 8),
          vertical: 4,
        ),
        child: SizedBox(
          height: metrics.topBarHeight,
          child: Row(
            children: [
              SizedBox(
                width: metrics.minTouchTarget,
                height: metrics.minTouchTarget,
                child: IconButton(
                  onPressed: onBack ?? () => context.pop(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: metrics.titleFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: metrics.minTouchTarget,
                height: metrics.minTouchTarget,
                child: trailing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double mathMax(double a, double b) => a > b ? a : b;
