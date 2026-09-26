import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // 主色
  static const Color primary = Color(0xFF4C8DFF);
  static const Color primaryDark = Color(0xFF215ECA);
  static const Color primaryLight = Color(0xFF6F9BFF);
  static const Color accent = Color(0xFF67C7FF);

  // 背景
  static const Color bgTop = Color(0xFF5FA4FF);
  static const Color bgMid = Color(0xFFAAD6FF);
  static const Color bgBottom = Color(0xFFE8F7FF);
  static const Color surface = Color(0xFFD7ECFF);

  // 文字
  static const Color textPrimary = Color(0xFF06224E);
  static const Color textSecondary = Color(0xFF425D8E);
  static const Color textMuted = Color(0xFF6F8CAF);

  // 玻璃拟态
  static const double glassOpacity = 0.18;
  static const double glassBlur = 18.0;
  static const double radiusXl = 34.0;
  static const double radiusLg = 24.0;
  static const double radiusMd = 18.0;
  static const double radiusSm = 12.0;

  // 间距
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 24.0;

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surface,
      fontFamily: 'sans',
    );
  }
}
