import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/core/constants/avatar_states.dart';
import 'package:lanxin_travelmate/data/local/app_database.dart' hide AvatarState;
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
        }
      ],
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

  testWidgets('ChatPage sends message and displays agent response', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChatPage(
        agentChatService: StubAgentChatService(),
        memoryRepository: memoryRepository,
      ),
    ));

    await tester.enterText(find.byType(TextField), '周末想去重庆两天，不吃香菜');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('周末想去重庆两天，不吃香菜'), findsOneWidget);
    expect(find.textContaining('洪崖洞夜景'), findsOneWidget);
    expect(find.text('发现 1 条记忆候选'), findsOneWidget);
  });

  testWidgets('ChatPage displays memory conflict suggestion', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChatPage(
        agentChatService: ConflictAgentChatService(),
        memoryRepository: memoryRepository,
      ),
    ));

    await tester.enterText(find.byType(TextField), '这次想慢一点');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('发现节奏偏好变化'), findsOneWidget);
    expect(find.textContaining('长期画像不直接覆盖'), findsOneWidget);
  });
}
