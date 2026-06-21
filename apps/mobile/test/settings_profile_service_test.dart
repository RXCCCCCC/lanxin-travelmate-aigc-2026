import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/profile/data/profile_service.dart';
import 'package:lanxin_travelmate/features/settings/data/settings_data_service.dart';
import 'package:lanxin_travelmate/features/settings/settings_page.dart';

class StubSettingsProfileService extends ProfileService {
  StubSettingsProfileService() : super(dio: Dio());

  ProfilePayload? updatedProfile;

  @override
  Future<ProfilePayload> fetchProfile({String userId = 'guest'}) async {
    return const ProfilePayload(
      userId: 'guest',
      travelPace: 'slow',
      dietaryPreferences: ['no cilantro'],
      interestTags: ['night views'],
      transportPreferences: ['transit'],
      budgetPreference: 'medium',
      personality: 'quiet_planner',
      proactivityLevel: 'quiet',
      syncStrategy: 'selectedOnly',
      notificationEnabled: false,
      voiceEnabled: true,
      textModePreferred: true,
      customPrompt: 'Keep reminders quiet.',
    );
  }

  @override
  Future<ProfilePayload> updateProfile({
    String userId = 'guest',
    required ProfilePayload profile,
  }) async {
    updatedProfile = profile;
    return profile;
  }
}

class StubSettingsDataService extends SettingsDataService {
  StubSettingsDataService() : super(dio: Dio());

  String? lastAction;

  @override
  Future<PrivacySummaryPayload> fetchPrivacySummary() async {
    return const PrivacySummaryPayload(
      principles: ['Consent before cloud sync.'],
      permissions: [
        PrivacyPermissionInfo(
          permission: 'location',
          label: 'Location',
          purpose: 'Route risk reminders',
          fallback: 'Manual destination input',
        ),
      ],
      userControls: {'canExportData': true},
    );
  }

  @override
  Future<DataActionResult> exportMemories({String userId = 'guest'}) async {
    lastAction = 'export';
    return const DataActionResult(status: 'ok', itemCount: 3);
  }
}

void main() {
  testWidgets('SettingsPage reads and writes profile settings', (tester) async {
    final service = StubSettingsProfileService();
    final dataService = StubSettingsDataService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(profileService: service, dataService: dataService),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('quiet_planner'), findsWidgets);
    expect(find.text('quiet'), findsWidgets);
    expect(find.text('selectedOnly'), findsWidgets);
    expect(find.text('Keep reminders quiet.'), findsOneWidget);

    await tester.tap(find.text('active').first);
    await tester.pump(const Duration(milliseconds: 50));

    expect(service.updatedProfile?.proactivityLevel, 'active');

    await tester.scrollUntilVisible(
      find.text('Consent before cloud sync.'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Location'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('导出记忆'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.ensureVisible(find.text('导出记忆').first);
    await tester.pump();
    await tester.tap(find.text('导出记忆').first);
    await tester.pump(const Duration(milliseconds: 50));
    expect(dataService.lastAction, 'export');
    expect(find.text('已导出 3 条记忆'), findsOneWidget);
  });
}
