import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/data/local/app_database.dart';
import 'package:lanxin_travelmate/data/repositories/memory_repository.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_models.dart';
import 'package:lanxin_travelmate/features/settings/data/settings_data_service.dart';
import 'package:lanxin_travelmate/features/settings/data/sync_retry_service.dart';

class _RetryDataStub extends SettingsDataService {
  _RetryDataStub({this.offline = false}) : super(dio: Dio());

  final bool offline;
  List<SyncMemoryDraft> pushedMemories = const [];
  List<String> revokedMemoryIds = const [];

  @override
  Future<SyncPushResult> pushSync({
    String userId = 'guest',
    String conflictStrategy = 'serverWins',
    List<SyncMemoryDraft> memories = const [],
  }) async {
    pushedMemories = memories;
    if (offline) return SyncPushResult.offline();
    return SyncPushResult(
      status: 'ok',
      pushed: {'memories': memories.length, 'profile': 0, 'trips': 0},
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
    if (offline) return const DataActionResult(status: 'offline');
    return DataActionResult(
      status: 'ok',
      revoked: {'memories': memoryIds.length, 'profile': 0, 'trips': 0},
    );
  }
}

void main() {
  test('SyncRetryService retries pending upserts and deletes', () async {
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    final repository = MemoryRepository(database);
    final dataService = _RetryDataStub();
    addTearDown(database.close);

    await repository.saveCandidate(
      MemoryCandidate(
        id: 'retry-upsert-memory',
        title: 'Retry upsert',
        content: 'Retry this pending upsert.',
        scopeOptions: const ['longTerm'],
        recommendedScope: 'longTerm',
        reason: 'background retry',
      ),
      scope: 'longTerm',
    );
    await repository.saveCandidate(
      MemoryCandidate(
        id: 'retry-delete-memory',
        title: 'Retry delete',
        content: 'Retry this pending delete.',
        scopeOptions: const ['longTerm'],
        recommendedScope: 'longTerm',
        reason: 'background retry',
      ),
      scope: 'longTerm',
    );
    final pendingBeforeDelete = await repository.listPendingSyncOperations();
    await repository.markSyncOperationsSucceeded(
      pendingBeforeDelete
          .where((item) => item.entityId == 'retry-delete-memory')
          .map((item) => item.id)
          .toList(growable: false),
    );
    await repository.deleteMemory('retry-delete-memory');

    final result = await SyncRetryService(
      repository: repository,
      dataService: dataService,
    ).retryPendingOperations();

    expect(result.pushedMemories, 1);
    expect(result.revokedMemories, 1);
    expect(dataService.pushedMemories.single.id, 'retry-upsert-memory');
    expect(dataService.revokedMemoryIds, ['retry-delete-memory']);
    expect(await repository.listPendingSyncOperations(), isEmpty);
  });

  test('SyncRetryService keeps offline operations pending', () async {
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    final repository = MemoryRepository(database);
    addTearDown(database.close);

    await repository.saveCandidate(
      MemoryCandidate(
        id: 'retry-offline-memory',
        title: 'Retry offline',
        content: 'Keep this pending while offline.',
        scopeOptions: const ['longTerm'],
        recommendedScope: 'longTerm',
        reason: 'background retry',
      ),
      scope: 'longTerm',
    );

    final result = await SyncRetryService(
      repository: repository,
      dataService: _RetryDataStub(offline: true),
    ).retryPendingOperations();

    expect(result.failedOperations, 1);
    final pending = await repository.listPendingSyncOperations();
    expect(pending.single.entityId, 'retry-offline-memory');
    expect(pending.single.attemptCount, 1);
    expect(pending.single.lastError, 'offline');
  });
}
