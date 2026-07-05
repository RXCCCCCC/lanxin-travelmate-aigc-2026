import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/chat/data/agent_chat_models.dart';
import '../local/app_database.dart';

class ConfirmedMemory {
  const ConfirmedMemory({
    required this.id,
    required this.title,
    required this.content,
    required this.scope,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final String scope;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PendingSyncOperation {
  const PendingSyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.status,
    required this.attemptCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, dynamic> payload;
  final String status;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastError;
}

class MemoryRepository {
  const MemoryRepository(this._database);

  final AppDatabase _database;

  AppDatabase get database => _database;

  Future<void> saveCandidate(
    MemoryCandidate candidate, {
    required String scope,
  }) async {
    final updatedAt = DateTime.now();
    await _database.into(_database.memoryCapsules).insertOnConflictUpdate(
      MemoryCapsulesCompanion.insert(
        id: candidate.id,
        title: candidate.title,
        content: candidate.content,
        scope: scope,
        source: const Value('agent'),
        updatedAt: Value(updatedAt),
      ),
    );
    await _queueMemoryUpsert(
      id: candidate.id,
      title: candidate.title,
      content: candidate.content,
      scope: scope,
      updatedAt: updatedAt,
    );
  }

  Future<List<ConfirmedMemory>> listMemories() async {
    final rows = await (_database.select(
      _database.memoryCapsules,
    )..orderBy([(table) => OrderingTerm.desc(table.createdAt)])).get();
    return rows
        .map(
          (row) => ConfirmedMemory(
            id: row.id,
            title: row.title,
            content: row.content,
            scope: row.scope,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt ?? row.createdAt,
          ),
        )
        .toList();
  }

  Future<void> updateMemory(
    String id, {
    required String title,
    required String content,
  }) async {
    final updatedAt = DateTime.now();
    final updatedRows = await (_database.update(
      _database.memoryCapsules,
    )..where((table) => table.id.equals(id))).write(
      MemoryCapsulesCompanion(
        title: Value(title),
        content: Value(content),
        updatedAt: Value(updatedAt),
      ),
    );
    if (updatedRows > 0) {
      final memory = await _memoryById(id);
      await _queueMemoryUpsert(
        id: id,
        title: title,
        content: content,
        scope: memory?.scope ?? 'longTerm',
        updatedAt: updatedAt,
      );
    }
  }

  Future<void> deleteMemory(String id) async {
    final memory = await _memoryById(id);
    await (_database.delete(
      _database.memoryCapsules,
    )..where((table) => table.id.equals(id))).go();
    await _queueSyncOperation(
      entityType: 'memory',
      entityId: id,
      operation: 'delete',
      payload: {
        'id': id,
        if (memory != null) 'title': memory.title,
        if (memory != null) 'scope': memory.scope,
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<List<PendingSyncOperation>> listPendingSyncOperations({
    String? entityType,
    String? operation,
  }) async {
    final query = _database.select(_database.localSyncOperations)
      ..where((table) => table.status.equals('pending'))
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);
    if (entityType != null) {
      query.where((table) => table.entityType.equals(entityType));
    }
    if (operation != null) {
      query.where((table) => table.operation.equals(operation));
    }
    final rows = await query.get();
    return rows.map(_syncOperationFromRow).toList();
  }

  Future<List<PendingSyncOperation>> listSyncOperations({
    int limit = 8,
  }) async {
    final query = _database.select(_database.localSyncOperations)
      ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map(_syncOperationFromRow).toList();
  }

  Future<void> markSyncOperationsSucceeded(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_database.update(
      _database.localSyncOperations,
    )..where((table) => table.id.isIn(ids))).write(
      LocalSyncOperationsCompanion(
        status: const Value('synced'),
        lastError: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markSyncOperationsFailed(
    List<String> ids,
    String error,
  ) async {
    if (ids.isEmpty) return;
    for (final id in ids) {
      final row = await (_database.select(
        _database.localSyncOperations,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
      if (row == null) continue;
      await (_database.update(
        _database.localSyncOperations,
      )..where((table) => table.id.equals(id))).write(
        LocalSyncOperationsCompanion(
          status: const Value('pending'),
          attemptCount: Value(row.attemptCount + 1),
          lastError: Value(error),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<MemoryCapsule?> _memoryById(String id) {
    return (_database.select(
      _database.memoryCapsules,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<void> _queueMemoryUpsert({
    required String id,
    required String title,
    required String content,
    required String scope,
    required DateTime updatedAt,
  }) {
    return _queueSyncOperation(
      entityType: 'memory',
      entityId: id,
      operation: 'upsert',
      payload: {
        'id': id,
        'title': title,
        'content': content,
        'scope': scope,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> _queueSyncOperation({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now();
    await _removePendingOperations(entityType, entityId);
    await _database.into(_database.localSyncOperations).insert(
      LocalSyncOperationsCompanion.insert(
        id: _operationId(entityType, entityId, operation),
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payloadJson: jsonEncode(payload),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _removePendingOperations(String entityType, String entityId) {
    return (_database.delete(_database.localSyncOperations)
          ..where((table) => table.entityType.equals(entityType))
          ..where((table) => table.entityId.equals(entityId))
          ..where((table) => table.status.equals('pending')))
        .go();
  }

  PendingSyncOperation _syncOperationFromRow(LocalSyncOperation row) {
    final decoded = jsonDecode(row.payloadJson);
    return PendingSyncOperation(
      id: row.id,
      entityType: row.entityType,
      entityId: row.entityId,
      operation: row.operation,
      payload: decoded is Map<String, dynamic> ? decoded : const {},
      status: row.status,
      attemptCount: row.attemptCount,
      lastError: row.lastError,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  String _operationId(String entityType, String entityId, String operation) {
    return '$entityType:$entityId:$operation:${DateTime.now().microsecondsSinceEpoch}';
  }
}
