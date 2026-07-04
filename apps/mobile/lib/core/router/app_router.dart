import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../layout/responsive_metrics.dart';
import '../../features/home/home_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/trip/trip_page.dart';
import '../../features/photo/photo_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/memory/memory_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/review/review_page.dart';
import '../../features/reminder/reminder_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => _ShellBackScope(
        location: state.uri.path,
        child: ScaffoldWithNav(child: child),
      ),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(path: '/trip', builder: (_, __) => const TripPage()),
        GoRoute(path: '/review', builder: (_, __) => const ReviewPage()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      ],
    ),
    GoRoute(
      path: '/chat',
      builder: (_, state) => ChatPage(
        sessionId: state.uri.queryParameters['sessionId'],
        tripId: state.uri.queryParameters['tripId'],
      ),
    ),
    GoRoute(path: '/photo', builder: (_, __) => const PhotoPage()),
    GoRoute(path: '/memory', builder: (_, __) => const MemoryPage()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
    GoRoute(path: '/reminder', builder: (_, __) => const ReminderPage()),
  ],
);

class _ShellBackScope extends StatelessWidget {
  const _ShellBackScope({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isHome = location == '/';
    final hasRouteStack = GoRouter.of(context).canPop();
    return PopScope(
      canPop: isHome || hasRouteStack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isHome) {
          context.go('/');
        }
      },
      child: child,
    );
  }
}

class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.72),
              const Color(0xFFDCEEFF).withOpacity(0.85),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.45), width: 0.8),
          ),
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.symmetric(
            horizontal: metrics.horizontalPadding / 2,
          ),
          child: SizedBox(
            height: metrics.bottomNavHeight,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: '首页', path: '/'),
                _NavItem(icon: Icons.map_rounded, label: '行程', path: '/trip'),
                _NavItem(
                  icon: Icons.auto_stories_rounded,
                  label: '复盘',
                  path: '/review',
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: '设置',
                  path: '/settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.path});
  final IconData icon;
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final isActive = GoRouterState.of(context).uri.path == path;
    final color = isActive ? const Color(0xFF215ECA) : const Color(0xFF6F8CAF);

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: GestureDetector(
        onTap: () => context.go(path),
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: metrics.minTouchTarget,
            minHeight: metrics.minTouchTarget,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: metrics.navIconSize),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: metrics.navLabelSize,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
