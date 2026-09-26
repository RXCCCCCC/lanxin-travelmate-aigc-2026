import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lanxin_travelmate/data/local/app_database.dart';
import 'package:lanxin_travelmate/data/repositories/memory_repository.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_models.dart';
import 'package:lanxin_travelmate/features/memory/memory_page.dart';
import 'package:lanxin_travelmate/features/settings/data/settings_data_service.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_dashboard_service.dart';

class StubMemoryDashboardService extends TripDashboardService {
  StubMemoryDashboardService() : super(dio: Dio());

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String? userId,
    String? tripId,
  }) async {
    return TripDashboardPayload(
      userId: userId ?? 'guest',
      tripId: tripId,
      currentTrip: const {},
      routePoints: const {},
      reminderHistory: const [],
      blindBoxTasks: const [],
      avatarStateEvents: const [],
      latestReview: const {},
      photoCandidates: const [],
      memories: const [
        {
          'id': 'cloud-night-view',
          'title': 'Prefers night views',
          'content': 'Use skyline routes and evening photo spots.',
          'scope': 'longTerm',
          'createdAt': '2026-06-20T10:00:00',
        },
      ],
    );
  }
}

class EmptyMemoryDashboardService extends TripDashboardService {
  EmptyMemoryDashboardService() : super(dio: Dio());

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String? userId,
    String? tripId,
  }) async {
    return TripDashboardPayload(
      userId: userId ?? 'guest',
      tripId: tripId,
      currentTrip: const {},
      routePoints: const {},
      reminderHistory: const [],
      blindBoxTasks: const [],
      avatarStateEvents: const [],
      latestReview: const {},
      photoCandidates: const [],
      memories: const [],
    );
  }
}

class StubMemorySyncService extends SettingsDataService {
  StubMemorySyncService() : super(dio: Dio());

  List<SyncMemoryDraft> pushedMemories = const [];

  @override
  Future<SyncPushResult> pushSync({
    String userId = 'guest',
    String conflictStrategy = 'serverWins',
    List<SyncMemoryDraft> memories = const [],
  }) async {
    pushedMemories = memories;
    return SyncPushResult(
      status: 'ok',
      pushed: {'memories': memories.length, 'profile': 0, 'trips': 0},
    );
  }
}

void main() {
  testWidgets('MemoryPage shows dashboard memories before offline fixtures', (
    tester,
  ) async {
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MemoryPage(
          database: database,
          repository: MemoryRepository(database),
          dashboardService: StubMemoryDashboardService(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Prefers night views'), findsOneWidget);
    expect(find.textContaining('Use skyline routes'), findsOneWidget);
    expect(find.text('离线样例'), findsNothing);
  });

  testWidgets('MemoryPage syncs only selected local memories', (tester) async {
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    final repository = MemoryRepository(database);
    final syncService = StubMemorySyncService();
    addTearDown(database.close);

    await repository.saveCandidate(
      MemoryCandidate(
        id: 'memory-sync-selected',
        title: 'Selected memory',
        content: 'Only this memory should sync.',
        scopeOptions: const ['longTerm'],
        recommendedScope: 'longTerm',
        reason: 'selected sync',
      ),
      scope: 'longTerm',
    );
    await repository.saveCandidate(
      MemoryCandidate(
        id: 'memory-sync-unselected',
        title: 'Unselected memory',
        content: 'This memory should stay local.',
        scopeOptions: const ['longTerm'],
        recommendedScope: 'longTerm',
        reason: 'selected sync',
      ),
      scope: 'longTerm',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MemoryPage(
          database: database,
          repository: repository,
          dashboardService: StubMemoryDashboardService(),
          syncService: syncService,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(
      find.byKey(const ValueKey('select-memory-memory-sync-selected')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sync-selected-memories')));
    await tester.pumpAndSettle();

    expect(syncService.pushedMemories.map((item) => item.id), [
      'memory-sync-selected',
    ]);
    final pending = await repository.listPendingSyncOperations(
      entityType: 'memory',
      operation: 'upsert',
    );
    expect(pending.map((item) => item.entityId), ['memory-sync-unselected']);
  });

  testWidgets('MemoryPage empty state explains how to create memories', (
    tester,
  ) async {
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
    final router = GoRouter(
      initialLocation: '/memory',
      routes: [
        GoRoute(
          path: '/memory',
          builder: (_, __) => MemoryPage(
            database: database,
            repository: MemoryRepository(database),
            dashboardService: EmptyMemoryDashboardService(),
          ),
        ),
        GoRoute(path: '/chat', builder: (_, __) => const Text('chat page')),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('暂无记忆胶囊'), findsOneWidget);
    expect(find.textContaining('我不吃香菜、喜欢轻松慢游'), findsOneWidget);
    expect(find.byKey(const ValueKey('memory-open-chat')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('memory-open-chat')));
    await tester.pumpAndSettle();

    expect(find.text('chat page'), findsOneWidget);
  });
}
