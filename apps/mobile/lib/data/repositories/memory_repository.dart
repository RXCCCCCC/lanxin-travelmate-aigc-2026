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
  });

  final String id;
  final String title;
  final String content;
  final String scope;
  final DateTime createdAt;
}

class MemoryRepository {
  const MemoryRepository(this._database);

  final AppDatabase _database;

  Future<void> saveCandidate(MemoryCandidate candidate, {required String scope}) {
    return _database.into(_database.memoryCapsules).insertOnConflictUpdate(
          MemoryCapsulesCompanion.insert(
            id: candidate.id,
            title: candidate.title,
            content: candidate.content,
            scope: scope,
            source: const Value('agent'),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<List<ConfirmedMemory>> listMemories() async {
    final rows = await (_database.select(_database.memoryCapsules)
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .get();
    return rows
        .map((row) => ConfirmedMemory(
              id: row.id,
              title: row.title,
              content: row.content,
              scope: row.scope,
              createdAt: row.createdAt,
            ))
        .toList();
  }

  Future<void> updateMemory(
    String id, {
    required String title,
    required String content,
  }) {
    return (_database.update(_database.memoryCapsules)
          ..where((table) => table.id.equals(id)))
        .write(MemoryCapsulesCompanion(
          title: Value(title),
          content: Value(content),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> deleteMemory(String id) {
    return (_database.delete(_database.memoryCapsules)
          ..where((table) => table.id.equals(id)))
        .go();
  }
}
