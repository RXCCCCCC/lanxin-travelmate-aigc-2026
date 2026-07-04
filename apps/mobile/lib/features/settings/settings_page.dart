import 'package:flutter/material.dart';

import '../../core/layout/responsive_metrics.dart';
import '../../core/router/navigation_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/app_database.dart' as local_db;
import '../../data/repositories/memory_repository.dart';
import '../../shared/widgets/glass_box.dart';
import '../profile/data/profile_service.dart';
import 'data/settings_data_service.dart';
import 'data/sync_retry_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.profileService,
    this.dataService,
    this.memoryRepository,
  });

  final ProfileService? profileService;
  final SettingsDataService? dataService;
  final MemoryRepository? memoryRepository;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final ProfileService _profileService;
  late final SettingsDataService _dataService;
  late final MemoryRepository _memoryRepository;
  late final SyncRetryService _syncRetryService;
  local_db.AppDatabase? _ownedDatabase;
  ProfilePayload? _profile;
  PrivacySummaryPayload? _privacySummary;
  List<PendingSyncOperation> _syncHistory = const [];
  String? _dataActionMessage;
  SyncPushResult? _syncPushResult;
  bool _loading = true;
  bool _saving = false;

  static const _personalityOptions = <_OptionItem>[
    _OptionItem('gentle_companion', '温柔陪伴'),
    _OptionItem('quiet_planner', '安静规划师'),
    _OptionItem('energetic_guide', '活力向导'),
    _OptionItem('careful_butler', '细心管家'),
  ];

  static const _proactivityOptions = <_OptionItem>[
    _OptionItem('quiet', '安静'),
    _OptionItem('standard', '标准'),
    _OptionItem('active', '主动'),
  ];

  static const _syncOptions = <_OptionItem>[
    _OptionItem('all', '全部同步'),
    _OptionItem('selectedOnly', '仅已选择'),
    _OptionItem('localOnly', '仅本机'),
  ];

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? ProfileService();
    _dataService = widget.dataService ?? SettingsDataService();
    if (widget.memoryRepository != null) {
      _memoryRepository = widget.memoryRepository!;
    } else {
      _ownedDatabase = local_db.AppDatabase();
      _memoryRepository = MemoryRepository(_ownedDatabase!);
    }
    _syncRetryService = SyncRetryService(
      repository: _memoryRepository,
      dataService: _dataService,
    );
    _loadProfile();
    _loadPrivacySummary();
    _loadSyncHistory();
  }

  @override
  void dispose() {
    _ownedDatabase?.close();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.fetchProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Future<void> _loadPrivacySummary() async {
    final summary = await _dataService.fetchPrivacySummary();
    if (!mounted) return;
    setState(() => _privacySummary = summary);
  }

  Future<void> _loadSyncHistory() async {
    final history = await _memoryRepository.listSyncOperations();
    if (!mounted) return;
    setState(() => _syncHistory = history);
  }

  Future<void> _save(ProfilePayload profile) async {
    setState(() {
      _profile = profile;
      _saving = true;
    });
    final saved = await _profileService.updateProfile(profile: profile);
    if (!mounted) return;
    setState(() {
      _profile = saved;
      _saving = false;
    });
  }

  Future<void> _exportMemories() async {
    final result = await _dataService.exportMemories();
    if (!mounted) return;
    setState(() {
      _dataActionMessage = result.status == 'ok'
          ? '已导出 ${result.itemCount} 条记忆'
          : '导出失败，请检查网络后重试';
    });
  }

  Future<void> _clearAllMemories() async {
    final confirmed = await _confirmDestructiveAction(
      title: '清空全部记忆',
      message: '这会删除云端已保存的记忆胶囊，已确认后再执行。',
    );
    if (!confirmed) return;
    final result = await _dataService.clearAllMemories();
    if (!mounted) return;
    setState(() {
      _dataActionMessage = result.status == 'ok'
          ? '已清空 ${result.deleted} 条记忆'
          : '清空失败，请检查网络后重试';
    });
  }

  Future<void> _clearCurrentTrip() async {
    final confirmed = await _confirmDestructiveAction(
      title: '清空当前旅行',
      message: '这会清除当前旅行计划、轨迹和复盘关联数据。',
    );
    if (!confirmed) return;
    final result = await _dataService.clearCurrentTrip();
    if (!mounted) return;
    setState(() {
      _dataActionMessage = result.status == 'ok'
          ? '已清空 ${result.deleted} 个当前旅行记录'
          : '清空失败，请检查网络后重试';
    });
  }

  Future<void> _revokeProfileSync() async {
    final confirmed = await _confirmDestructiveAction(
      title: '撤销云端画像同步',
      message: '这会删除云端保存的画像副本，本机设置仍可继续使用。',
    );
    if (!confirmed) return;
    final result = await _dataService.revokeCloudSync(revokeProfile: true);
    if (!mounted) return;
    final profileCount = result.revoked['profile'] as int? ?? 0;
    setState(() {
      _dataActionMessage = result.status == 'ok'
          ? '已撤销 $profileCount 个云端画像副本'
          : '撤销失败，请检查网络后重试';
    });
  }

  Future<void> _revokeSelectedSync(
    List<String> memoryIds,
    List<String> tripIds,
  ) async {
    if (memoryIds.isEmpty && tripIds.isEmpty) {
      setState(() {
        _dataActionMessage =
            '\u{8BF7}\u{5148}\u{586B}\u{5199}\u{8981}\u{64A4}\u{9500}\u{7684}\u{8BB0}\u{5FC6} ID \u{6216}\u{65C5}\u{7A0B} ID';
      });
      return;
    }
    final confirmed = await _confirmDestructiveAction(
      title: '\u{64A4}\u{9500}\u{6307}\u{5B9A}\u{540C}\u{6B65}',
      message:
          '\u{8FD9}\u{4F1A}\u{5220}\u{9664}\u{6307}\u{5B9A}\u{8BB0}\u{5FC6}\u{6216}\u{65C5}\u{7A0B}\u{7684}\u{4E91}\u{7AEF}\u{526F}\u{672C}\u{FF0C}\u{4E0D}\u{4F1A}\u{5F71}\u{54CD}\u{672C}\u{673A}\u{6570}\u{636E}\u{3002}',
    );
    if (!confirmed) return;
    final result = await _dataService.revokeCloudSync(
      memoryIds: memoryIds,
      tripIds: tripIds,
    );
    if (!mounted) return;
    final memoryCount = result.revoked['memories'] as int? ?? 0;
    final tripCount = result.revoked['trips'] as int? ?? 0;
    setState(() {
      _dataActionMessage = result.status == 'ok'
          ? '\u{5DF2}\u{64A4}\u{9500} $memoryCount \u{6761}\u{8BB0}\u{5FC6}\u{548C} $tripCount \u{4E2A}\u{65C5}\u{7A0B}\u{4E91}\u{7AEF}\u{526F}\u{672C}'
          : '\u{64A4}\u{9500}\u{5931}\u{8D25}\u{FF0C}\u{8BF7}\u{68C0}\u{67E5}\u{7F51}\u{7EDC}\u{540E}\u{91CD}\u{8BD5}';
    });
  }

  Future<void> _pushSyncDraft(
    SyncMemoryDraft draft,
    String conflictStrategy,
  ) async {
    final result = await _dataService.pushSync(
      conflictStrategy: conflictStrategy,
      memories: [draft],
    );
    if (!mounted) return;
    setState(() {
      _syncPushResult = result;
      if (result.status == 'offline') {
        _dataActionMessage =
            '\u{540C}\u{6B65}\u{5931}\u{8D25}\u{FF0C}\u{8BF7}\u{68C0}\u{67E5}\u{7F51}\u{7EDC}\u{540E}\u{91CD}\u{8BD5}';
      } else if (result.conflicts.isEmpty) {
        _dataActionMessage =
            '\u{672A}\u{68C0}\u{6D4B}\u{5230}\u{540C}\u{6B65}\u{51B2}\u{7A81}';
      } else {
        _dataActionMessage = conflictStrategy == 'clientWins'
            ? '\u{5DF2}\u{4F7F}\u{7528}\u{672C}\u{673A}\u{7248}\u{672C}\u{8986}\u{76D6}\u{4E91}\u{7AEF}'
            : '\u{5DF2}\u{68C0}\u{6D4B}\u{5230}\u{51B2}\u{7A81}\u{FF0C}\u{9ED8}\u{8BA4}\u{4FDD}\u{7559}\u{4E91}\u{7AEF}\u{7248}\u{672C}';
      }
    });
  }

  Future<void> _syncLocalMemories() async {
    final pending = await _memoryRepository.listPendingSyncOperations();
    if (pending.isNotEmpty) {
      final result = await _syncRetryService.retryPendingOperations();
      final remaining = await _memoryRepository.listPendingSyncOperations();
      final history = await _memoryRepository.listSyncOperations();
      if (!mounted) return;
      setState(() {
        _syncHistory = history;
        _syncPushResult = null;
        if (result.failedOperations > 0) {
          _dataActionMessage =
              '\u{540C}\u{6B65}\u{5931}\u{8D25}\u{FF0C}\u{5DF2}\u{4FDD}\u{7559}\u{5230}\u{672C}\u{673A}\u{961F}\u{5217}\u{7B49}\u{5F85}\u{91CD}\u{8BD5}';
        } else if (result.conflicts > 0) {
          _dataActionMessage =
              '\u{5DF2}\u{68C0}\u{6D4B}\u{5230}\u{540C}\u{6B65}\u{51B2}\u{7A81}\u{FF0C}\u{8BF7}\u{786E}\u{8BA4}\u{5408}\u{5E76}\u{7B56}\u{7565}';
        } else {
          _dataActionMessage =
              '\u{5DF2}\u{5904}\u{7406} ${result.handledOperations} \u{6761}\u{961F}\u{5217}\u{540C}\u{6B65}\u{FF0C}\u{5269}\u{4F59} ${remaining.length} \u{6761}\u{5F85}\u{5904}\u{7406}';
        }
      });
      return;
    }
    final memories = await _memoryRepository.listMemories();
    if (memories.isEmpty) {
      if (!mounted) return;
      setState(() {
        _dataActionMessage =
            '\u{672C}\u{673A}\u{6682}\u{65E0}\u{53EF}\u{540C}\u{6B65}\u{8BB0}\u{5FC6}';
      });
      return;
    }
    final result = await _dataService.pushSync(
      memories: memories.map(_memoryToSyncDraft).toList(growable: false),
    );
    final history = await _memoryRepository.listSyncOperations();
    if (!mounted) return;
    setState(() {
      _syncHistory = history;
      _syncPushResult = result;
      if (result.status == 'offline') {
        _dataActionMessage =
            '\u{540C}\u{6B65}\u{5931}\u{8D25}\u{FF0C}\u{8BF7}\u{68C0}\u{67E5}\u{7F51}\u{7EDC}\u{540E}\u{91CD}\u{8BD5}';
      } else {
        final pushed = result.pushed['memories'] as int? ?? memories.length;
        _dataActionMessage =
            '\u{5DF2}\u{540C}\u{6B65} $pushed \u{6761}\u{672C}\u{673A}\u{8BB0}\u{5FC6}';
      }
    });
  }

  Future<bool> _confirmDestructiveAction({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const ValueKey('confirm-destructive-action'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  ProfilePayload _currentProfile() => _profile ?? ProfilePayload.fallback();

  ProfilePayload _copyProfile({
    String? personality,
    String? proactivityLevel,
    String? syncStrategy,
    bool? notificationEnabled,
    bool? voiceEnabled,
    bool? textModePreferred,
    String? customPrompt,
  }) {
    final current = _currentProfile();
    return ProfilePayload(
      userId: current.userId,
      travelPace: current.travelPace,
      dietaryPreferences: current.dietaryPreferences,
      interestTags: current.interestTags,
      transportPreferences: current.transportPreferences,
      budgetPreference: current.budgetPreference,
      personality: personality ?? current.personality,
      proactivityLevel: proactivityLevel ?? current.proactivityLevel,
      syncStrategy: syncStrategy ?? current.syncStrategy,
      notificationEnabled: notificationEnabled ?? current.notificationEnabled,
      voiceEnabled: voiceEnabled ?? current.voiceEnabled,
      textModePreferred: textModePreferred ?? current.textModePreferred,
      customPrompt: customPrompt ?? current.customPrompt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final profile = _currentProfile();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.bgTop, AppTheme.bgMid, AppTheme.bgBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.horizontalPadding - 8,
                vertical: 4,
              ),
              child: SizedBox(
                height: metrics.topBarHeight,
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
                        '设置',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: _saving
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.cloud_done_rounded,
                              color: AppTheme.primary,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AdaptiveContentWidth(
                child: ListView(
                  padding: metrics.listPadding(top: AppTheme.spacingSm),
                  children: [
                    _ProfileSettingsSummary(
                      profile: profile,
                      loading: _loading,
                    ),
                    SizedBox(height: metrics.sectionGap),
                    _SettingsSection(
                      title: '蓝小心人格',
                      icon: Icons.face_rounded,
                      child: _OptionWrap(
                        options: _personalityOptions,
                        selectedValue: profile.personality,
                        onSelected: (value) =>
                            _save(_copyProfile(personality: value)),
                      ),
                    ),
                    _SettingsSection(
                      title: '主动程度',
                      icon: Icons.tune_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _OptionWrap(
                            options: _proactivityOptions,
                            selectedValue: profile.proactivityLevel,
                            onSelected: (value) =>
                                _save(_copyProfile(proactivityLevel: value)),
                            showRawValue: true,
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          _HintLine(
                            text: _proactivityHint(profile.proactivityLevel),
                          ),
                        ],
                      ),
                    ),
                    _SettingsSection(
                      title: '同步策略',
                      icon: Icons.cloud_sync_rounded,
                      child: _OptionWrap(
                        options: _syncOptions,
                        selectedValue: profile.syncStrategy,
                        onSelected: (value) =>
                            _save(_copyProfile(syncStrategy: value)),
                        showRawValue: true,
                      ),
                    ),
                    _SettingsSection(
                      title: '通知与输入',
                      icon: Icons.notifications_rounded,
                      child: Column(
                        children: [
                          _ToggleItem(
                            title: '主动提醒',
                            subtitle: '饭点、天气、路线变化时允许蓝小心提醒',
                            value: profile.notificationEnabled,
                            onChanged: (value) =>
                                _save(_copyProfile(notificationEnabled: value)),
                          ),
                          _ToggleItem(
                            title: '语音播报',
                            subtitle: '行程提醒与复盘支持语音表达',
                            value: profile.voiceEnabled,
                            onChanged: (value) =>
                                _save(_copyProfile(voiceEnabled: value)),
                          ),
                          _ToggleItem(
                            title: '优先文字模式',
                            subtitle: '弱网或安静场景下优先展示文字回复',
                            value: profile.textModePreferred,
                            onChanged: (value) =>
                                _save(_copyProfile(textModePreferred: value)),
                          ),
                        ],
                      ),
                    ),
                    _SettingsSection(
                      title: '自定义提示词',
                      icon: Icons.record_voice_over_rounded,
                      child: _PromptEditor(
                        initialValue: profile.customPrompt ?? '',
                        onSubmitted: (value) =>
                            _save(_copyProfile(customPrompt: value.trim())),
                      ),
                    ),
                    _SettingsSection(
                      title: '数据与隐私',
                      icon: Icons.privacy_tip_rounded,
                      child: _PrivacyDataControls(
                        summary: _privacySummary,
                        actionMessage: _dataActionMessage,
                        onExport: _exportMemories,
                        onClearMemories: _clearAllMemories,
                        onClearTrip: _clearCurrentTrip,
                        onRevokeProfileSync: _revokeProfileSync,
                        onRevokeSelectedSync: _revokeSelectedSync,
                        syncPushResult: _syncPushResult,
                        syncHistory: _syncHistory,
                        onPushSyncDraft: _pushSyncDraft,
                        onSyncLocalMemories: _syncLocalMemories,
                      ),
                    ),
                    _SettingsSection(
                      title: '关于',
                      icon: Icons.info_outline_rounded,
                      child: const GlassBox(
                        opacity: 0.12,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.smart_toy_rounded,
                              size: 24,
                              color: AppTheme.primary,
                            ),
                            SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '蓝心同行',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'v1.0.0',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _proactivityHint(String value) {
  return switch (value) {
    'quiet' => '仅在高风险或你明确请求时主动打扰。',
    'active' => '会更积极地发现附近机会、风险和路线变化。',
    _ => '保持标准频率，兼顾提醒和安静体验。',
  };
}

class _OptionItem {
  const _OptionItem(this.value, this.label);

  final String value;
  final String label;
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return Padding(
      padding: EdgeInsets.only(bottom: metrics.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          child,
        ],
      ),
    );
  }
}

class _ProfileSettingsSummary extends StatelessWidget {
  const _ProfileSettingsSummary({required this.profile, required this.loading});

  final ProfilePayload profile;
  final bool loading;

  String _labelForOption(List<_OptionItem> options, String value) {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                loading ? Icons.sync_rounded : Icons.verified_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loading ? '正在读取真实设置' : '已连接个人设置',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SettingValueChip(
                label: _labelForOption(
                  _SettingsPageState._personalityOptions,
                  profile.personality,
                ),
              ),
              _SettingValueChip(
                label: _labelForOption(
                  _SettingsPageState._proactivityOptions,
                  profile.proactivityLevel,
                ),
              ),
              _SettingValueChip(
                label: _labelForOption(
                  _SettingsPageState._syncOptions,
                  profile.syncStrategy,
                ),
              ),
              _SettingValueChip(
                label: profile.notificationEnabled ? '主动提醒已开启' : '主动提醒已关闭',
              ),
              _SettingValueChip(
                label: profile.voiceEnabled ? '语音已开启' : '语音已关闭',
              ),
              _SettingValueChip(
                label: profile.textModePreferred ? '优先文字' : '文字优先关闭',
              ),
            ],
          ),
          if ((profile.customPrompt ?? '').isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              profile.customPrompt!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionWrap extends StatelessWidget {
  const _OptionWrap({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.showRawValue = false,
  });

  final List<_OptionItem> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;
  final bool showRawValue;

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final selected = option.value == selectedValue;
          return GestureDetector(
            onTap: () => onSelected(option.value),
            child: _SettingValueChip(label: option.label, selected: selected),
          );
        }).toList(),
      ),
    );
  }
}

class _SettingValueChip extends StatelessWidget {
  const _SettingValueChip({
    required this.label,
    this.helper,
    this.selected = false,
  });

  final String label;
  final String? helper;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return Container(
      constraints: BoxConstraints(minHeight: metrics.minTouchTarget - 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withOpacity(0.2)
            : Colors.white.withOpacity(0.24),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: selected
              ? AppTheme.primary.withOpacity(0.36)
              : Colors.white.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 1),
            Text(
              helper!,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HintLine extends StatelessWidget {
  const _HintLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return GlassBox(
      opacity: 0.12,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SwitchListTile(
        minTileHeight: metrics.minTouchTarget,
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        activeColor: AppTheme.primary,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _PrivacyDataControls extends StatelessWidget {
  const _PrivacyDataControls({
    required this.summary,
    required this.actionMessage,
    required this.onExport,
    required this.onClearMemories,
    required this.onClearTrip,
    required this.onRevokeProfileSync,
    required this.onRevokeSelectedSync,
    required this.syncPushResult,
    required this.syncHistory,
    required this.onPushSyncDraft,
    required this.onSyncLocalMemories,
  });

  final PrivacySummaryPayload? summary;
  final String? actionMessage;
  final VoidCallback onExport;
  final VoidCallback onClearMemories;
  final VoidCallback onClearTrip;
  final VoidCallback onRevokeProfileSync;
  final void Function(List<String> memoryIds, List<String> tripIds)
  onRevokeSelectedSync;
  final SyncPushResult? syncPushResult;
  final List<PendingSyncOperation> syncHistory;
  final void Function(SyncMemoryDraft draft, String conflictStrategy)
  onPushSyncDraft;
  final VoidCallback onSyncLocalMemories;

  @override
  Widget build(BuildContext context) {
    final current = summary ?? PrivacySummaryPayload.fallback();
    final firstPermissions = current.permissions.take(3).toList();
    return GlassBox(
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final principle in current.principles.take(2))
            _InfoRow(icon: Icons.check_circle_rounded, text: principle),
          if (firstPermissions.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: firstPermissions
                  .map(
                    (item) => _SettingValueChip(
                      label: item.label,
                      helper: _permissionHelperText(item.fallback),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (actionMessage != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            _InfoRow(icon: Icons.done_rounded, text: actionMessage!),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          _DataActionTile(
            icon: Icons.download_rounded,
            title: '导出记忆',
            subtitle: '导出云端保存内容，便于人工检查',
            onTap: onExport,
          ),
          _DataActionTile(
            key: const ValueKey('sync-local-memories-button'),
            icon: Icons.sync_rounded,
            title: '\u{540C}\u{6B65}\u{672C}\u{673A}\u{8BB0}\u{5FC6}',
            subtitle:
                '\u{5C06}\u{672C}\u{673A}\u{5DF2}\u{786E}\u{8BA4}\u{8BB0}\u{5FC6}\u{540C}\u{6B65}\u{5230}\u{4E91}\u{7AEF}',
            onTap: onSyncLocalMemories,
          ),
          _SyncHistoryPanel(history: syncHistory),
          _DataActionTile(
            icon: Icons.cloud_off_rounded,
            title: '撤销云端画像同步',
            subtitle: '仅撤销云端画像副本，本机设置继续保留',
            onTap: onRevokeProfileSync,
          ),
          _RevokeSelectedSyncPanel(onSubmit: onRevokeSelectedSync),
          _SyncConflictPanel(result: syncPushResult, onSubmit: onPushSyncDraft),
          _DataActionTile(
            icon: Icons.route_rounded,
            title: '清空当前旅行',
            subtitle: '删除当前旅程数据，保留长期记忆',
            destructive: true,
            onTap: onClearTrip,
          ),
          _DataActionTile(
            icon: Icons.delete_outline_rounded,
            title: '清空全部记忆',
            subtitle: '删除云端记忆胶囊，执行前会二次确认',
            destructive: true,
            onTap: onClearMemories,
          ),
        ],
      ),
    );
  }
}

class _DataActionTile extends StatelessWidget {
  const _DataActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final color = destructive ? const Color(0xFFB42318) : AppTheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: Material(
        color: Colors.white.withOpacity(0.24),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: metrics.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: destructive ? color : AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: color, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncHistoryPanel extends StatelessWidget {
  const _SyncHistoryPanel({required this.history});

  final List<PendingSyncOperation> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: Container(
        key: const ValueKey('sync-history-panel'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.24),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: Colors.white.withOpacity(0.26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, color: AppTheme.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '\u{540C}\u{6B65}\u{5386}\u{53F2}',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            for (final item in history.take(4)) _SyncHistoryRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _SyncHistoryRow extends StatelessWidget {
  const _SyncHistoryRow({required this.item});

  final PendingSyncOperation item;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.status == 'synced'
        ? const Color(0xFF217A4B)
        : AppTheme.primary;
    final operation = _syncOperationLabel(item.entityType, item.operation);
    final status = _syncStatusLabel(item.status);
    final detail = item.lastError == null || item.lastError!.isEmpty
        ? '对象：${item.entityId}'
        : '对象：${item.entityId}；错误：${item.lastError}';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle_rounded, color: statusColor, size: 10),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$operation · $status',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevokeSelectedSyncPanel extends StatefulWidget {
  const _RevokeSelectedSyncPanel({required this.onSubmit});

  final void Function(List<String> memoryIds, List<String> tripIds) onSubmit;

  @override
  State<_RevokeSelectedSyncPanel> createState() =>
      _RevokeSelectedSyncPanelState();
}

class _RevokeSelectedSyncPanelState extends State<_RevokeSelectedSyncPanel> {
  final _memoryController = TextEditingController();
  final _tripController = TextEditingController();

  @override
  void dispose() {
    _memoryController.dispose();
    _tripController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.24),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: Colors.white.withOpacity(0.26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.fact_check_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '\u{64A4}\u{9500}\u{6307}\u{5B9A}\u{540C}\u{6B65}',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              key: const ValueKey('revoke-memory-ids-field'),
              controller: _memoryController,
              minLines: 1,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: _revokeInputDecoration(
                label: '\u{8BB0}\u{5FC6}\u{7F16}\u{53F7}',
                hint: '记忆编号，用逗号分隔',
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              key: const ValueKey('revoke-trip-ids-field'),
              controller: _tripController,
              minLines: 1,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: _revokeInputDecoration(
                label: '\u{65C5}\u{7A0B}\u{7F16}\u{53F7}',
                hint: '旅程编号',
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('revoke-selected-sync-button'),
                onPressed: () => widget.onSubmit(
                  _splitIds(_memoryController.text),
                  _splitIds(_tripController.text),
                ),
                icon: const Icon(Icons.cloud_off_rounded, size: 18),
                label: const Text(
                  '\u{64A4}\u{9500}\u{6307}\u{5B9A}\u{540C}\u{6B65}',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(metrics.minTouchTarget),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncConflictPanel extends StatefulWidget {
  const _SyncConflictPanel({required this.result, required this.onSubmit});

  final SyncPushResult? result;
  final void Function(SyncMemoryDraft draft, String conflictStrategy) onSubmit;

  @override
  State<_SyncConflictPanel> createState() => _SyncConflictPanelState();
}

class _SyncConflictPanelState extends State<_SyncConflictPanel> {
  final _idController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final conflict = widget.result?.conflicts.isNotEmpty == true
        ? widget.result!.conflicts.first
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.24),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: Colors.white.withOpacity(0.26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '\u{540C}\u{6B65}\u{51B2}\u{7A81}\u{5408}\u{5E76}',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              key: const ValueKey('sync-conflict-memory-id-field'),
              controller: _idController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: _revokeInputDecoration(
                label: '\u{8BB0}\u{5FC6}\u{7F16}\u{53F7}',
                hint: '记忆编号',
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              key: const ValueKey('sync-conflict-title-field'),
              controller: _titleController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: _revokeInputDecoration(
                label: '\u{672C}\u{673A}\u{6807}\u{9898}',
                hint: '本机版本标题',
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              key: const ValueKey('sync-conflict-content-field'),
              controller: _contentController,
              minLines: 1,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: _revokeInputDecoration(
                label: '\u{672C}\u{673A}\u{5185}\u{5BB9}',
                hint: '本机版本内容',
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('detect-sync-conflict-button'),
                    onPressed: () => widget.onSubmit(_draft(), 'serverWins'),
                    icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                    label: const Text('\u{68C0}\u{6D4B}\u{51B2}\u{7A81}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.fromHeight(metrics.minTouchTarget),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('resolve-sync-client-wins-button'),
                    onPressed: () => widget.onSubmit(_draft(), 'clientWins'),
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('\u{672C}\u{673A}\u{8986}\u{76D6}'),
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(metrics.minTouchTarget),
                    ),
                  ),
                ),
              ],
            ),
            if (conflict != null) ...[
              const SizedBox(height: AppTheme.spacingSm),
              _InfoRow(
                icon: Icons.warning_amber_rounded,
                text:
                    '记忆 ${conflict.entityId} 发现冲突，当前处理：${_conflictResolutionLabel(conflict.resolution)}；云端：${conflict.server['title'] ?? ''}；本机：${conflict.client['title'] ?? ''}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  SyncMemoryDraft _draft() {
    final id = _idController.text.trim().isEmpty
        ? 'memory-draft'
        : _idController.text.trim();
    final title = _titleController.text.trim().isEmpty
        ? '本机记忆标题'
        : _titleController.text.trim();
    final content = _contentController.text.trim().isEmpty
        ? title
        : _contentController.text.trim();
    return SyncMemoryDraft(
      id: id,
      title: title,
      content: content,
      scope: 'longTerm',
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }
}

InputDecoration _revokeInputDecoration({
  required String label,
  required String hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.72)),
    labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
    filled: true,
    fillColor: Colors.white.withOpacity(0.32),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
    ),
    isDense: true,
  );
}

List<String> _splitIds(String value) {
  return value
      .split(RegExp(r'[\s,;]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _syncOperationLabel(String entityType, String operation) {
  final entity = switch (entityType) {
    'memory' || 'memories' => '记忆',
    'trip' || 'trips' => '旅程',
    'profile' => '画像',
    _ => '数据',
  };
  final action = switch (operation) {
    'upsert' || 'create' || 'update' => '同步',
    'delete' || 'revoke' => '撤销',
    _ => '处理',
  };
  return '$entity$action';
}

String _syncStatusLabel(String status) {
  return switch (status) {
    'synced' => '已同步',
    'pending' => '待同步',
    'failed' => '同步失败',
    'offline' => '离线待重试',
    _ => '处理中',
  };
}

String _conflictResolutionLabel(String resolution) {
  return switch (resolution) {
    'serverWins' => '保留云端版本',
    'clientWins' => '使用本机版本',
    'manual' => '等待手动确认',
    _ => '等待确认',
  };
}

String _permissionHelperText(String fallback) {
  final value = fallback.trim();
  if (value.isEmpty) return '按需授权';
  return switch (value) {
    'unconfigured' => '尚未配置',
    'fallback' => '使用降级方案',
    'denied' => '权限未允许',
    'offline' => '离线可用',
    _ => value,
  };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptEditor extends StatefulWidget {
  const _PromptEditor({required this.initialValue, required this.onSubmitted});

  final String initialValue;
  final ValueChanged<String> onSubmitted;

  @override
  State<_PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<_PromptEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _PromptEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onSubmitted: widget.onSubmitted,
            onEditingComplete: () => widget.onSubmitted(_controller.text),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              height: 1.35,
            ),
            decoration: InputDecoration(
              hintText: '例如：少打扰，但在风险和高价值发现时主动提醒。',
              hintStyle: TextStyle(
                color: AppTheme.textMuted.withOpacity(0.72),
                fontSize: 12,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.32),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => widget.onSubmitted(_controller.text),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
