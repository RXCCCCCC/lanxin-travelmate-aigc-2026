import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lanxin_travelmate/core/constants/avatar_states.dart';
import 'package:lanxin_travelmate/data/local/app_database.dart'
    hide AvatarState;
import 'package:lanxin_travelmate/data/repositories/memory_repository.dart';
import 'package:lanxin_travelmate/features/chat/chat_page.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_models.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_service.dart';

class StubAgentChatService extends AgentChatService {
  StubAgentChatService() : super(dio: Dio());

  @override
  Future<AgentChatResponse> sendMessage(
    String message, {
    String? sessionId,
    String? userId,
    String? tripId,
    Map<String, dynamic>? context,
    CancelToken? cancelToken,
  }) async {
    return const AgentChatResponse(
      replyText: '我把洪崖洞夜景安排在傍晚后，也会避开香菜。',
      voiceText: '我把洪崖洞夜景安排在傍晚后，也会避开香菜。',
      avatarState: AvatarState.planning,
      emotion: 'curious',
      cards: [],
      memoryCandidates: [
        MemoryCandidate(
          id: 'mem-cilantro',
          title: '不吃香菜',
          content: '后续餐饮推荐避开香菜。',
          scopeOptions: ['longTerm', 'currentTrip', 'temporary', 'ignore'],
          recommendedScope: 'longTerm',
          reason: '稳定饮食偏好',
        ),
      ],
      toolTrace: [],
      nextActions: [],
      syncSuggestions: [],
      errors: [],
    );
  }
}

class ConflictAgentChatService extends AgentChatService {
  ConflictAgentChatService() : super(dio: Dio());

  @override
  Future<AgentChatResponse> sendMessage(
    String message, {
    String? sessionId,
    String? userId,
    String? tripId,
    Map<String, dynamic>? context,
    CancelToken? cancelToken,
  }) async {
    return const AgentChatResponse(
      replyText: '这次我会按轻松节奏处理，不直接覆盖你过去的特种兵偏好。',
      voiceText: '这次我会按轻松节奏处理，不直接覆盖你过去的特种兵偏好。',
      avatarState: AvatarState.planning,
      emotion: 'thoughtful',
      cards: [],
      memoryCandidates: [],
      toolTrace: [],
      nextActions: [],
      errors: [],
      syncSuggestions: [
        {
          'type': 'memoryConflict',
          'title': '发现节奏偏好变化',
          'description': '本次行程优先按低强度规划，长期画像不直接覆盖。',
        },
      ],
    );
  }
}

class ThrowingAgentChatService extends AgentChatService {
  ThrowingAgentChatService() : super(dio: Dio());

  @override
  Future<AgentChatResponse> sendMessage(
    String message, {
    String? sessionId,
    String? userId,
    String? tripId,
    Map<String, dynamic>? context,
    CancelToken? cancelToken,
  }) async {
    throw DioException(
      requestOptions: RequestOptions(path: '/api/agent/chat'),
      type: DioExceptionType.receiveTimeout,
    );
  }
}

void main() {
  late AppDatabase database;
  late MemoryRepository memoryRepository;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    memoryRepository = MemoryRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('ChatPage sends message and displays agent response', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(
          agentChatService: StubAgentChatService(),
          memoryRepository: memoryRepository,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '周末想去重庆两天，不吃香菜');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('周末想去重庆两天，不吃香菜'), findsOneWidget);
    expect(find.textContaining('洪崖洞夜景', skipOffstage: false), findsOneWidget);
    expect(find.text('发现 1 条记忆候选', skipOffstage: false), findsOneWidget);
  });

  testWidgets('ChatPage displays memory conflict suggestion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(
          agentChatService: ConflictAgentChatService(),
          memoryRepository: memoryRepository,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '这次想慢一点');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('发现节奏偏好变化', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('长期画像不直接覆盖', skipOffstage: false), findsOneWidget);
  });

  testWidgets('ChatPage resets sending state and shows fallback when chat fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(
          agentChatService: ThrowingAgentChatService(),
          memoryRepository: memoryRepository,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '你好');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('后端暂时连不上', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });

  testWidgets('ChatPage quick route chip switches to trip tab without pushing root stack', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/chat',
      routes: [
        ShellRoute(
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: '/trip',
              builder: (_, __) => const Scaffold(body: Text('Trip tab')),
            ),
          ],
        ),
        GoRoute(
          path: '/chat',
          builder: (_, __) => ChatPage(
            agentChatService: StubAgentChatService(),
            memoryRepository: memoryRepository,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('规划路线'));
    await tester.pumpAndSettle();

    expect(find.text('Trip tab'), findsOneWidget);
    expect(router.canPop(), isFalse);
    expect(tester.takeException(), equals(null));
  });

  testWidgets('ChatPage route chip switches to trip tab after opening from shell home', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.push('/chat'),
                    child: const Text('进入纯净模式'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/trip',
              builder: (_, __) => const Scaffold(body: Text('Trip tab')),
            ),
          ],
        ),
        GoRoute(
          path: '/chat',
          builder: (_, __) => ChatPage(
            agentChatService: StubAgentChatService(),
            memoryRepository: memoryRepository,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('进入纯净模式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('规划路线'));
    await tester.pumpAndSettle();

    expect(find.text('Trip tab'), findsOneWidget);
    expect(router.canPop(), isFalse);
    expect(tester.takeException(), equals(null));
  });
}
