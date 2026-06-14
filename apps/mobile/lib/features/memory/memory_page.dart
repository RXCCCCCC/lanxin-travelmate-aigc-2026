import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
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

  static const _tabs = ['全部', '长期', '本次', '临时'];

  List<MemoryCapsule> get _filtered {
    if (_selectedTab == 0) return mockMemoryCapsules;
    final scope = MemoryScope.values[_selectedTab - 1];
    return mockMemoryCapsules.where((c) => c.scope == scope).toList();
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
                itemBuilder: (_, i) => MemoryCapsuleCard(capsule: _filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
