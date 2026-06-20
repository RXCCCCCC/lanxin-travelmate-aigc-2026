import '../../../data/repositories/memory_repository.dart';
import 'settings_data_service.dart';

class SyncRetryResult {
  const SyncRetryResult({
    this.pushedMemories = 0,
    this.revokedMemories = 0,
    this.failedOperations = 0,
    this.conflicts = 0,
  });

  final int pushedMemories;
  final int revokedMemories;
  final int failedOperations;
  final int conflicts;

  int get handledOperations => pushedMemories + revokedMemories;
}

class SyncRetryService {
  const SyncRetryService({
    required this.repository,
    required this.dataService,
  });

  final MemoryRepository repository;
  final SettingsDataService dataService;

  Future<SyncRetryResult> retryPendingOperations() async {
    var pushedMemories = 0;
    var revokedMemories = 0;
    var failedOperations = 0;
    var conflicts = 0;

    final pendingUpserts = await repository.listPendingSyncOperations(
      entityType: 'memory',
      operation: 'upsert',
    );
    if (pendingUpserts.isNotEmpty) {
      final result = await dataService.pushSync(
        memories: pendingUpserts.map(_operationToMemoryDraft).toList(
          growable: false,
        ),
      );
      final ids = pendingUpserts.map((item) => item.id).toList(growable: false);
      if (result.status == 'offline') {
        await repository.markSyncOperationsFailed(ids, 'offline');
        failedOperations += ids.length;
      } else if (result.conflicts.isEmpty) {
        await repository.markSyncOperationsSucceeded(ids);
        pushedMemories += ids.length;
      } else {
        conflicts += result.conflicts.length;
      }
    }

    final pendingDeletes = await repository.listPendingSyncOperations(
      entityType: 'memory',
      operation: 'delete',
    );
    if (pendingDeletes.isNotEmpty) {
      final result = await dataService.revokeCloudSync(
        memoryIds: pendingDeletes.map((item) => item.entityId).toList(
          growable: false,
        ),
      );
      final ids = pendingDeletes.map((item) => item.id).toList(growable: false);
      if (result.status == 'offline') {
        await repository.markSyncOperationsFailed(ids, 'offline');
        failedOperations += ids.length;
      } else {
        await repository.markSyncOperationsSucceeded(ids);
        revokedMemories += ids.length;
      }
    }

    return SyncRetryResult(
      pushedMemories: pushedMemories,
      revokedMemories: revokedMemories,
      failedOperations: failedOperations,
      conflicts: conflicts,
    );
  }
}

SyncMemoryDraft _operationToMemoryDraft(PendingSyncOperation operation) {
  final payload = operation.payload;
  return SyncMemoryDraft(
    id: (payload['id'] as String?) ?? operation.entityId,
    title: (payload['title'] as String?) ?? operation.entityId,
    content: (payload['content'] as String?) ?? '',
    scope: (payload['scope'] as String?) ?? 'longTerm',
    updatedAt: payload['updatedAt'] as String?,
  );
}
