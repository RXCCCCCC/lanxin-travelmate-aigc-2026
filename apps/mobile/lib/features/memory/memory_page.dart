import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/app_database.dart' as local_db;
import '../../data/mock_data.dart';
import '../../data/repositories/memory_repository.dart';
import '../../shared/widgets/glass_box.dart';
import '../../shared/widgets/memory_capsule_card.dart';

/// 记忆胶囊页面
class MemoryPage extends StatefulWidget {
  const MemoryPage({super.key});

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  int _selectedTab = 0;
  late final local_db.AppDatabase _database;
  late final MemoryRepository _repository;
  List<ConfirmedMemory> _storedMemories = [];

  static const _tabs = ['全部', '长期', '本次', '临时'];

  @override
  void initState() {
    super.initState();
    _database = local_db.AppDatabase();
    _repository = MemoryRepository(_database);
    _loadStoredMemories();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _loadStoredMemories() async {
    final memories = await _repository.listMemories();
    if (!mounted) return;
    setState(() => _storedMemories = memories);
  }

  List<_MemoryDisplayItem> get _items {
    final storedItems = _storedMemories.map((memory) {
      return _MemoryDisplayItem(
        capsule: MemoryCapsule(
          id: memory.id,
          title: memory.title,
          content: memory.content,
          scope: _scopeFromStorage(memory.scope),
          createdAt: _formatDate(memory.createdAt),
          tags: const ['已确认', '本地'],
          isNew: true,
        ),
        storedId: memory.id,
      );
    });
    final mockItems = mockMemoryCapsules.map((capsule) => _MemoryDisplayItem(capsule: capsule));
    return [...storedItems, ...mockItems];
  }

  List<_MemoryDisplayItem> get _filtered {
    if (_selectedTab == 0) return _items;
    final scope = MemoryScope.values[_selectedTab - 1];
    return _items.where((item) => item.capsule.scope == scope).toList();
  }

  MemoryScope _scopeFromStorage(String scope) {
    return switch (scope) {
      'longTerm' => MemoryScope.longTerm,
      'temporary' => MemoryScope.temporary,
      _ => MemoryScope.currentTrip,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteStoredMemory(String id) async {
    await _repository.deleteMemory(id);
    await _loadStoredMemories();
  }

  Future<void> _editStoredMemory(_MemoryDisplayItem item) async {
    final titleController = TextEditingController(text: item.capsule.title);
    final contentController = TextEditingController(text: item.capsule.content);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑记忆胶囊'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: '标题')),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: '内容'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('保存')),
        ],
      ),
    );
    if (shouldSave != true || item.storedId == null) return;
    await _repository.updateMemory(
      item.storedId!,
      title: titleController.text.trim(),
      content: contentController.text.trim(),
    );
    await _loadStoredMemories();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5FA4FF), Color(0xFFAAD6FF), Color(0xFFE8F7FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 顶部栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                  ),
                  const Expanded(
                    child: Text('记忆胶囊', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 48), // 平衡返回按钮
                ],
              ),
            ),
            // 筛选标签
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingSm),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final selected = _selectedTab == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: GlassBox(
                        opacity: selected ? 0.35 : 0.12,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          _tabs[i],
                          style: TextStyle(
                            color: selected ? AppTheme.primary : AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // 记忆胶囊列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final item = _filtered[i];
                  if (item.storedId == null) {
                    return MemoryCapsuleCard(capsule: item.capsule);
                  }
                  return Column(
                    children: [
                      MemoryCapsuleCard(capsule: item.capsule),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _editStoredMemory(item),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('编辑'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _deleteStoredMemory(item.storedId!),
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              label: const Text('删除'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryDisplayItem {
  const _MemoryDisplayItem({required this.capsule, this.storedId});

  final MemoryCapsule capsule;
  final String? storedId;
}
