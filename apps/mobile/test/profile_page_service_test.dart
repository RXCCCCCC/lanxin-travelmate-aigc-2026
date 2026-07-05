import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/profile/data/profile_service.dart';
import 'package:lanxin_travelmate/features/profile/profile_page.dart';

class StubProfileService extends ProfileService {
  StubProfileService() : super(dio: Dio());

  ProfilePayload? updatedProfile;

  @override
  Future<ProfilePayload> fetchProfile({String userId = 'guest'}) async {
    return const ProfilePayload(
      userId: 'traveler-a',
      travelPace: 'slow pace',
      dietaryPreferences: ['no cilantro'],
      interestTags: ['night views'],
      transportPreferences: ['transit'],
      budgetPreference: 'medium',
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

void main() {
  testWidgets('ProfilePage displays profile service data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProfilePage(profileService: StubProfileService())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('traveler-a'), findsOneWidget);
    expect(find.text('no cilantro'), findsOneWidget);
    expect(find.text('慢节奏'), findsOneWidget);
    expect(find.text('公共交通'), findsOneWidget);
    expect(find.text('中等预算'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('夜景'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('night views'), findsNothing);
    expect(find.text('夜景'), findsOneWidget);
  });

  testWidgets('ProfilePage edits and saves profile data', (tester) async {
    final service = StubProfileService();
    await tester.pumpWidget(
      MaterialApp(home: ProfilePage(profileService: service)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.widgetWithText(InkWell, '编辑').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no cilantro, light meals');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(service.updatedProfile?.dietaryPreferences, [
      'no cilantro',
      'light meals',
    ]);
    expect(find.text('light meals'), findsOneWidget);
  });
}
