import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/router/navigation_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/app_database.dart' as local_db;
import '../../data/repositories/memory_repository.dart';
import '../../shared/models/travelmate_models.dart';
import '../../shared/widgets/glass_box.dart';
import '../../shared/widgets/memory_capsule_card.dart';
import '../settings/data/settings_data_service.dart';
import '../trip/data/trip_dashboard_service.dart';

/// 记忆胶囊页面
class MemoryPage extends StatefulWidget {
  const MemoryPage({
    super.key,
    this.database,
    this.repository,
    this.dashboardService,
    this.syncService,
  });

  final local_db.AppDatabase? database;
  final MemoryRepository? repository;
  final TripDashboardService? dashboardService;
  final SettingsDataService? syncService;

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  int _selectedTab = 0;
  late final local_db.AppDatabase _database;
  late final MemoryRepository _repository;
  late final TripDashboardService _dashboardService;
  late final SettingsDataService _syncService;
  late final bool _ownsDatabase;
  List<ConfirmedMemory> _storedMemories = [];
  List<Map<String, dynamic>> _dashboardMemories = [];
  final Set<String> _selectedMemoryIds = {};
  String? _syncMessage;

  static const _tabs = ['全部', '长期', '本次', '临时'];

  @override
  void initState() {
    super.initState();
    _ownsDatabase = widget.database == null;
    _database = widget.database ?? local_db.AppDatabase();
    _repository = widget.repository ?? MemoryRepository(_database);
    _dashboardService = widget.dashboardService ?? TripDashboardService();
    _syncService = widget.syncService ?? SettingsDataService();
    _loadStoredMemories();
    _loadDashboardMemories();
  }

  @override
  void dispose() {
    if (_ownsDatabase) {
      _database.close();
    }
    super.dispose();
  }

  Future<void> _loadStoredMemories() async {
    final memories = await _repository.listMemories();
    if (!mounted) return;
    setState(() => _storedMemories = memories);
  }

  Future<void> _loadDashboardMemories() async {
    final dashboard = await _dashboardService.fetchDashboard();
    if (!mounted) return;
    setState(() => _dashboardMemories = dashboard.memories);
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
    final localIds = _storedMemories.map((memory) => memory.id).toSet();
    final dashboardItems = _dashboardMemories
        .where((memory) => !localIds.contains(memory['id']?.toString()))
        .map(_memoryFromDashboard);
    return [...storedItems, ...dashboardItems];
  }

