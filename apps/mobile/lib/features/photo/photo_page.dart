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
    final upload = await _photoExperienceService.createUploadMetadata(
      filename: 'manual-night-photo.jpg',
      contentType: 'image/jpeg',
      localPath: 'device://selected-photo/manual-night-photo.jpg',
    );
    final candidate = await _photoExperienceService.createCandidate(
      id: 'manual-photo-${DateTime.now().millisecondsSinceEpoch}',
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
                        ..._tasks.take(3).map((task) => _TaskCard(task: task)),
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
                hasError ? Icons.cloud_off_rounded : Icons.photo_library_outlined,
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
            hasError
                ? '请检查网络后重试；也可以先登记本机候选。'
                : '可以先登记候选照片，后续再接入系统相册和相机权限。',
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

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      opacity: 0.16,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
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
        ],
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
