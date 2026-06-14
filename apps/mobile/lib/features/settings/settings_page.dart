import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_box.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                    child: Text('设置', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // 设置项
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                children: [
                  // 蓝小心人格
                  _SettingsSection(
                    title: '蓝小心人格',
                    icon: Icons.face_rounded,
                    child: GlassBox(
                      opacity: 0.12,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.smart_toy_rounded, size: 20, color: AppTheme.primary),
                          const SizedBox(width: AppTheme.spacingMd),
                          const Expanded(child: Text('活泼可爱', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('切换', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 主动程度
                  _SettingsSection(
                    title: '主动程度',
                    icon: Icons.tune_rounded,
                    child: GlassBox(
                      opacity: 0.12,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: ['安静', '标准', '活跃'].asMap().entries.map((e) {
                              final selected = e.key == 1;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    color: selected ? AppTheme.primary : AppTheme.textMuted,
                                    fontSize: 14,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.primary,
                              inactiveTrackColor: AppTheme.primary.withOpacity(0.15),
                              thumbColor: AppTheme.primary,
                              overlayColor: AppTheme.primary.withOpacity(0.1),
                            ),
                            child: Slider(value: 0.5, onChanged: (_) {}),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 同步策略
                  _SettingsSection(
                    title: '同步策略',
                    icon: Icons.cloud_sync_rounded,
                    child: GlassBox(
                      opacity: 0.12,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('云端同步', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                        subtitle: const Text('将记忆和画像同步到云端', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        activeColor: AppTheme.primary,
                        value: true,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                  // 通知设置
                  _SettingsSection(
                    title: '通知设置',
                    icon: Icons.notifications_rounded,
                    child: Column(
                      children: [
                        _ToggleItem(title: '主动提醒', subtitle: '蓝小心主动发起对话', value: true),
                        _ToggleItem(title: '行程提醒', subtitle: '出发时间和行程变更通知', value: true),
                        _ToggleItem(title: '天气预警', subtitle: '天气变化对行程的影响', value: false),
                      ],
                    ),
                  ),
                  // 关于
                  _SettingsSection(
                    title: '关于',
                    icon: Icons.info_outline_rounded,
                    child: GlassBox(
                      opacity: 0.12,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: const Row(
                        children: [
                          Icon(Icons.smart_toy_rounded, size: 24, color: AppTheme.primary),
                          SizedBox(width: AppTheme.spacingMd),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('蓝心同行', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                              SizedBox(height: 2),
                              Text('v1.0.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          child,
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({required this.title, required this.subtitle, required this.value});
  final String title;
  final String subtitle;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      opacity: 0.12,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        activeColor: AppTheme.primary,
        value: value,
        onChanged: (_) {},
      ),
    );
  }
}
