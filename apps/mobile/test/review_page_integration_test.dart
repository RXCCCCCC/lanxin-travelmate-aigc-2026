import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/core/constants/avatar_states.dart';
import 'package:lanxin_travelmate/data/agent_response_cache.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_models.dart';
import 'package:lanxin_travelmate/features/profile/data/profile_service.dart';
import 'package:lanxin_travelmate/features/review/data/trip_review_service.dart';
import 'package:lanxin_travelmate/features/review/review_page.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_dashboard_service.dart';

class StubTripReviewService extends TripReviewService {
  StubTripReviewService() : super(dio: Dio());

  @override
  Future<TripReviewPayload> generateReview({
    String message = '生成今天旅行复盘',
    String? tripId,
    List<Map<String, dynamic>> completedTasks = const [],
    List<Map<String, dynamic>> temporaryMemories = const [],
    Map<String, dynamic> profileContext = const {},
  }) async {
    return const TripReviewPayload(
      route: '测试路线：解放碑 → 洪崖洞',
      highlightPhotos: ['洪崖洞夜景'],
      newMemories: ['喜欢夜景'],
      completedTasks: [
        {'id': 'task-night-photo', 'title': '拍一张夜景', 'status': 'completed'},
      ],
      reminderHighlights: [],
      avatarStatusChanges: ['好感度 +2'],
      nextTripSuggestions: ['成都慢节奏美食线'],
      temporaryMemoryPromotions: [
        {'id': 'mem-slow-pace', 'title': '想轻松一点', 'suggestedScope': 'longTerm'},
      ],
    );
  }
}

class StubReviewProfileService extends ProfileService {
  StubReviewProfileService() : super(dio: Dio());

  @override
  Future<ProfilePayload> fetchProfile({String userId = 'guest'}) async {
    return const ProfilePayload(
      userId: 'guest',
      travelPace: 'slow',
      dietaryPreferences: ['不吃香菜'],
      interestTags: ['夜景'],
      transportPreferences: ['步行'],
      budgetPreference: 'medium',
    );
  }
}

class FetchingTripReviewService extends TripReviewService {
  FetchingTripReviewService() : super(dio: Dio());

  @override
  Future<TripReviewPayload?> fetchReview({required String tripId}) async {
    return const TripReviewPayload(
      route: '最新复盘路线：广州塔 → 海心桥',
      highlightPhotos: ['广州塔夜景'],
      newMemories: ['这次想轻松一点'],
      completedTasks: [
        {
          'id': 'task-guangzhou-night',
          'title': '补拍广州塔夜景',
          'status': 'completed',
        },
      ],
      reminderHighlights: [],
      avatarStatusChanges: ['蓝小心确认你更偏爱珠江夜景'],
      nextTripSuggestions: ['下次可以试试广州老城晨间慢游'],
      temporaryMemoryPromotions: [],
    );
  }

  @override
  Future<TripReviewPayload> generateReview({
    String message = '生成今天旅行复盘',
    String? tripId,
    List<Map<String, dynamic>> completedTasks = const [],
    List<Map<String, dynamic>> temporaryMemories = const [],
    Map<String, dynamic> profileContext = const {},
  }) async {
    throw StateError('should use persisted review first');
  }
}

class StaleDashboardReviewService extends TripReviewService {
  StaleDashboardReviewService() : super(dio: Dio());

  bool generated = false;
  String? generatedTripId;

  @override
  Future<TripReviewPayload?> fetchReview({required String tripId}) async {
    return const TripReviewPayload(
      route: '旧复盘路线：广州塔',
      highlightPhotos: ['旧照片'],
      newMemories: [],
      completedTasks: [],
      reminderHighlights: [],
      avatarStatusChanges: [],
      nextTripSuggestions: [],
      temporaryMemoryPromotions: [],
    );
  }

