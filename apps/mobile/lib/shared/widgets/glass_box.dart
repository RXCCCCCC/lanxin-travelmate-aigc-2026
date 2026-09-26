import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 毛玻璃容器组件 — 完全复刻参考图的磨砂玻璃拟态
/// 效果：多层渐变 + 强模糊 + 白色描边高光 + 柔和外阴影 + 可选内发光
class GlassBox extends StatelessWidget {
  const GlassBox({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.opacity = 0.13,
    this.blur = 28.0,
    this.borderColor,
    this.width,
    this.height,
    this.showGlow = false,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double opacity;
  final double blur;
  final Color? borderColor;
  final double? width;
  final double? height;
  final bool showGlow;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppTheme.radiusLg);
    final border = borderColor ?? Colors.white.withOpacity(0.50);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              borderRadius: radius,
              // 多层渐变：上白下蓝，模拟真实磨砂玻璃
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(opacity + 0.10),
                  Colors.white.withOpacity(opacity),
                  const Color(0xFFB8D8FF).withOpacity(opacity * 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // 白色半透明描边 — 参考图中明显的白色高光边框
              border: Border.all(color: border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4C8DFF).withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                if (showGlow)
                  BoxShadow(
                    color: (glowColor ?? AppTheme.primary).withOpacity(0.22),
                    blurRadius: 32,
                    spreadRadius: -4,
                  ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
