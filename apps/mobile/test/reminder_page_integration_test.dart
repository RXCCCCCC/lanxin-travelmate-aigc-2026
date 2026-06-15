import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/reminder/data/reminder_trigger_service.dart';
import 'package:lanxin_travelmate/features/reminder/reminder_page.dart';

class StubReminderTriggerService extends ReminderTriggerService {
  StubReminderTriggerService() : super(dio: Dio());

  @override
  Future<List<Map<String, dynamic>>> trigger(
    String triggerType, {
    String? location,
    Map<String, dynamic> eventPayload = const {},
  }) async {
    return [
      {
        'id': 'reminder-new-photo',
        'title': '这张照片适合加入旅拍候选',
        'triggerType': triggerType,
        'description': '复盘时可以生成照片配文。',
        'cooldownMinutes': 45,
      }
    ];
  }
}

void main() {
  testWidgets('ReminderPage can simulate behavior trigger', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ReminderPage(reminderTriggerService: StubReminderTriggerService()),
    ));

    await tester.tap(find.text('拍照触发'));
    await tester.pumpAndSettle();

    expect(find.text('这张照片适合加入旅拍候选'), findsOneWidget);
    expect(find.textContaining('behavior'), findsOneWidget);
  });
}