  _MemoryDisplayItem _memoryFromDashboard(Map<String, dynamic> memory) {
    return _MemoryDisplayItem(
      capsule: MemoryCapsule(
        id: memory['id']?.toString() ?? 'cloud-memory',
        title: memory['title']?.toString() ?? 'Cloud memory',
        content: memory['content']?.toString() ?? '',
        scope: _scopeFromStorage(memory['scope']?.toString() ?? ''),
        createdAt: _formatDashboardDate(memory['createdAt']?.toString()),
        tags: const ['cloud'],
        isNew: true,
      ),
    );
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

  String _formatDashboardDate(String? value) {
    if (value == null || value.length < 10) return _formatDate(DateTime.now());
    return value.substring(0, 10);
  }

  Future<void> _deleteStoredMemory(String id) async {
    await _repository.deleteMemory(id);
    _selectedMemoryIds.remove(id);
    await _loadStoredMemories();
  }

  Future<void> _syncSelectedMemories() async {
    final selected = _storedMemories
        .where((memory) => _selectedMemoryIds.contains(memory.id))
        .toList(growable: false);
    if (selected.isEmpty) {
      setState(() => _syncMessage = '请选择要同步的本地记忆');
      return;
    }
    final result = await _syncService.pushSync(
      memories: selected.map(_memoryToSyncDraft).toList(growable: false),
    );
    if (result.status != 'offline' && result.conflicts.isEmpty) {
      final pending = await _repository.listPendingSyncOperations(
        entityType: 'memory',
        operation: 'upsert',
      );
      final selectedIds = selected.map((memory) => memory.id).toSet();
      await _repository.markSyncOperationsSucceeded(
        pending
            .where((item) => selectedIds.contains(item.entityId))
            .map((item) => item.id)
            .toList(growable: false),
      );
    }
    if (!mounted) return;
    setState(() {
      if (result.status == 'offline') {
        _syncMessage = '同步失败，已保留到本机队列';
      } else if (result.conflicts.isNotEmpty) {
        _syncMessage = '检测到同步冲突，请到设置页合并';
      } else {
        _syncMessage = '已同步 ${selected.length} 条已选记忆';
        _selectedMemoryIds.clear();
      }
    });
  }

  SyncMemoryDraft _memoryToSyncDraft(ConfirmedMemory memory) {
    return SyncMemoryDraft(
      id: memory.id,
      title: memory.title,
      content: memory.content,
      scope: memory.scope,
      updatedAt: memory.updatedAt.toUtc().toIso8601String(),
    );
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
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: '内容'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存'),
          ),
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
    final metrics = context.responsive;
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
              padding: EdgeInsets.symmetric(
                horizontal: metrics.horizontalPadding - 8,
                vertical: 4,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => navigateBackOrHome(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      '记忆胶囊',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('sync-selected-memories'),
                    tooltip: '同步已选记忆',
                    onPressed: _syncSelectedMemories,
                    icon: const Icon(
                      Icons.cloud_upload_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (_syncMessage != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding,
                ),
                child: GlassBox(
                  opacity: 0.16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _syncMessage!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // 筛选标签
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.horizontalPadding,
                vertical: AppTheme.spacingSm,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final selected = _selectedTab == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = i),
                        child: GlassBox(
                          opacity: selected ? 0.35 : 0.12,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // 记忆胶囊列表
            Expanded(
              child: _filtered.isEmpty
                  ? _EmptyMemoryState(
                      onRetry: () {
                        _loadStoredMemories();
                        _loadDashboardMemories();
                      },
                      onOpenChat: () => context.push('/chat'),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: metrics.listBottomPadding + 48,
                      ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingLg,
                              ),
                              child: Row(
                                children: [
                                  Material(
                                    type: MaterialType.transparency,
                                    child: Checkbox(
                                      key: ValueKey(
                                        'select-memory-${item.storedId}',
                                      ),
                                      value: _selectedMemoryIds.contains(
                                        item.storedId,
                                      ),
                                      onChanged: (selected) {
                                        setState(() {
                                          if (selected == true) {
                                            _selectedMemoryIds.add(
                                              item.storedId!,
                                            );
                                          } else {
                                            _selectedMemoryIds.remove(
                                              item.storedId,
                                            );
                                          }
                                        });
                                      },
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const Text(
                                    '选择同步',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => _editStoredMemory(item),
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('编辑'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _deleteStoredMemory(item.storedId!),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                    ),
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

class _EmptyMemoryState extends StatelessWidget {
  const _EmptyMemoryState({required this.onRetry, required this.onOpenChat});

  final VoidCallback onRetry;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return ListView(
      padding: EdgeInsets.only(
        left: metrics.horizontalPadding,
        right: metrics.horizontalPadding,
        top: AppTheme.spacingLg,
        bottom: metrics.listBottomPadding + 48,
      ),
      children: [
        GlassBox(
          opacity: 0.18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bubble_chart_outlined, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '暂无记忆胶囊',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              const Text(
                '测试方法：先去蓝小心聊天，说“我不吃香菜、喜欢轻松慢游”，出现“确认记忆胶囊”后点确认；返回这里即可看到保存的偏好。',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              const Text(
                '复盘页产生的新增记忆，也会在确认沉淀后同步到这里。',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('memory-retry-load'),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('重试加载'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('memory-open-chat'),
                      onPressed: onOpenChat,
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text('去聊天生成'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemoryDisplayItem {
  const _MemoryDisplayItem({required this.capsule, this.storedId});

  final MemoryCapsule capsule;
  final String? storedId;
}
