import 'package:flutter/material.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/adaptive_chrome.dart';
import '../../shared/widgets/glass_box.dart';
import '../trip/data/trip_dashboard_service.dart';
import 'data/photo_experience_service.dart';

/// 旅拍候选页面
class PhotoPage extends StatefulWidget {
  const PhotoPage({
    super.key,
    this.photoExperienceService,
    this.dashboardService,
  });

  final PhotoExperienceService? photoExperienceService;
  final TripDashboardService? dashboardService;

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  late final PhotoExperienceService _photoExperienceService;
  late final TripDashboardService _dashboardService;
  late Future<void> _loadFuture;
  List<Map<String, dynamic>> _candidates = const [];
  List<Map<String, dynamic>> _tasks = const [];
  Map<String, dynamic>? _copywriting;
  bool _isGenerating = false;
  bool _isRegistering = false;
  final Set<String> _updatingTaskIds = {};
  String? _photoNotice;

  @override
  void initState() {
    super.initState();
    _photoExperienceService =
        widget.photoExperienceService ?? PhotoExperienceService();
    _dashboardService = widget.dashboardService ?? TripDashboardService();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final dashboard = await _dashboardService.fetchDashboard();
    _candidates = dashboard.photoCandidates;
    _tasks = dashboard.blindBoxTasks;
    if (_candidates.isNotEmpty && _tasks.isNotEmpty) return;

    final results = await Future.wait([
      if (_candidates.isEmpty) _photoExperienceService.fetchCandidates(),
      if (_tasks.isEmpty) _photoExperienceService.fetchBlindBoxTasks(),
    ]);
    var index = 0;
    if (_candidates.isEmpty) {
      _candidates = results[index++];
    }
    if (_tasks.isEmpty) {
      _tasks = results[index];
    }
  }

  void _retryLoad() {
    setState(() {
      _photoNotice = null;
      _candidates = const [];
      _tasks = const [];
      _copywriting = null;
      _loadFuture = _load();
    });
  }

  Future<void> _registerManualCandidate() async {
    if (_isRegistering) return;
    setState(() {
      _isRegistering = true;
      _photoNotice = null;
    });
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final upload = await _photoExperienceService.createUploadMetadata(
      filename: 'user-import-$timestamp.jpg',
      contentType: 'image/jpeg',
    );
    final candidate = await _photoExperienceService.createCandidate(
      id: 'manual-photo-$timestamp',
      remoteUrl: upload['remoteUrl']?.toString(),
      location: '手动导入照片',
      score: 8.6,
      description: '已登记为旅拍候选，本地路径不会上传保存。',
      tags: const ['手动导入', '待分析'],
    );
    if (!mounted) return;
    setState(() {
      _candidates = [candidate, ..._candidates];
      _photoNotice = '已登记候选照片，本地路径不会上传保存';
      _isRegistering = false;
    });
  }

  Future<void> _updateTaskStatus(
    Map<String, dynamic> task,
    String status,
  ) async {
    final taskId = task['id']?.toString() ?? task['taskId']?.toString() ?? '';
    if (taskId.isEmpty || _updatingTaskIds.contains(taskId)) return;
    setState(() {
      _updatingTaskIds.add(taskId);
      _photoNotice = null;
    });
    final updated = await _photoExperienceService.updateBlindBoxTaskStatus(
      taskId: taskId,
      status: status,
      note: status == 'completed' ? '用户在旅拍页完成盲盒任务' : null,
    );
    if (!mounted) return;
    setState(() {
      _tasks = _tasks
          .map((item) {
            final id = item['id']?.toString() ?? item['taskId']?.toString();
            if (id != taskId) return item;
            return {...item, ...updated, 'id': taskId};
          })
          .toList(growable: false);
      _updatingTaskIds.remove(taskId);
      _photoNotice = updated['offline'] == true
          ? '盲盒任务状态同步失败，请检查后端连接后重试'
          : _taskStatusNotice(status);
    });
  }

