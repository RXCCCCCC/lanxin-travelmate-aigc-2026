import 'package:flutter/material.dart';

import '../../core/layout/responsive_metrics.dart';
import '../../core/router/navigation_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_box.dart';
import 'data/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.profileService});

  final ProfileService? profileService;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileService _profileService;
  ProfilePayload? _profile;

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? ProfileService();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.fetchProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _saveProfile(ProfilePayload profile) async {
    final saved = await _profileService.updateProfile(profile: profile);
    if (!mounted) return;
    setState(() => _profile = saved);
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
                      '个人画像',
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
            Expanded(
              child: _ProfileList(
                payload: _profile,
                profile: _ProfileViewModel.fromPayload(_profile),
                onSave: _saveProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileViewModel {
  const _ProfileViewModel({
    required this.name,
    required this.dietaryPreferences,
    required this.travelPace,
    required this.transportPreferences,
    required this.budgetPreference,
    required this.interestTags,
  });

  final String name;
  final List<String> dietaryPreferences;
  final String travelPace;
  final List<String> transportPreferences;
  final String budgetPreference;
  final List<String> interestTags;

  factory _ProfileViewModel.fromPayload(ProfilePayload? payload) {
    if (payload == null) return _ProfileViewModel.empty();
    return _ProfileViewModel(
      name: payload.userId,
      dietaryPreferences: _fallbackList(
        payload.dietaryPreferences.map(_displayProfileValue).toList(),
      ),
      travelPace: _displayProfileValue(payload.travelPace),
      transportPreferences: _fallbackList(
        payload.transportPreferences.map(_displayProfileValue).toList(),
      ),
      budgetPreference: _displayProfileValue(payload.budgetPreference),
      interestTags: _fallbackList(
        payload.interestTags.map(_displayProfileValue).toList(),
      ),
    );
  }

  factory _ProfileViewModel.empty() {
    return const _ProfileViewModel(
      name: 'guest',
      dietaryPreferences: ['未设置'],
      travelPace: '未设置',
      transportPreferences: ['未设置'],
      budgetPreference: '未设置',
      interestTags: ['未设置'],
    );
  }

  static List<String> _fallbackList(List<String> values) {
    final filtered = values.where((item) => item.trim().isNotEmpty).toList();
    return filtered.isEmpty ? const ['未设置'] : filtered;
  }
}

String _displayProfileValue(String value) {
  final text = value.trim();
  if (text.isEmpty) return '未设置';
  const map = {
    'light': '轻松',
    'slow': '慢节奏',
    'slow pace': '慢节奏',
    'relaxed pace': '轻松节奏',
    'medium': '中等预算',
    'medium budget': '中等预算',
    'low': '低预算',
    'low budget': '低预算',
    'high': '高预算',
    'high budget': '高预算',
    'transit': '公共交通',
    'walking': '步行',
    'taxi': '打车',
    'self_drive': '自驾',
    'night view': '夜景',
    'night views': '夜景',
    'less walking': '少走路',
  };
  return map[text.toLowerCase()] ?? text;
}

class _ProfileList extends StatelessWidget {
  const _ProfileList({
    required this.payload,
    required this.profile,
    required this.onSave,
  });

  final ProfilePayload? payload;
  final _ProfileViewModel profile;
  final ValueChanged<ProfilePayload> onSave;

  ProfilePayload get _editableProfile => payload ?? ProfilePayload.fallback();

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return ListView(
      padding: metrics.listPadding(top: AppTheme.spacingSm),
      children: [
        GlassBox(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: const Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '蓝小心了解你的旅行偏好',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        _ProfileCard(
          icon: Icons.restaurant_rounded,
          title: '饮食偏好',
          values: profile.dietaryPreferences,
          onEdit: () => _openEditor(
            context,
            field: _ProfileField.dietary,
            title: '饮食偏好',
            initialValue: profile.dietaryPreferences.join(', '),
          ),
        ),
        _ProfileCard(
          icon: Icons.directions_walk_rounded,
          title: '旅行节奏',
          values: [profile.travelPace],
          onEdit: () => _openEditor(
            context,
            field: _ProfileField.pace,
            title: '旅行节奏',
            initialValue: profile.travelPace,
          ),
        ),
        _ProfileCard(
          icon: Icons.directions_bus_rounded,
          title: '交通偏好',
          values: profile.transportPreferences,
          onEdit: () => _openEditor(
            context,
            field: _ProfileField.transport,
            title: '交通偏好',
            initialValue: profile.transportPreferences.join(', '),
          ),
        ),
        _ProfileCard(
          icon: Icons.account_balance_wallet_rounded,
          title: '预算水平',
          values: [profile.budgetPreference],
          onEdit: () => _openEditor(
            context,
            field: _ProfileField.budget,
            title: '预算水平',
            initialValue: profile.budgetPreference,
          ),
        ),
        _ProfileCard(
          icon: Icons.local_offer_rounded,
          title: '兴趣标签',
          values: profile.interestTags,
          isTags: true,
          onEdit: () => _openEditor(
            context,
            field: _ProfileField.interests,
            title: '兴趣标签',
            initialValue: profile.interestTags.join(', '),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    required _ProfileField field,
    required String title,
    required String initialValue,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProfileEditSheet(
        title: title,
        initialValue: initialValue,
        multiValue: field.isList,
      ),
    );
    if (result == null) return;
    onSave(_updatedProfile(field, result));
  }

  ProfilePayload _updatedProfile(_ProfileField field, String rawValue) {
    final current = _editableProfile;
    final listValue = _splitValues(rawValue);
    return ProfilePayload(
      userId: current.userId,
      travelPace: field == _ProfileField.pace
          ? rawValue.trim()
          : current.travelPace,
      dietaryPreferences: field == _ProfileField.dietary
          ? listValue
          : current.dietaryPreferences,
      interestTags: field == _ProfileField.interests
          ? listValue
          : current.interestTags,
      transportPreferences: field == _ProfileField.transport
          ? listValue
          : current.transportPreferences,
      budgetPreference: field == _ProfileField.budget
          ? rawValue.trim()
          : current.budgetPreference,
      personality: current.personality,
      proactivityLevel: current.proactivityLevel,
      syncStrategy: current.syncStrategy,
      notificationEnabled: current.notificationEnabled,
      voiceEnabled: current.voiceEnabled,
      textModePreferred: current.textModePreferred,
      customPrompt: current.customPrompt,
    );
  }
}

enum _ProfileField { dietary, pace, transport, budget, interests }

extension on _ProfileField {
  bool get isList => switch (this) {
    _ProfileField.dietary ||
    _ProfileField.transport ||
    _ProfileField.interests => true,
    _ => false,
  };
}

List<String> _splitValues(String value) {
  return value
      .split(RegExp(r'[,，]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.values,
    this.isTags = false,
    this.onEdit,
  });

  final IconData icon;
  final String title;
  final List<String> values;
  final bool isTags;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final metrics = context.responsive;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: GlassBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primary),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Material(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: metrics.minTouchTarget - 12,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '编辑',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            isTags
                ? Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingSm,
                    children: values
                        .map((value) => _TagChip(value: value))
                        .toList(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: values
                        .map((value) => _ValueLine(value: value))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({
    required this.title,
    required this.initialValue,
    required this.multiValue,
  });

  final String title;
  final String initialValue;
  final bool multiValue;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: widget.multiValue ? 2 : 1,
            maxLines: widget.multiValue ? 3 : 1,
            decoration: InputDecoration(
              helperText: widget.multiValue ? '多个值用逗号分隔' : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_controller.text),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: const TextStyle(color: AppTheme.primary, fontSize: 13),
      ),
    );
  }
}

class _ValueLine extends StatelessWidget {
  const _ValueLine({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        value,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}
