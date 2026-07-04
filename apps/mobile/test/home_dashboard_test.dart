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
  testWidgets('HomePage displays dashboard trip summary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomePage(dashboardService: StubHomeDashboardService())),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Hangzhou'), findsOneWidget);
    expect(find.textContaining('2 条记忆'), findsOneWidget);
    expect(find.textContaining('1 条提醒'), findsOneWidget);
  });

  testWidgets('HomePage starts with collapsed companion chat bar', (
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

    expect(find.byKey(const ValueKey('home-chat-collapsed-bar')), findsOneWidget);
    expect(find.text('和蓝小心直接聊'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-chat-collapsed-bar')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('和蓝小心直接聊'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('HomePage pure mode button opens full chat route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              HomePage(dashboardService: StubHomeDashboardService()),
        ),
        GoRoute(
          path: '/chat',
          builder: (_, __) => const Scaffold(body: Text('蓝小心纯净模式')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('进入纯净模式'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('蓝小心纯净模式'), findsOneWidget);
  });
}
