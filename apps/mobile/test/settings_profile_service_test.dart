import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/data/local/app_database.dart';
import 'package:lanxin_travelmate/data/repositories/memory_repository.dart';
import 'package:lanxin_travelmate/features/profile/data/profile_service.dart';
import 'package:lanxin_travelmate/features/settings/data/settings_data_service.dart';
import 'package:lanxin_travelmate/features/settings/settings_page.dart';

class StubSettingsProfileService extends ProfileService {
  StubSettingsProfileService() : super(dio: Dio());

  ProfilePayload? updatedProfile;
  final List<ProfilePayload> updateRequests = [];

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
    updateRequests.add(profile);
    updatedProfile = profile;
    return profile;
  }
}

class DelayedSettingsProfileService extends StubSettingsProfileService {
  final List<Completer<ProfilePayload>> completions = [];

  @override
  Future<ProfilePayload> updateProfile({
    String userId = 'guest',
    required ProfilePayload profile,
  }) {
    updateRequests.add(profile);
    final completer = Completer<ProfilePayload>();
    completions.add(completer);
    return completer.future;
  }
}

class OfflineSettingsProfileService extends StubSettingsProfileService {
  @override
  Future<ProfilePayload> fetchProfile({String userId = 'guest'}) async {
    return ProfilePayload.fallback(userId: userId);
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

class _SettingsHarness extends StatefulWidget {
  const _SettingsHarness({
    required this.profileService,
    required this.dataService,
  });

  final ProfileService profileService;
  final SettingsDataService dataService;

  @override
  State<_SettingsHarness> createState() => _SettingsHarnessState();
}

class _SettingsHarnessState extends State<_SettingsHarness> {
  late final AppDatabase database;
  late final MemoryRepository repository;

  @override
  void initState() {
    super.initState();
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = MemoryRepository(database);
  }

  @override
  void dispose() {
    database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      profileService: widget.profileService,
      dataService: widget.dataService,
      memoryRepository: repository,
    );
  }
}

Widget _settingsTestApp({
  required ProfileService profileService,
  required SettingsDataService dataService,
}) {
  return MaterialApp(
    home: Scaffold(
      body: _SettingsHarness(
        profileService: profileService,
        dataService: dataService,
      ),
    ),
  );
}

void main() {
  testWidgets('SettingsPage reads and writes profile settings', (tester) async {
    final service = StubSettingsProfileService();
    final dataService = StubSettingsDataService();

    await tester.pumpWidget(
      _settingsTestApp(
        profileService: service,
        dataService: dataService,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('安静规划师'), findsWidgets);
    expect(find.text('安静'), findsWidgets);
    expect(find.text('仅已选择'), findsWidgets);
    expect(find.text('Keep reminders quiet.'), findsOneWidget);

    await tester.tap(find.text('主动').first);
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

  testWidgets('SettingsPage ignores stale profile save responses', (
    tester,
  ) async {
    final service = DelayedSettingsProfileService();
    final dataService = StubSettingsDataService();

    await tester.pumpWidget(
      _settingsTestApp(
        profileService: service,
        dataService: dataService,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('主动').first);
    await tester.pump();
    await tester.tap(find.text('标准').first);
    await tester.pump();

    expect(service.updateRequests.map((item) => item.proactivityLevel), [
      'active',
      'standard',
    ]);

    service.completions[1].complete(service.updateRequests[1]);
    await tester.pump();
    expect(find.text('标准'), findsWidgets);

    service.completions[0].complete(service.updateRequests[0]);
    await tester.pump();

    expect(find.textContaining('保持标准频率'), findsOneWidget);
    expect(find.textContaining('更积极地发现'), findsNothing);
  });

  testWidgets('SettingsPage labels fallback profile as offline default settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsTestApp(
        profileService: OfflineSettingsProfileService(),
        dataService: StubSettingsDataService(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('已连接个人设置'), findsNothing);
    expect(find.text('当前使用本机默认设置'), findsOneWidget);
  });
}
