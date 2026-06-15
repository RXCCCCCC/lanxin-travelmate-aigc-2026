import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum DeviceSizeClass { compactPhone, phone, largePhone, tablet }

class ResponsiveMetrics {
  const ResponsiveMetrics._({
    required this.size,
    required this.safeInsets,
    required this.textScale,
  });

  factory ResponsiveMetrics.of(BuildContext context) {
    final media = MediaQuery.of(context);
    return ResponsiveMetrics._(
      size: media.size,
      safeInsets: media.padding,
      textScale: MediaQuery.textScalerOf(context).scale(1),
    );
  }

  final Size size;
  final EdgeInsets safeInsets;
  final double textScale;

  double get shortestSide => math.min(size.width, size.height);
  double get longestSide => math.max(size.width, size.height);
  bool get isLandscape => size.width > size.height;
  bool get isCompactPhone => shortestSide <= 375 || size.height < 760;
  bool get isLargePhone => shortestSide >= 430 && shortestSide < 600;
  bool get isTablet => shortestSide >= 600;
  bool get hasLargeText => textScale >= 1.2;

  DeviceSizeClass get sizeClass {
    if (isTablet) return DeviceSizeClass.tablet;
    if (isLargePhone) return DeviceSizeClass.largePhone;
    if (isCompactPhone) return DeviceSizeClass.compactPhone;
    return DeviceSizeClass.phone;
  }

  double get horizontalPadding {
    if (isTablet) return 32;
    if (isLandscape) return 24;
    if (isCompactPhone) return 12;
    if (isLargePhone) return 20;
    return AppTheme.spacingLg;
  }

  double get sectionGap =>
      isCompactPhone ? AppTheme.spacingMd : AppTheme.spacingLg;
  double get cardGap =>
      isCompactPhone ? AppTheme.spacingSm : AppTheme.spacingMd;
  double get topBarHeight => isLandscape || isCompactPhone ? 52 : 56;
  double get bottomNavHeight => isLandscape ? 54 : (isCompactPhone ? 58 : 64);
  double get minTouchTarget => 48;

  double get titleFontSize => isCompactPhone ? 18 : 20;
  double get navIconSize => isCompactPhone || isLandscape ? 23 : 25;
  double get navLabelSize => hasLargeText ? 10 : 11;

  double get listBottomPadding =>
      math.max(safeInsets.bottom, AppTheme.spacingSm) + AppTheme.spacingXl;

  double get maxContentWidth {
    if (isTablet) return 720;
    if (isLandscape) return 760;
    return double.infinity;
  }

  double compactValue(double normal, {double factor = 0.92, double? min}) {
    final value = isCompactPhone || isLandscape ? normal * factor : normal;
    return min == null ? value : math.max(value, min);
  }

  EdgeInsets pagePadding({double top = 0, double bottom = 0}) {
    return EdgeInsets.fromLTRB(
      horizontalPadding,
      top,
      horizontalPadding,
      bottom,
    );
  }

  EdgeInsets listPadding({double top = AppTheme.spacingSm, double bottom = 0}) {
    return EdgeInsets.fromLTRB(
      horizontalPadding,
      top,
      horizontalPadding,
      bottom + listBottomPadding,
    );
  }
}

extension ResponsiveContext on BuildContext {
  ResponsiveMetrics get responsive => ResponsiveMetrics.of(this);
}

class AdaptiveContentWidth extends StatelessWidget {
  const AdaptiveContentWidth({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: metrics.maxContentWidth),
        child: child,
      ),
    );
  }
}
