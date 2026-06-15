import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_box.dart';
import 'data/photo_experience_service.dart';

/// 旅拍候选页面
class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key, this.photoExperienceService});

  final PhotoExperienceService? photoExperienceService;

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  late final PhotoExperienceService _photoExperienceService;
  late final Future<void> _loadFuture;
  List<Map<String, dynamic>> _candidates = const [];
  List<Map<String, dynamic>> _tasks = const [];
  Map<String, dynamic>? _copywriting;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _photoExperienceService = widget.photoExperienceService ?? PhotoExperienceService();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _photoExperienceService.fetchCandidates(),
      _photoExperienceService.fetchBlindBoxTasks(),
    ]);
    _candidates = results[0];
    _tasks = results[1];
  }

  Future<void> _generateCopywriting() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    final copywriting = await _photoExperienceService.generateCopywriting(
      photoIds: _candidates.map((item) => item['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList(),
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
                    child: Text('旅拍候选', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<void>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(AppTheme.spacingLg, AppTheme.spacingSm, AppTheme.spacingLg, AppTheme.spacingXl),
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppTheme.spacingMd,
                          mainAxisSpacing: AppTheme.spacingMd,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _candidates.length,
                        itemBuilder: (_, i) => _AgentPhotoCandidateCard(photo: _candidates[i]),
                      ),
                      if (_tasks.isNotEmpty) ...[
                        const _SectionHeader(icon: Icons.card_giftcard_rounded, title: '旅行盲盒'),
                        ..._tasks.take(3).map((task) => _TaskCard(task: task)),
                      ],
                      if (_copywriting != null) ...[
                        const _SectionHeader(icon: Icons.edit_note_rounded, title: '生成文案'),
                        _CopywritingCard(copywriting: _copywriting!),
                      ],
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spacingLg, 0, AppTheme.spacingLg, AppTheme.spacingMd),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateCopywriting,
                  icon: Icon(_isGenerating ? Icons.more_horiz_rounded : Icons.edit_note_rounded, size: 22),
                  label: Text(_isGenerating ? '生成中' : '生成文案', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
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
      child: Row(children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _AgentPhotoCandidateCard extends StatelessWidget {
  const _AgentPhotoCandidateCard({required this.photo});

  final Map<String, dynamic> photo;

  @override
  Widget build(BuildContext context) {
    final tags = (photo['tags'] as List<dynamic>? ?? const []).map((item) => item.toString()).toList();
    return GlassBox(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            child: const Icon(Icons.landscape_rounded, size: 34, color: AppTheme.primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(photo['location']?.toString() ?? '旅拍地点', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800))),
              Text('${photo['score'] ?? 9.0}', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 4),
            Text(photo['description']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(tags.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
      ]),
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
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(task['title']?.toString() ?? '旅行盲盒任务', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800))),
      ]),
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
            .map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.35)),
                ))
            .toList(),
      ),
    );
  }
}
