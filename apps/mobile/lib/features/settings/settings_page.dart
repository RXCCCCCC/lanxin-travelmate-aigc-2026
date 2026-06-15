import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_metrics.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_box.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      '设置',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // 设置项
            Expanded(
              child: ListView(
                padding: metrics.listPadding(top: AppTheme.spacingSm),
                children: [
                  // 蓝小心人格
                  _SettingsSection(
                    title: '蓝小心人格',
                    icon: Icons.face_rounded,
                    child: GlassBox(
                      opacity: 0.12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _PersonaChip(label: '活泼向导', selected: true),
                              _PersonaChip(label: '细心管家'),
                              _PersonaChip(label: '冷静规划师'),
                              _PersonaChip(label: '元气拍档'),
                              _PersonaChip(label: '安静陪伴'),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          TextField(
                            minLines: 2,
                            maxLines: 3,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: '自定义人格 Prompt，例如：更像靠谱朋友，少打扰但关键时刻主动提醒',
                              hintStyle: TextStyle(
                                color: AppTheme.textMuted.withOpacity(0.72),
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.32),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              isDense: true,
                            ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          Wrap(
                            spacing: AppTheme.spacingSm,
                            runSpacing: AppTheme.spacingSm,
                            children: ['安静', '标准', '活跃'].asMap().entries.map((
                              e,
                            ) {
                              final selected = e.key == 1;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppTheme.primary.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    color: selected
                                        ? AppTheme.primary
                                        : AppTheme.textMuted,
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.primary,
                              inactiveTrackColor: AppTheme.primary.withOpacity(
                                0.15,
                              ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '云端同步',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          '将记忆和画像同步到云端',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
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
                        _ToggleItem(
                          title: '主动提醒',
                          subtitle: '蓝小心主动发起对话',
                          value: true,
                        ),
                        _ToggleItem(
                          title: '行程提醒',
                          subtitle: '出发时间和行程变更通知',
                          value: true,
                        ),
                        _ToggleItem(
                          title: '天气预警',
                          subtitle: '天气变化对行程的影响',
                          value: false,
                        ),
                      ],
                    ),
                  ),
                  _SettingsSection(
                    title: '动作映射',
                    icon: Icons.animation_rounded,
                    child: const GlassBox(
                      opacity: 0.12,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          _InfoLine(
                            icon: Icons.route_rounded,
                            text: '规划中 → planning',
                          ),
                          _InfoLine(
                            icon: Icons.warning_amber_rounded,
                            text: '风险提醒 → warning',
                          ),
                          _InfoLine(
                            icon: Icons.auto_awesome_rounded,
                            text: '发现盲盒 → excited',
                          ),
                          _InfoLine(
                            icon: Icons.task_alt_rounded,
                            text: '任务完成 → happy',
                          ),
                        ],
                      ),
                    ),
                  ),
                  _SettingsSection(
                    title: '状态表达文案',
                    icon: Icons.record_voice_over_rounded,
                    child: const GlassBox(
                      opacity: 0.12,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          _InfoLine(
                            icon: Icons.battery_2_bar_rounded,
                            text: '精力低时：我们把下一站换成近一点的轻松路线。',
                          ),
                          _InfoLine(
                            icon: Icons.favorite_rounded,
                            text: '好感度提升时：这次配合很默契，我更懂你的旅行节奏了。',
                          ),
                          _InfoLine(
                            icon: Icons.explore_rounded,
                            text: '好奇心高时：附近有个不绕路的小发现，要不要去看看？',
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 关于
                  _SettingsSection(
                    title: '关于',
                    icon: Icons.info_outline_rounded,
                    child: GlassBox(
                      opacity: 0.12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.smart_toy_rounded,
                            size: 24,
                            color: AppTheme.primary,
                          ),
                          SizedBox(width: AppTheme.spacingMd),
                          Column(
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
                        ],
                      ),
                    ),
                  ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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

class _PersonaChip extends StatelessWidget {
  const _PersonaChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return Container(
      constraints: BoxConstraints(minHeight: metrics.minTouchTarget - 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withOpacity(0.18)
            : Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: selected
              ? AppTheme.primary.withOpacity(0.32)
              : Colors.white.withOpacity(0.28),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppTheme.primary : AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.title,
    required this.subtitle,
    required this.value,
  });
  final String title;
  final String subtitle;
  final bool value;

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
        onChanged: (_) {},
      ),
    );
  }
}
