import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lanxin_travelmate/features/auth/data/auth_session_service.dart';
import 'package:lanxin_travelmate/features/chat/data/voice_interaction_service.dart';
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

class StubVoiceInteractionService extends VoiceInteractionService {
  StubVoiceInteractionService(this.text);

  final String? text;
  int startCalls = 0;
  int stopCalls = 0;
  bool _isListening = false;

  @override
  Future<bool> startListening() async {
    startCalls += 1;
    _isListening = true;
    return true;
  }

  @override
  Future<String?> stopListening() async {
    stopCalls += 1;
    if (!_isListening) return null;
    _isListening = false;
    return text;
  }
}

void main() {
  Widget buildRoutedHome({
    required Widget chatPage,
    TripDashboardService? dashboardService,
    AuthSessionService? authSessionService,
    VoiceInteractionService? voiceInteractionService,
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              HomePage(
                dashboardService: dashboardService ?? StubHomeDashboardService(),
                authSessionService: authSessionService,
                voiceInteractionService: voiceInteractionService,
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

  testWidgets('HomePage microphone fills recognized speech into input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final voiceService = StubVoiceInteractionService('帮我规划广州三天');

    await tester.pumpWidget(
      buildRoutedHome(
        chatPage: const Text('蓝小心纯净模式'),
        voiceInteractionService: voiceService,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // First tap: start recording
    await tester.tap(find.byTooltip('语音输入'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(voiceService.startCalls, 1);
    expect(find.text('正在听你说话，点击麦克风结束'), findsOneWidget);

    // Second tap: stop recording and fill text
    await tester.tap(find.byTooltip('语音输入'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(voiceService.stopCalls, 1);
    expect(find.text('帮我规划广州三天'), findsOneWidget);
    expect(find.text('已填入语音识别文本，可编辑后发送'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}
