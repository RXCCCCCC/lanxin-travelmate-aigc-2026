import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/profile/data/profile_service.dart';
import 'package:lanxin_travelmate/features/reminder/data/reminder_trigger_service.dart';
import 'package:lanxin_travelmate/features/reminder/reminder_page.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_dashboard_service.dart';

class StubReminderTriggerService extends ReminderTriggerService {
  StubReminderTriggerService() : super(dio: Dio());

  ReminderEvaluateDraft? capturedEvaluateDraft;

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
      },
    ];
  }

  @override
  Future<ReminderEvaluateResult> evaluate(ReminderEvaluateDraft draft) async {
    capturedEvaluateDraft = draft;
    return ReminderEvaluateResult(
      triggered: true,
      historyId: 'history-profile',
      items: const [
        {
          'id': 'auto-low-energy',
          'title': 'Low energy reminder',
          'triggerType': 'status',
          'description': 'Energy is low; switch to a shorter route.',
          'cooldownMinutes': 45,
        },
      ],
      suppressedReason: null,
      cooldownRemainingSeconds: 0,
    );
  }
}

class StubReminderProfileService extends ProfileService {
  StubReminderProfileService() : super(dio: Dio());

  @override
  Future<ProfilePayload> fetchProfile({String userId = 'guest'}) async {
    return const ProfilePayload(
      userId: 'guest',
      travelPace: 'light',
      dietaryPreferences: ['不吃香菜'],
      interestTags: ['夜景'],
      transportPreferences: ['地铁'],
      budgetPreference: 'medium',
      proactivityLevel: 'quiet',
    );
  }
}

class StubReminderDashboardService extends TripDashboardService {
  StubReminderDashboardService() : super();

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String? userId,
    String? tripId,
  }) async {
    return TripDashboardPayload(
      userId: userId ?? 'guest',
      tripId: tripId ?? 'reminder-trip',
      currentTrip: const {'status': 'planning', 'plan': <String, dynamic>{}},
      routePoints: const {'route': '', 'points': []},
      reminderHistory: const [
        {
          'historyId': 'history-a',
          'triggerType': 'location',
          'location': 'West Lake',
          'items': [
            {
              'id': 'dashboard-reminder-a',
              'title': 'Dashboard dinner reminder',
              'triggerType': 'time',
              'description':
                  'Reserve a lighter dinner before the evening walk.',
              'cooldownMinutes': 45,
            },
          ],
        },
      ],
      blindBoxTasks: const [],
      avatarStateEvents: const [],
      latestReview: const {},
      photoCandidates: const [],
      memories: const [],
    );
  }
}

void main() {
  testWidgets('ReminderPage can simulate behavior trigger', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderPage(
          reminderTriggerService: StubReminderTriggerService(),
        ),
      ),
    );

    await tester.tap(find.text('拍照触发'));
    await tester.pumpAndSettle();

    expect(find.text('这张照片适合加入旅拍候选'), findsOneWidget);
    expect(find.textContaining('\u884c\u4e3a'), findsOneWidget);
  });

  testWidgets(
    'ReminderPage displays dashboard reminder history before manual triggers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderPage(
            reminderTriggerService: StubReminderTriggerService(),
            dashboardService: StubReminderDashboardService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('\u4e3b\u52a8\u63d0\u9192'), findsWidgets);
      expect(find.textContaining('\u65f6\u95f4'), findsWidgets);
    },
  );
  testWidgets('ReminderPage evaluates reminders with profile context', (
    tester,
  ) async {
    final triggerService = StubReminderTriggerService();

    await tester.pumpWidget(
      MaterialApp(
        home: ReminderPage(
          reminderTriggerService: triggerService,
          profileService: StubReminderProfileService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('\u5b89\u9759'), findsOneWidget);
    expect(find.textContaining('夜景'), findsOneWidget);
    expect(find.text('\u4f53\u529b\u504f\u4f4e\u63d0\u9192'), findsOneWidget);
    expect(triggerService.capturedEvaluateDraft?.proactivityLevel, 'quiet');
    expect(triggerService.capturedEvaluateDraft?.status['travelPace'], 'light');
    expect(triggerService.capturedEvaluateDraft?.external['interestTags'], [
      '夜景',
    ]);
    expect(
      triggerService.capturedEvaluateDraft?.external['dietaryPreferences'],
      ['不吃香菜'],
    );
  });
}
