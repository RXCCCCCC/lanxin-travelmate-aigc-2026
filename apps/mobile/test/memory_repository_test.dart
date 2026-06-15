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

  test('MemoryRepository saves, updates and deletes confirmed memories', () async {
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
    expect(saved.single.title, '不吃香菜');
    expect(saved.single.scope, 'longTerm');

    await repository.updateMemory(
      saved.single.id,
      title: '不要香菜',
      content: '餐厅推荐和点单时都避开香菜。',
    );
    final updated = await repository.listMemories();
    expect(updated.single.title, '不要香菜');

    await repository.deleteMemory(updated.single.id);
    expect(await repository.listMemories(), isEmpty);
  });
}
