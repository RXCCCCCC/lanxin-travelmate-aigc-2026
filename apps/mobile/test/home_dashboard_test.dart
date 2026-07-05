import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lanxin_travelmate/features/home/home_page.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_dashboard_service.dart';

class StubHomeDashboardService extends TripDashboardService {
  StubHomeDashboardService() : super();

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String userId = 'guest',
    String? tripId,
  }) async {
    return TripDashboardPayload(
      userId: userId,
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

void main() {
  Widget buildRoutedHome({required Widget chatPage}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              HomePage(dashboardService: StubHomeDashboardService()),
        ),
        GoRoute(path: '/chat', builder: (_, __) => chatPage),
        GoRoute(path: '/trip', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/memory', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/review', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/reminder', builder: (_, __) => const SizedBox()),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('HomePage displays dashboard trip summary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomePage(dashboardService: StubHomeDashboardService())),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Hangzhou'), findsOneWidget);
    expect(find.textContaining('2 条记忆'), findsOneWidget);
  });

  testWidgets('HomePage starts with collapsed companion chat input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(home: HomePage(dashboardService: StubHomeDashboardService())),
    );
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-chat-collapsed-bar')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('HomePage pure mode button opens full chat route', (
    tester,
  ) async {
    await tester.pumpWidget(buildRoutedHome(chatPage: const Text('蓝小心纯净模式')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('进入纯净模式'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-chat-collapsed-bar')),
      findsOneWidget,
    );

    await tester.tap(find.text('进入纯净模式'));
    await tester.pumpAndSettle();

    expect(find.text('蓝小心纯净模式'), findsOneWidget);
  });

  testWidgets('HomePage collapsed chat expands before showing quick actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(home: HomePage(dashboardService: StubHomeDashboardService())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey('home-chat-collapsed-bar')),
      findsOneWidget,
    );
    expect(find.text('规划路线'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-chat-collapsed-bar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('规划路线'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
