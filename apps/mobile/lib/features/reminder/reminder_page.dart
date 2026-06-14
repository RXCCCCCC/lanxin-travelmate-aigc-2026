import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/reminder_card.dart';

/// 主动提醒页面
class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key});

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
                    child: Text('主动提醒', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // 提醒列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: AppTheme.spacingSm, bottom: AppTheme.spacingXl),
                itemCount: mockReminders.length,
                itemBuilder: (_, i) => ReminderCard(reminder: mockReminders[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
