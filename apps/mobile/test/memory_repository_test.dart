import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/data/local/app_database.dart';
import 'package:lanxin_travelmate/data/repositories/memory_repository.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_models.dart';

void main() {
  late AppDatabase database;
  late MemoryRepository repository;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = MemoryRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'MemoryRepository saves, updates and deletes confirmed memories',
    () async {
      final candidate = MemoryCandidate(
        id: 'mem-cilantro',
        title: '不吃香菜',
        content: '后续餐饮推荐避开香菜。',
        scopeOptions: const ['longTerm', 'currentTrip', 'temporary', 'ignore'],
        recommendedScope: 'longTerm',
        reason: '稳定饮食偏好',
      );

      await repository.saveCandidate(candidate, scope: 'longTerm');
      final saved = await repository.listMemories();
      expect(saved, hasLength(1));
      expect(saved.single.updatedAt, isA<DateTime>());
      expect(saved.single.title, '不吃香菜');
      expect(saved.single.scope, 'longTerm');

      await repository.updateMemory(
        saved.single.id,
        title: '不要香菜',
        content: '餐厅推荐和点单时都避开香菜。',
      );
      final updated = await repository.listMemories();
      expect(
        updated.single.updatedAt.isBefore(saved.single.updatedAt),
        isFalse,
      );
      expect(updated.single.title, '不要香菜');

      await repository.deleteMemory(updated.single.id);
      expect(await repository.listMemories(), isEmpty);
    },
  );

  test('MemoryRepository queues memory sync operations', () async {
    final candidate = MemoryCandidate(
      id: 'mem-sync-queue',
      title: 'sync title',
      content: 'sync content',
      scopeOptions: const ['longTerm'],
      recommendedScope: 'longTerm',
      reason: 'sync queue test',
    );

    await repository.saveCandidate(candidate, scope: 'longTerm');
    final queuedAfterSave = await repository.listPendingSyncOperations();
    expect(queuedAfterSave, hasLength(1));
    expect(queuedAfterSave.single.entityType, 'memory');
    expect(queuedAfterSave.single.operation, 'upsert');
    expect(queuedAfterSave.single.entityId, candidate.id);

    await repository.updateMemory(
      candidate.id,
      title: 'sync title 2',
      content: 'sync content 2',
    );
    final queuedAfterUpdate = await repository.listPendingSyncOperations();
    expect(queuedAfterUpdate, hasLength(1));
    expect(queuedAfterUpdate.single.operation, 'upsert');
    expect(queuedAfterUpdate.single.attemptCount, 0);

    await repository.deleteMemory(candidate.id);
    final queuedAfterDelete = await repository.listPendingSyncOperations();
    expect(queuedAfterDelete, hasLength(1));
    expect(queuedAfterDelete.single.operation, 'delete');
    expect(queuedAfterDelete.single.entityId, candidate.id);
  });

  test('MemoryRepository marks sync operations by result', () async {
    final candidate = MemoryCandidate(
      id: 'mem-sync-result',
      title: 'sync title',
      content: 'sync content',
      scopeOptions: const ['longTerm'],
      recommendedScope: 'longTerm',
      reason: 'sync result test',
    );

    await repository.saveCandidate(candidate, scope: 'longTerm');
    final pending = await repository.listPendingSyncOperations();

    await repository.markSyncOperationsSucceeded([pending.single.id]);
    expect(await repository.listPendingSyncOperations(), isEmpty);

    await repository.updateMemory(
      candidate.id,
      title: 'sync title 2',
      content: 'sync content 2',
    );
    final failed = await repository.listPendingSyncOperations();

    await repository.markSyncOperationsFailed(
      [failed.single.id],
      'offline',
    );
    final retriable = await repository.listPendingSyncOperations();
    expect(retriable.single.status, 'pending');
    expect(retriable.single.attemptCount, 1);
    expect(retriable.single.lastError, 'offline');
  });
}
