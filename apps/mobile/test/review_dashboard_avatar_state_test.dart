import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/data/agent_response_cache.dart';
import 'package:lanxin_travelmate/features/profile/data/profile_service.dart';
import 'package:lanxin_travelmate/features/review/data/trip_review_service.dart';
import 'package:lanxin_travelmate/features/review/review_page.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_dashboard_service.dart';

class StubAvatarDashboardService extends TripDashboardService {
  StubAvatarDashboardService() : super(dio: Dio());

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String userId = 'guest',
    String? tripId,
  }) async {
    return TripDashboardPayload(
      userId: userId,
      tripId: tripId ?? 'trip-avatar',
      currentTrip: const {
        'tripId': 'trip-avatar',
        'destination': 'Hangzhou',
        'status': 'active',
      },
      routePoints: const {'route': 'Hotel -> West Lake'},
      reminderHistory: const [],
      blindBoxTasks: const [],
      avatarStateEvents: const [
        {
          'eventType': 'memory_confirmed',
          'title': '确认了不吃香菜记忆',
          'deltas': {'affection': 2, 'rapport': 1},
        },
      ],
      latestReview: const {'reviewId': null, 'review': <String, dynamic>{}},
      photoCandidates: const [],
      memories: const [],
    );
  }
}

class CapturingReviewService extends TripReviewService {
  CapturingReviewService() : super(dio: Dio());

  Map<String, dynamic>? capturedProfileContext;
  String? capturedTripId;

  @override
  Future<TripReviewPayload> generateReview({
    String message = '生成今天旅行复盘',
    String? tripId,
    List<Map<String, dynamic>> completedTasks = const [],
    List<Map<String, dynamic>> temporaryMemories = const [],
    Map<String, dynamic> profileContext = const {},
  }) async {
    capturedTripId = tripId;
    capturedProfileContext = profileContext;
    return const TripReviewPayload(
      route: '画像复盘路线',
      highlightPhotos: [],
      newMemories: [],
      completedTasks: [],
      avatarStatusChanges: [],
      nextTripSuggestions: ['夜景轻松线'],
      temporaryMemoryPromotions: [],
    );
  }
}

class StubReviewProfileService extends ProfileService {
  StubReviewProfileService() : super(dio: Dio());

  @override
  Future<ProfilePayload> fetchProfile({String userId = 'guest'}) async {
    return const ProfilePayload(
      userId: 'guest',
      travelPace: 'light',
      dietaryPreferences: ['不吃香菜'],
      interestTags: ['夜景'],
      transportPreferences: ['地铁'],
      budgetPreference: 'medium',
    );
  }
}

class ThrowingReviewService extends TripReviewService {
  ThrowingReviewService() : super(dio: Dio());

  @override
  Future<TripReviewPayload> generateReview({
    String message = '生成今天旅行复盘',
    String? tripId,
    List<Map<String, dynamic>> completedTasks = const [],
    List<Map<String, dynamic>> temporaryMemories = const [],
    Map<String, dynamic> profileContext = const {},
  }) async {
    throw StateError('review generation should not be needed');
  }
}

void main() {
  tearDown(() {
    latestAgentResponse.value = null;
  });

  testWidgets('ReviewPage displays dashboard avatar-state history', (
    tester,
  ) async {
    latestAgentResponse.value = null;

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          dashboardService: StubAvatarDashboardService(),
          tripReviewService: ThrowingReviewService(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.scrollUntilVisible(
      find.textContaining('确认了不吃香菜记忆'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('affection +2'), findsOneWidget);
  });
  testWidgets('ReviewPage passes profile context into generated review', (
    tester,
  ) async {
    latestAgentResponse.value = null;
    final reviewService = CapturingReviewService();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          tripReviewService: reviewService,
          profileService: StubReviewProfileService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('画像复盘路线'), findsOneWidget);
    expect(reviewService.capturedTripId, startsWith('review-trip-'));
    expect(reviewService.capturedTripId, isNot('demo-chongqing-weekend'));
    expect(find.textContaining('夜景'), findsOneWidget);
    expect(reviewService.capturedProfileContext?['travelPace'], 'light');
    expect(reviewService.capturedProfileContext?['interestTags'], ['夜景']);
    expect(reviewService.capturedProfileContext?['dietaryPreferences'], [
      '不吃香菜',
    ]);
  });
}
