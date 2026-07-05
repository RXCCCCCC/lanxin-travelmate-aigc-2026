import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

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
  static const _navCollapsedKey = 'home.nav.collapsed';
  static const _tabPaths = ['/', '/trip', '/review', '/settings'];
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _restoreCollapsedState();
  }

  Future<void> _restoreCollapsedState() async {
    final file = await _navStateFile();
    final collapsed = await file.exists()
        ? (await file.readAsString()).trim() == 'collapsed'
        : false;
    if (!mounted) return;
    setState(() => _collapsed = collapsed);
  }

  Future<void> _setCollapsed(bool value) async {
    setState(() => _collapsed = value);
    final file = await _navStateFile();
    await file.writeAsString(value ? 'collapsed' : 'expanded');
  }

  Future<File> _navStateFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_navCollapsedKey.txt');
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 360) return;
    final currentPath = GoRouterState.of(context).uri.path;
    final currentIndex = _tabPaths.indexOf(currentPath);
    if (currentIndex < 0) return;
    final nextIndex = velocity < 0 ? currentIndex + 1 : currentIndex - 1;
    if (nextIndex < 0 || nextIndex >= _tabPaths.length) return;
    context.go(_tabPaths[nextIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final navHeight = _collapsed ? 28.0 : metrics.bottomNavHeight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleHorizontalSwipe,
        child: widget.child,
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(_collapsed ? 0.20 : 0.72),
              const Color(0xFFDCEEFF).withOpacity(_collapsed ? 0.36 : 0.85),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: navHeight,
            child: SizedBox(
              height: navHeight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _collapsed
                    ? _CollapsedNavBar(
                        key: const ValueKey('collapsed-nav'),
                        onExpand: () => _setCollapsed(false),
                      )
                    : _ExpandedNavBar(
                        key: const ValueKey('expanded-nav'),
                        onCollapse: () => _setCollapsed(true),
                      ),
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
    final metrics = context.responsive;
    final topPadding = metrics.isLandscape ? 4.0 : 8.0;

    return Container(
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
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding),
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
          Positioned(
            top: 0,
            child: _NavChevronButton(
              icon: Icons.keyboard_arrow_down_rounded,
              tooltip: '收起底部导航',
              onTap: onCollapse,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedNavBar extends StatelessWidget {
  const _CollapsedNavBar({super.key, required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.24),
              const Color(0xFFDCEEFF).withOpacity(0.34),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 0.8),
        ),
        child: Center(
          child: _NavChevronButton(
            icon: Icons.keyboard_arrow_up_rounded,
            tooltip: '展开底部导航',
            onTap: onExpand,
            height: 28,
            width: 72,
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

class _NavChevronButton extends StatelessWidget {
  const _NavChevronButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.width = 56,
    this.height = 28,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: width,
            height: height,
            child: Center(
              child: Icon(icon, color: const Color(0xFF4D7FBD), size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