  @override
  Future<TripReviewPayload> generateReview({
    String message = '生成今天旅行复盘',
    String? tripId,
    List<Map<String, dynamic>> completedTasks = const [],
    List<Map<String, dynamic>> temporaryMemories = const [],
    Map<String, dynamic> profileContext = const {},
  }) async {
    generated = true;
    generatedTripId = tripId;
    return const TripReviewPayload(
      route: '新复盘路线：广州塔 → 永庆坊',
      highlightPhotos: ['新上传旅拍'],
      newMemories: ['喜欢珠江边轻松散步'],
      completedTasks: [],
      reminderHighlights: [],
      avatarStatusChanges: ['蓝小心记录了新的旅拍高光'],
      nextTripSuggestions: ['下次可以试试广州老城慢游'],
      temporaryMemoryPromotions: [],
    );
  }
}

class PhotoNewerThanReviewDashboardService extends TripDashboardService {
  PhotoNewerThanReviewDashboardService() : super(dio: Dio());

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String? userId,
    String? tripId,
  }) async {
    return TripDashboardPayload(
      userId: userId ?? 'guest',
      tripId: tripId ?? 'guangzhou-trip',
      currentTrip: const {'tripId': 'guangzhou-trip', 'status': 'planning'},
      routePoints: const {'route': '广州塔 → 永庆坊', 'points': []},
      reminderHistory: const [],
      blindBoxTasks: const [],
      avatarStateEvents: const [],
      latestReview: const {
        'reviewId': 'old-review',
        'tripId': 'guangzhou-trip',
        'createdAt': '2026-07-05T08:00:00',
        'review': {
          'route': '旧复盘路线：广州塔',
          'highlightPhotos': ['旧照片'],
          'newMemories': [],
          'completedTasks': [],
          'reminderHighlights': [],
          'avatarStatusChanges': [],
          'nextTripSuggestions': [],
          'temporaryMemoryPromotions': [],
        },
      },
      photoCandidates: const [
        {
          'id': 'new-photo',
          'tripId': 'guangzhou-trip',
          'location': '新上传旅拍',
          'description': '刚刚上传的珠江边旅拍',
          'updatedAt': '2026-07-05T09:00:00',
          'canAddToReview': true,
        },
      ],
      memories: const [],
    );
  }
}

class MutablePhotoDashboardService extends TripDashboardService {
  MutablePhotoDashboardService() : super(dio: Dio());

  bool hasNewPhoto = false;

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String? userId,
    String? tripId,
  }) async {
    return TripDashboardPayload(
      userId: userId ?? 'guest',
      tripId: tripId ?? 'guangzhou-trip',
      currentTrip: const {'tripId': 'guangzhou-trip', 'status': 'planning'},
      routePoints: const {'route': '广州塔 → 永庆坊', 'points': []},
      reminderHistory: const [],
      blindBoxTasks: const [],
      avatarStateEvents: const [],
      latestReview: const {
        'reviewId': 'old-review',
        'tripId': 'guangzhou-trip',
        'createdAt': '2026-07-05T08:00:00',
        'review': {
          'route': '旧复盘路线：广州塔',
          'highlightPhotos': ['旧照片'],
          'newMemories': [],
          'completedTasks': [],
          'reminderHighlights': [],
          'avatarStatusChanges': [],
          'nextTripSuggestions': [],
          'temporaryMemoryPromotions': [],
        },
      },
      photoCandidates: hasNewPhoto
          ? const [
              {
                'id': 'new-photo',
                'tripId': 'guangzhou-trip',
                'location': '新上传旅拍',
                'description': '刚刚上传的珠江边旅拍',
                'updatedAt': '2026-07-05T09:00:00',
                'canAddToReview': true,
              },
            ]
          : const [],
      memories: const [],
    );
  }
}

