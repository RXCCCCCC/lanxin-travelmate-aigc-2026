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

class ScaffoldWithNav extends StatefulWidget {
  const ScaffoldWithNav({super.key, required this.child});
  final Widget child;

  @override
  State<ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends State<ScaffoldWithNav> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final navHeight = _collapsed ? 42.0 : metrics.bottomNavHeight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.child,
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
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
            height: navHeight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _collapsed
                  ? _CollapsedNavBar(
                      key: const ValueKey('collapsed-nav'),
                      onExpand: () => setState(() => _collapsed = false),
                    )
                  : _ExpandedNavBar(
                      key: const ValueKey('expanded-nav'),
                      onCollapse: () => setState(() => _collapsed = true),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedNavBar extends StatelessWidget {
  const _ExpandedNavBar({super.key, required this.onCollapse});

  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const _NavItem(icon: Icons.home_rounded, label: '首页', path: '/'),
        const _NavItem(icon: Icons.map_rounded, label: '行程', path: '/trip'),
        const _NavItem(
          icon: Icons.auto_stories_rounded,
          label: '复盘',
          path: '/review',
        ),
        const _NavItem(
          icon: Icons.settings_rounded,
          label: '设置',
          path: '/settings',
        ),
        _NavToggleButton(
          icon: Icons.keyboard_arrow_down_rounded,
          tooltip: '收起底部导航',
          onTap: onCollapse,
        ),
      ],
    );
  }
}

class _CollapsedNavBar extends StatelessWidget {
  const _CollapsedNavBar({super.key, required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const _MiniNavItem(icon: Icons.home_rounded, label: '首页', path: '/'),
        const _MiniNavItem(icon: Icons.map_rounded, label: '行程', path: '/trip'),
        const _MiniNavItem(
          icon: Icons.auto_stories_rounded,
          label: '复盘',
          path: '/review',
        ),
        const _MiniNavItem(
          icon: Icons.settings_rounded,
          label: '设置',
          path: '/settings',
        ),
        _NavToggleButton(
          icon: Icons.keyboard_arrow_up_rounded,
          tooltip: '展开底部导航',
          onTap: onExpand,
        ),
      ],
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

class _MiniNavItem extends StatelessWidget {
  const _MiniNavItem({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    final isActive = GoRouterState.of(context).uri.path == path;
    final color = isActive ? const Color(0xFF215ECA) : const Color(0xFF6F8CAF);
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: GestureDetector(
        onTap: () => context.go(path),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 48,
          height: 38,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _NavToggleButton extends StatelessWidget {
  const _NavToggleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.28),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Icon(icon, color: const Color(0xFF4D7FBD), size: 24),
        ),
      ),
    );
  }
}
