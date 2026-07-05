import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lanxin_travelmate/features/auth/data/auth_session_service.dart';
import 'package:lanxin_travelmate/features/home/home_page.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_dashboard_service.dart';

class StubHomeDashboardService extends TripDashboardService {
  StubHomeDashboardService() : super();

  final List<String> requestedUserIds = [];

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String? userId,
    String? tripId,
  }) async {
    requestedUserIds.add(userId ?? 'guest');
    return TripDashboardPayload(
      userId: userId ?? 'guest',
      tripId: tripId ?? 'trip-home',
      currentTrip: const {
        'tripId': 'trip-home',
        'destination': 'Hangzhou',
        'status': 'active',
        'plan': {'title': 'West Lake night route'},
      },
      routePoints: const {'route': 'Hotel -> West Lake'},
      reminderHistory: const [
        {
          'items': [
            {'title': 'Rain reminder'},
          ],
        },
      ],
      blindBoxTasks: const [],
      avatarStateEvents: const [
        {'eventType': 'chat_interaction'},
      ],
      latestReview: const {},
      photoCandidates: const [],
      memories: const [
        {'title': 'Prefers night views'},
        {'title': 'Avoids cilantro'},
      ],
    );
  }
}

class TestAuthSessionStore implements AuthSessionStore {
  Map<String, dynamic>? value;

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<Map<String, dynamic>?> read() async => value;

  @override
  Future<void> write(Map<String, dynamic> json) async {
    value = json;
  }
}

void main() {
  Widget buildRoutedHome({
    required Widget chatPage,
    TripDashboardService? dashboardService,
    AuthSessionService? authSessionService,
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              HomePage(
                dashboardService: dashboardService ?? StubHomeDashboardService(),
                authSessionService: authSessionService,
              ),
        ),
        GoRoute(path: '/chat', builder: (_, __) => chatPage),
        GoRoute(path: '/trip', builder: (_, __) => const Text('行程页')),
        GoRoute(path: '/memory', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/review', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/reminder', builder: (_, __) => const SizedBox()),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('HomePage displays dashboard trip summary', (tester) async {
    await tester.pumpWidget(buildRoutedHome(chatPage: const Text('蓝小心纯净模式')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Hangzhou'), findsOneWidget);
    expect(find.textContaining('2 条记忆'), findsOneWidget);
  });

  testWidgets('HomePage starts with companion chat panel input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(buildRoutedHome(chatPage: const Text('蓝小心纯净模式')));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('切换到纯净模式'), findsOneWidget);
    expect(find.text('规划路线'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('HomePage pure mode button toggles in-place pure mode', (
    tester,
  ) async {
    await tester.pumpWidget(buildRoutedHome(chatPage: const Text('蓝小心纯净模式')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('切换到纯净模式'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('切换到纯净模式'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('切换到陪伴模式'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('HomePage quick route action opens trip tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(buildRoutedHome(chatPage: const Text('蓝小心纯净模式')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('规划路线'), findsOneWidget);
    await tester.tap(find.text('规划路线'));
    await tester.pumpAndSettle();

    expect(find.text('行程页'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('HomePage reloads dashboard for new account session', (
    tester,
  ) async {
    final dashboardService = StubHomeDashboardService();
    final store = TestAuthSessionStore();
    final auth = AuthSessionService(store: store);
    await auth.debugSetSession(null);

    await tester.pumpWidget(
      buildRoutedHome(
        chatPage: const Text('蓝小心纯净模式'),
        dashboardService: dashboardService,
        authSessionService: auth,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(dashboardService.requestedUserIds, contains('guest'));

    await auth.debugSetSession(
      const AuthSession(
        userId: 'user-a',
        displayName: '用户A',
        authMode: 'password',
        isGuest: false,
        accessToken: 'token-a',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(dashboardService.requestedUserIds.last, 'user-a');
  });
}
