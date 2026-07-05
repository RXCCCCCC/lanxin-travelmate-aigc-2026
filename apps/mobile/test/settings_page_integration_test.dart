import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/data/local/app_database.dart';
import 'package:lanxin_travelmate/data/repositories/memory_repository.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_models.dart';
import 'package:lanxin_travelmate/features/profile/data/profile_service.dart';
import 'package:lanxin_travelmate/features/settings/data/settings_data_service.dart';
import 'package:lanxin_travelmate/features/settings/settings_page.dart';

class _ProfileStub extends ProfileService {
  _ProfileStub() : super(dio: Dio());

  @override
  Future<ProfilePayload> fetchProfile({String userId = 'guest'}) async {
    return const ProfilePayload(
      userId: 'guest',
      travelPace: 'light',
      dietaryPreferences: [],
      interestTags: [],
      transportPreferences: [],
      budgetPreference: 'medium',
      personality: 'gentle_companion',
      customPrompt: 'Keep it calm.',
    );
  }
}

class _DataStub extends SettingsDataService {
  _DataStub() : super(dio: Dio());

  List<String> revokedMemoryIds = const [];
  List<String> revokedTripIds = const [];
  bool revokedProfile = false;
  final List<String> conflictStrategies = [];
  List<SyncMemoryDraft> pushedMemories = const [];
  int pushCount = 0;
  bool conflictForSingleMemory = true;

  @override
  Future<PrivacySummaryPayload> fetchPrivacySummary() async {
    return const PrivacySummaryPayload(
      principles: ['Consent first, minimal cloud data.'],
      permissions: [
        PrivacyPermissionInfo(
          permission: 'photos',
          label: 'Photos',
          purpose: 'Travel review highlights',
          fallback: 'Text-only review',
        ),
      ],
      userControls: {'canExportData': true},
    );
  }

  @override
  Future<DataActionResult> revokeCloudSync({
    String userId = 'guest',
    List<String> memoryIds = const [],
    bool revokeProfile = false,
    List<String> tripIds = const [],
  }) async {
    revokedMemoryIds = memoryIds;
    revokedTripIds = tripIds;
    revokedProfile = revokeProfile;
    return const DataActionResult(
      status: 'ok',
      revoked: {'memories': 2, 'profile': 0, 'trips': 1},
    );
  }

  @override
  Future<SyncPushResult> pushSync({
    String userId = 'guest',
    String conflictStrategy = 'serverWins',
    List<SyncMemoryDraft> memories = const [],
  }) async {
    pushCount += 1;
    conflictStrategies.add(conflictStrategy);
    pushedMemories = memories;
    if (memories.length != 1 || !conflictForSingleMemory) {
      return SyncPushResult(
        status: 'ok',
        pushed: {'memories': memories.length, 'profile': 0, 'trips': 0},
      );
    }
    return SyncPushResult(
      status: 'ok',
      conflicts: [
        SyncConflictInfo(
          entityType: 'memory',
          entityId: memories.single.id,
          resolution: conflictStrategy,
          server: const {'title': 'server title'},
          client: {'title': memories.single.title},
        ),
      ],
    );
  }
}

class _MemoryRepositoryStub extends MemoryRepository {
  const _MemoryRepositoryStub(super.database, this._memories);

  final List<ConfirmedMemory> _memories;

  @override
  Future<List<ConfirmedMemory>> listMemories() async => _memories;
}

