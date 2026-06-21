import 'package:flutter/material.dart';
import '../../core/constants/avatar_states.dart';
import '../../core/theme/app_theme.dart';

/// 蓝小心形象展示组件
///
/// 根据 [AvatarState] 显示对应状态的蓝小心形象图，
/// 并按状态应用不同的浮动节奏和轻微缩放。
class AvatarDisplay extends StatefulWidget {
  const AvatarDisplay({
    super.key,
    this.state = AvatarState.idle,
    this.size = 120,
  });

  final AvatarState state;
  final double size;

  @override
  State<AvatarDisplay> createState() => _AvatarDisplayState();
}

class _AvatarDisplayState extends State<AvatarDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: widget.state.motionDuration,
    )..repeat(reverse: true);
    _configureAnimations();
  }

  @override
  void didUpdateWidget(covariant AvatarDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _floatController.duration = widget.state.motionDuration;
      _configureAnimations();
      _floatController
        ..reset()
        ..repeat(reverse: true);
    }
  }

  void _configureAnimations() {
    final curve = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    );
    _floatAnimation = Tween<double>(
      begin: -widget.state.floatAmplitude,
      end: widget.state.floatAmplitude,
    ).animate(curve);
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.state.pulseScale,
    ).animate(curve);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: _buildAvatar(),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        widget.state.assetPath,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        semanticLabel: '蓝小心${widget.state.label}',
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.15),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: widget.size * 0.45,
              color: AppTheme.primary,
            ),
          );
        },
      ),
    );
  }
}