void main() {
  tearDown(() {
    latestAgentResponse.value = null;
  });

  testWidgets(
    'ReviewPage fetches generated review when no chat response exists',
    (tester) async {
      latestAgentResponse.value = null;

      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            tripReviewService: StubTripReviewService(),
            profileService: StubReviewProfileService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('测试路线'), findsWidgets);
      expect(find.text('拍一张夜景'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('成都慢节奏美食线'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('成都慢节奏美食线'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('想轻松一点'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('想轻松一点'), findsOneWidget);
    },
  );

  testWidgets(
    'ReviewPage prefers fetched latest review over stale cached tripReview card',
    (tester) async {
      latestAgentResponse.value = const AgentChatResponse(
        replyText: '旧复盘',
        voiceText: '旧复盘',
        avatarState: AvatarState.thinking,
        emotion: 'stale',
        cards: [
          {
            'type': 'tripPlan',
            'payload': {'tripId': 'guangzhou-trip'},
          },
          {
            'type': 'tripReview',
            'payload': {
              'route': '旧复盘路线：北京站 → 什刹海',
              'highlightPhotos': ['旧北京照片'],
              'newMemories': ['旧记忆'],
              'completedTasks': [],
              'avatarStatusChanges': ['旧状态'],
              'nextTripSuggestions': ['旧建议'],
              'temporaryMemoryPromotions': [],
            },
          },
        ],
        memoryCandidates: [],
        toolTrace: [],
        nextActions: [],
        syncSuggestions: [],
        errors: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            tripReviewService: FetchingTripReviewService(),
            profileService: StubReviewProfileService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('最新复盘路线：广州塔'), findsWidgets);
      expect(find.text('广州塔夜景'), findsOneWidget);
      expect(find.textContaining('旧复盘路线：北京站'), findsNothing);
      expect(find.text('旧北京照片'), findsNothing);
    },
  );

  testWidgets(
    'ReviewPage regenerates review when dashboard photos are newer than latest review',
    (tester) async {
      latestAgentResponse.value = const AgentChatResponse(
        replyText: '行程已创建',
        voiceText: '行程已创建',
        avatarState: AvatarState.planning,
        emotion: 'planning',
        cards: [
          {
            'type': 'tripPlan',
            'payload': {'tripId': 'guangzhou-trip'},
          },
        ],
        memoryCandidates: [],
        toolTrace: [],
        nextActions: [],
        syncSuggestions: [],
        errors: [],
      );
      final reviewService = StaleDashboardReviewService();

      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            tripReviewService: reviewService,
            dashboardService: PhotoNewerThanReviewDashboardService(),
            profileService: StubReviewProfileService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(reviewService.generated, isTrue);
      expect(reviewService.generatedTripId, 'guangzhou-trip');
      expect(find.textContaining('新复盘路线：广州塔'), findsWidgets);
      expect(find.text('新上传旅拍'), findsOneWidget);
      expect(find.text('旧照片'), findsNothing);
    },
  );

  testWidgets('ReviewPage refresh button reloads newer photo-backed review', (
    tester,
  ) async {
    latestAgentResponse.value = const AgentChatResponse(
      replyText: '行程已创建',
      voiceText: '行程已创建',
      avatarState: AvatarState.planning,
      emotion: 'planning',
      cards: [
        {
          'type': 'tripPlan',
          'payload': {'tripId': 'guangzhou-trip'},
        },
      ],
      memoryCandidates: [],
      toolTrace: [],
      nextActions: [],
      syncSuggestions: [],
      errors: [],
    );
    final dashboardService = MutablePhotoDashboardService();
    final reviewService = StaleDashboardReviewService();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          tripReviewService: reviewService,
          dashboardService: dashboardService,
          profileService: StubReviewProfileService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('旧照片'), findsOneWidget);
    expect(reviewService.generated, isFalse);

    dashboardService.hasNewPhoto = true;
    await tester.tap(find.byKey(const ValueKey('review-refresh-button')));
    await tester.pumpAndSettle();

    expect(reviewService.generated, isTrue);
    expect(find.text('新上传旅拍'), findsOneWidget);
    expect(find.text('旧照片'), findsNothing);
  });
}