void main() {
  AppDatabase newTestDatabase() {
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
    return database;
  }

  testWidgets('SettingsPage shows profile and data-control sections', (
    tester,
  ) async {
    final dataStub = _DataStub();
    final database = newTestDatabase();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            profileService: _ProfileStub(),
            dataService: dataStub,
            memoryRepository: _MemoryRepositoryStub(database, [
              ConfirmedMemory(
                id: 'local-memory-1',
                title: 'Local memory',
                content: 'Local content',
                scope: 'longTerm',
                createdAt: DateTime.utc(2026, 6, 19),
                updatedAt: DateTime.utc(2026, 6, 20),
              ),
            ]),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('温柔陪伴'), findsWidgets);
    expect(find.text('Keep it calm.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('自定义 Prompt'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(TextField), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('数据与隐私'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Consent first, minimal cloud data.'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sync-local-memories-button')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('sync-local-memories-button')));
    await tester.pumpAndSettle();
    expect(dataStub.pushedMemories.single.id, 'local-memory-1');
    expect(
      dataStub.pushedMemories.single.updatedAt,
      '2026-06-20T00:00:00.000Z',
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('revoke-memory-ids-field')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('revoke-memory-ids-field')),
      'm-1, m-2',
    );
    await tester.enterText(
      find.byKey(const ValueKey('revoke-trip-ids-field')),
      'trip-1',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('revoke-selected-sync-button')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('revoke-selected-sync-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-destructive-action')));
    await tester.pumpAndSettle();

    expect(dataStub.revokedMemoryIds, ['m-1', 'm-2']);
    expect(dataStub.revokedTripIds, ['trip-1']);
    expect(dataStub.revokedProfile, isFalse);
    expect(
      find.text(
        '\u{5DF2}\u{64A4}\u{9500} 2 \u{6761}\u{8BB0}\u{5FC6}\u{548C} 1 \u{4E2A}\u{65C5}\u{7A0B}\u{4E91}\u{7AEF}\u{526F}\u{672C}',
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sync-conflict-memory-id-field')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('sync-conflict-memory-id-field')),
      'm-conflict',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sync-conflict-title-field')),
      'client title',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sync-conflict-content-field')),
      'client content',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('detect-sync-conflict-button')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('detect-sync-conflict-button')));
    await tester.pumpAndSettle();

    expect(dataStub.conflictStrategies, contains('serverWins'));
    expect(find.textContaining('server title'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('resolve-sync-client-wins-button')),
    );
    await tester.pumpAndSettle();
    expect(dataStub.conflictStrategies.last, 'clientWins');

    await tester.scrollUntilVisible(
      find.text('导出记忆'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('撤销云端画像同步'), findsOneWidget);
    expect(find.text('清空当前旅行'), findsOneWidget);
    expect(find.text('清空全部记忆'), findsOneWidget);
  });

  testWidgets('SettingsPage pushes pending memory sync queue first', (
    tester,
  ) async {
    final dataStub = _DataStub();
    dataStub.conflictForSingleMemory = false;
    final database = newTestDatabase();
    final repository = MemoryRepository(database);

    await repository.saveCandidate(
      MemoryCandidate(
        id: 'queued-memory-1',
        title: 'queued title',
        content: 'queued content',
        scopeOptions: const ['longTerm'],
        recommendedScope: 'longTerm',
        reason: 'queued sync',
      ),
      scope: 'longTerm',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            profileService: _ProfileStub(),
            dataService: dataStub,
            memoryRepository: repository,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sync-local-memories-button')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('sync-local-memories-button'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sync-local-memories-button')));
    await tester.pumpAndSettle();

    expect(dataStub.pushCount, 1);
    expect(dataStub.pushedMemories.single.id, 'queued-memory-1');
    expect(await repository.listPendingSyncOperations(), isEmpty);
    expect(find.textContaining('pending'), findsNothing);
  });

  testWidgets('SettingsPage revokes pending memory delete queue', (
    tester,
  ) async {
    final dataStub = _DataStub();
    final database = newTestDatabase();
    final repository = MemoryRepository(database);

    await repository.saveCandidate(
      MemoryCandidate(
        id: 'deleted-memory-1',
        title: 'deleted title',
        content: 'deleted content',
        scopeOptions: const ['longTerm'],
        recommendedScope: 'longTerm',
        reason: 'delete sync',
      ),
      scope: 'longTerm',
    );
    final createdQueue = await repository.listPendingSyncOperations();
    await repository.markSyncOperationsSucceeded(
      createdQueue.map((item) => item.id).toList(growable: false),
    );
    await repository.deleteMemory('deleted-memory-1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            profileService: _ProfileStub(),
            dataService: dataStub,
            memoryRepository: repository,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sync-local-memories-button')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('sync-local-memories-button'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sync-local-memories-button')));
    await tester.pumpAndSettle();

    expect(dataStub.revokedMemoryIds, ['deleted-memory-1']);
    expect(await repository.listPendingSyncOperations(), isEmpty);
  });

  testWidgets('SettingsPage displays local sync history', (tester) async {
    final dataStub = _DataStub();
    final database = newTestDatabase();
    final repository = MemoryRepository(database);

    await repository.saveCandidate(
      MemoryCandidate(
        id: 'history-upsert-memory',
        title: 'history upsert',
        content: 'history content',
        scopeOptions: const ['longTerm'],
        recommendedScope: 'longTerm',
        reason: 'history sync',
      ),
      scope: 'longTerm',
    );
    final pendingUpsert = await repository.listPendingSyncOperations();
    await repository.markSyncOperationsSucceeded(
      pendingUpsert.map((item) => item.id).toList(growable: false),
    );
    await repository.deleteMemory('history-upsert-memory');
    final pendingDelete = await repository.listPendingSyncOperations();
    await repository.markSyncOperationsFailed(
      pendingDelete.map((item) => item.id).toList(growable: false),
      'offline',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            profileService: _ProfileStub(),
            dataService: dataStub,
            memoryRepository: repository,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sync-history-panel')),
      220,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.textContaining('history-upsert-memory'), findsWidgets);
    expect(find.textContaining('记忆同步'), findsOneWidget);
    expect(find.textContaining('记忆撤销'), findsOneWidget);
    expect(find.textContaining('已同步'), findsOneWidget);
    expect(find.textContaining('同步失败'), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
  });
}
