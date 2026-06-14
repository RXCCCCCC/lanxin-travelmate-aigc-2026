import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class LanXinApp extends StatelessWidget {
  const LanXinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '蓝心同行',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