  Future<void> _generateCopywriting() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    final copywriting = await _photoExperienceService.generateCopywriting(
      photoIds: _candidates
          .map((item) => item['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList(),
      persona: '活泼向导',
      style: '轻松',
    );
    if (!mounted) return;
    setState(() {
      _copywriting = copywriting;
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    final contentWidth = metrics.maxContentWidth.isFinite
        ? metrics.maxContentWidth
        : MediaQuery.sizeOf(context).width;
    final gridWidth = contentWidth - metrics.horizontalPadding * 2;
    final gridColumns = gridWidth >= 660
        ? 3
        : (gridWidth < 360 || metrics.hasLargeText ? 1 : 2);
    final gridAspectRatio = gridColumns == 1
        ? 1.22
        : (metrics.hasLargeText ? 0.66 : 0.72);

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
            const AdaptiveTopBar(title: '旅拍候选'),
            Expanded(
              child: FutureBuilder<void>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting;
                  final isEmpty =
                      !isLoading && _candidates.isEmpty && _tasks.isEmpty;
                  return ListView(
                    padding: metrics.listPadding(),
                    children: [
                      if (isLoading)
                        const _LoadingState()
                      else if (snapshot.hasError || isEmpty)
                        _PhotoEmptyState(
                          hasError: snapshot.hasError,
                          onRetry: _retryLoad,
                        ),
                      if (_photoNotice != null) ...[
                        GlassBox(
                          opacity: 0.18,
                          margin: const EdgeInsets.only(
                            bottom: AppTheme.spacingMd,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.privacy_tip_rounded,
                                color: AppTheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: Text(
                                  _photoNotice!,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridColumns,
                          crossAxisSpacing: AppTheme.spacingMd,
                          mainAxisSpacing: AppTheme.spacingMd,
                          childAspectRatio: gridAspectRatio,
                        ),
                        itemCount: _candidates.length,
                        itemBuilder: (_, i) =>
                            _AgentPhotoCandidateCard(photo: _candidates[i]),
                      ),
                      if (_tasks.isNotEmpty) ...[
                        const _SectionHeader(
                          icon: Icons.card_giftcard_rounded,
                          title: '旅行盲盒',
                        ),
                        ..._tasks.take(3).map((task) {
                          final taskId =
                              task['id']?.toString() ??
                              task['taskId']?.toString() ??
                              '';
                          return _TaskCard(
                            task: task,
                            updating: _updatingTaskIds.contains(taskId),
                            onStatusChanged: (status) =>
                                _updateTaskStatus(task, status),
                          );
                        }),
                      ],
                      if (_copywriting != null) ...[
                        const _SectionHeader(
                          icon: Icons.edit_note_rounded,
                          title: '生成文案',
                        ),
                        _CopywritingCard(copywriting: _copywriting!),
                      ],
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.horizontalPadding,
                0,
                metrics.horizontalPadding,
                metrics.safeInsets.bottom + AppTheme.spacingMd,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isRegistering
                            ? null
                            : _registerManualCandidate,
                        icon: Icon(
                          _isRegistering
                              ? Icons.more_horiz_rounded
                              : Icons.add_photo_alternate_rounded,
                          size: 22,
                        ),
                        label: Text(
                          _isRegistering ? '登记中' : '登记候选',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          minimumSize: Size.fromHeight(metrics.minTouchTarget),
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateCopywriting,
                        icon: Icon(
                          _isGenerating
                              ? Icons.more_horiz_rounded
                              : Icons.edit_note_rounded,
                          size: 22,
                        ),
                        label: Text(
                          _isGenerating ? '生成中' : '生成文案',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: Size.fromHeight(metrics.minTouchTarget),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          elevation: 0,
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const GlassBox(
      opacity: 0.16,
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppTheme.spacingSm),
          Text(
            '正在加载旅拍候选',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoEmptyState extends StatelessWidget {
  const _PhotoEmptyState({required this.hasError, required this.onRetry});

  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      opacity: 0.18,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasError
                    ? Icons.cloud_off_rounded
                    : Icons.photo_library_outlined,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                hasError ? '旅拍候选加载失败' : '还没有旅拍候选',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            hasError ? '请检查网络后重试；也可以先登记本机候选。' : '可以先登记候选照片，后续再接入系统相册和相机权限。',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('重试加载'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentPhotoCandidateCard extends StatelessWidget {
  const _AgentPhotoCandidateCard({required this.photo});

  final Map<String, dynamic> photo;

  @override
  Widget build(BuildContext context) {
    final tags = (photo['tags'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();
    return GlassBox(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLg),
                  topRight: Radius.circular(AppTheme.radiusLg),
                ),
                gradient: LinearGradient(
                  colors: [AppTheme.bgTop, AppTheme.bgTop.withOpacity(0.48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.landscape_rounded,
                size: 34,
                color: AppTheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        photo['location']?.toString() ?? '旅拍地点',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${photo['score'] ?? 9.0}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  photo['description']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    tags.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _taskStatusNotice(String status) {
  return switch (status) {
    'accepted' => '已接受盲盒任务，完成后会写入蓝小心状态事件',
    'completed' => '完成盲盒任务，蓝小心状态奖励已同步',
    'skipped' => '已跳过盲盒任务',
    _ => '盲盒任务状态已更新',
  };
}

String _formatRewardDeltas(Map<String, dynamic> deltas) {
  final labels = <String>[];
  final affection = deltas['affection'];
  final rapport = deltas['rapport'];
  if (affection is num && affection != 0) {
    labels.add('好感 +${affection.toInt()}');
  }
  if (rapport is num && rapport != 0) {
    labels.add('默契 +${rapport.toInt()}');
  }
  return labels.isEmpty ? '蓝小心状态已奖励' : labels.join(' / ');
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.updating,
    required this.onStatusChanged,
  });

  final Map<String, dynamic> task;
  final bool updating;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final taskId = task['id']?.toString() ?? task['taskId']?.toString() ?? '';
    final status = task['status']?.toString() ?? 'available';
    final isAccepted = status == 'accepted';
    final isCompleted = status == 'completed';
    final isSkipped = status == 'skipped';
    final rewardDeltas =
        task['rewardDeltas'] as Map<String, dynamic>? ?? const {};
    return GlassBox(
      opacity: 0.16,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task['title']?.toString() ?? '旅行盲盒任务',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _TaskStatusPill(status: status),
            ],
          ),
          if (task['reward'] != null || task['note'] != null) ...[
            const SizedBox(height: 6),
            Text(
              (task['note'] ?? task['reward']).toString(),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (rewardDeltas.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _formatRewardDeltas(rewardDeltas),
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: ValueKey('blind-box-$taskId-accept'),
                onPressed: updating || isAccepted || isCompleted || isSkipped
                    ? null
                    : () => onStatusChanged('accepted'),
                icon: const Icon(Icons.playlist_add_check_rounded, size: 16),
                label: const Text('接受'),
              ),
              FilledButton.icon(
                key: ValueKey('blind-box-$taskId-complete'),
                onPressed: updating || isCompleted || isSkipped
                    ? null
                    : () => onStatusChanged('completed'),
                icon: updating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('完成'),
              ),
              TextButton.icon(
                key: ValueKey('blind-box-$taskId-skip'),
                onPressed: updating || isCompleted || isSkipped
                    ? null
                    : () => onStatusChanged('skipped'),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('跳过'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskStatusPill extends StatelessWidget {
  const _TaskStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'accepted' => '已接受',
      'completed' => '已完成',
      'skipped' => '已跳过',
      _ => '待领取',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CopywritingCard extends StatelessWidget {
  const _CopywritingCard({required this.copywriting});

  final Map<String, dynamic> copywriting;

  @override
  Widget build(BuildContext context) {
    final items = [
      copywriting['moments'],
      copywriting['xiaohongshu'],
      copywriting['diary'],
      copywriting['vlogNarration'],
    ].whereType<String>();
    return GlassBox(
      opacity: 0.18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
