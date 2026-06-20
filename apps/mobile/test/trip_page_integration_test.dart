import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/core/constants/avatar_states.dart';
import 'package:lanxin_travelmate/data/demo_agent_state.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_models.dart';
import 'package:lanxin_travelmate/features/profile/data/profile_service.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_dashboard_service.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_group_service.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_plan_service.dart';
import 'package:lanxin_travelmate/features/trip/trip_page.dart';

class StubTripDashboardService extends TripDashboardService {
  StubTripDashboardService() : super();

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String userId = 'guest',
    String? tripId,
  }) async {
    return TripDashboardPayload(
      userId: userId,
      tripId: tripId ?? 'dashboard-trip',
      currentTrip: const {
        'tripId': 'dashboard-trip',
        'status': 'planning',
        'destination': 'Hangzhou',
        'startDate': '2026-07-01',
        'endDate': '2026-07-03',
        'plan': {
          'title': 'Hangzhou real dashboard plan',
          'destination': 'Hangzhou',
          'dateRange': '2026-07-01 - 2026-07-03',
          'profileMatches': ['night view preference applied'],
          'days': [],
          'risks': [],
        },
      },
      routePoints: const {
        'route': 'Hotel -> West Lake',
        'points': [
          {'label': 'Hotel', 'time': '09:00'},
          {'label': 'West Lake', 'time': '10:00'},
        ],
      },
      reminderHistory: const [],
      blindBoxTasks: const [],
      avatarStateEvents: const [],
      latestReview: const {},
      photoCandidates: const [],
      memories: const [],
    );
  }
}

class StubTripPlanService extends TripPlanService {
  StubTripPlanService() : super();

  TripPlanRequestDraft? capturedDraft;
  final List<TripPlanRequestDraft> requests = [];

  @override
  Future<TripPlanResult> createPlan(TripPlanRequestDraft draft) async {
    capturedDraft = draft;
    requests.add(draft);
    return TripPlanResult.ok({
      'title': '${draft.destination} custom plan',
      'destination': draft.destination,
      'dateRange': '${draft.startDate} - ${draft.endDate}',
      'planningInputs': draft.toJson(),
      'profileMatches': ['${draft.budget} budget applied'],
      'days': const [],
      'risks': const [],
    });
  }
}

class StubTripGroupService extends TripGroupService {
  StubTripGroupService() : super();

  GroupCoordinationDraft? capturedDraft;

  @override
  Future<GroupCoordinationResult> coordinate(
    GroupCoordinationDraft draft,
  ) async {
    capturedDraft = draft;
    return GroupCoordinationResult.ok({
      'coordinationId': 'group-test',
      'tripId': draft.tripId,
      'destination': draft.destination,
      'conflicts': const [
        {'type': 'pace', 'title': '节奏冲突'},
      ],
      'compromisePlan': const {
        'pace': 'balanced_slow',
        'budget': 'low_first',
        'sharedInterests': ['夜景'],
      },
      'privacySummary': const {'publicRule': '多人模式默认只展示汇总后的协调依据。'},
    });
  }
}

class StubTripProfileService extends ProfileService {
  StubTripProfileService() : super();

  @override
  Future<ProfilePayload> fetchProfile({String userId = 'guest'}) async {
    return const ProfilePayload(
      userId: 'guest',
      travelPace: 'slow pace',
      dietaryPreferences: ['no cilantro'],
      interestTags: ['night views'],
      transportPreferences: ['transit'],
      budgetPreference: 'medium',
    );
  }
}

void main() {
  tearDown(() {
    latestAgentResponse.value = null;
  });

  testWidgets(
    'TripPage displays alternatives and navigation links from agent plan',
    (tester) async {
      latestAgentResponse.value = const AgentChatResponse(
        replyText: '规划完成',
        voiceText: '规划完成',
        avatarState: AvatarState.planning,
        emotion: 'curious',
        memoryCandidates: [],
        toolTrace: [],
        nextActions: [],
        syncSuggestions: [],
        errors: [],
        cards: [
          {
            'type': 'tripPlan',
            'payload': {
              'title': '重庆两日轻松夜景线',
              'destination': '重庆',
              'dateRange': '周末两天',
              'profileMatches': [],
              'days': [],
              'risks': [],
              'alternatives': [
                {'title': '雨天室内轻松版', 'summary': '改去三峡博物馆和来福士室内观景。'},
              ],
              'navigationLinks': [
                {'label': '打开高德导航到洪崖洞', 'url': 'androidamap://route?dname=洪崖洞'},
              ],
            },
          },
        ],
      );

      await tester.pumpWidget(const MaterialApp(home: TripPage()));

      expect(find.text('雨天室内轻松版'), findsOneWidget);
      expect(find.text('打开高德导航到洪崖洞'), findsOneWidget);
    },
  );

  testWidgets(
    'TripPage loads current plan from dashboard when agent plan is empty',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TripPage(dashboardService: StubTripDashboardService()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hangzhou real dashboard plan'), findsOneWidget);
      expect(
        find.textContaining('night view preference applied'),
        findsOneWidget,
      );
      expect(find.text('真实轨迹'), findsOneWidget);
      expect(find.textContaining('Hotel -> West Lake'), findsOneWidget);
      expect(find.textContaining('West Lake'), findsWidgets);
    },
  );

  testWidgets('TripPage creates a plan from user input', (tester) async {
    final planService = StubTripPlanService();
    await tester.pumpWidget(
      MaterialApp(
        home: TripPage(
          dashboardService: EmptyTripDashboardService(),
          planService: planService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('trip-destination-input')),
      'Hangzhou',
    );
    await tester.enterText(
      find.byKey(const ValueKey('trip-start-date-input')),
      '2026-07-01',
    );
    await tester.enterText(
      find.byKey(const ValueKey('trip-end-date-input')),
      '2026-07-03',
    );
    await tester.enterText(
      find.byKey(const ValueKey('trip-companions-input')),
      'mother, child',
    );
    await tester.enterText(
      find.byKey(const ValueKey('trip-preferences-input')),
      'night view, less walking',
    );
    await tester.tap(find.byKey(const ValueKey('trip-budget-medium')));
    await tester.tap(find.byKey(const ValueKey('trip-transport-transit')));
    await tester.tap(find.byKey(const ValueKey('trip-create-plan-button')));
    await tester.pumpAndSettle();

    expect(planService.capturedDraft?.destination, 'Hangzhou');
    expect(planService.capturedDraft?.startDate, '2026-07-01');
    expect(planService.capturedDraft?.companions, ['mother', 'child']);
    expect(planService.capturedDraft?.preferences, [
      'night view',
      'less walking',
    ]);
    expect(planService.capturedDraft?.budget, 'medium');
    expect(planService.capturedDraft?.transportMode, 'transit');
    expect(find.text('Hangzhou custom plan'), findsOneWidget);
  });

  testWidgets('TripPage applies profile preferences to plan request', (
    tester,
  ) async {
    final planService = StubTripPlanService();
    await tester.pumpWidget(
      MaterialApp(
        home: TripPage(
          dashboardService: EmptyTripDashboardService(),
          planService: planService,
          profileService: StubTripProfileService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('trip-destination-input')),
      'Hangzhou',
    );
    await tester.tap(find.byKey(const ValueKey('trip-create-plan-button')));
    await tester.pumpAndSettle();

    expect(planService.capturedDraft?.budget, 'medium');
    expect(planService.capturedDraft?.transportMode, 'transit');
    expect(planService.capturedDraft?.preferences, contains('night views'));
    expect(planService.capturedDraft?.preferences, contains('no cilantro'));
    expect(planService.capturedDraft?.preferences, contains('slow pace'));
  });

  testWidgets('TripPage sends replan reason after plan exists', (tester) async {
    final planService = StubTripPlanService();
    await tester.pumpWidget(
      MaterialApp(
        home: TripPage(
          dashboardService: EmptyTripDashboardService(),
          planService: planService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('trip-destination-input')),
      'Hangzhou',
    );
    await tester.tap(find.byKey(const ValueKey('trip-create-plan-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trip-replan-weather-risk')));
    await tester.pumpAndSettle();

    expect(planService.requests, hasLength(2));
    expect(planService.requests.last.replanReason, 'weather_risk');
    expect(planService.requests.last.destination, 'Hangzhou');
  });
  testWidgets('TripPage coordinates group preferences before planning', (
    tester,
  ) async {
    final groupService = StubTripGroupService();
    await tester.pumpWidget(
      MaterialApp(
        home: TripPage(
          dashboardService: EmptyTripDashboardService(),
          groupService: groupService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('trip-destination-input')),
      '重庆',
    );
    await tester.enterText(
      find.byKey(const ValueKey('group-member-a-name-input')),
      '小林',
    );
    await tester.enterText(
      find.byKey(const ValueKey('group-member-a-preferences-input')),
      '慢节奏, 夜景, 不吃香菜',
    );
    await tester.enterText(
      find.byKey(const ValueKey('group-member-b-name-input')),
      '阿远',
    );
    await tester.enterText(
      find.byKey(const ValueKey('group-member-b-preferences-input')),
      '预算低, 夜景, 山城步道',
    );
    final coordinateButton = find.byKey(
      const ValueKey('trip-coordinate-group-button'),
    );
    await tester.ensureVisible(coordinateButton);
    await tester.pumpAndSettle();
    await tester.tap(coordinateButton);
    await tester.pumpAndSettle();

    expect(groupService.capturedDraft?.destination, '重庆');
    expect(groupService.capturedDraft?.members, hasLength(2));
    expect(groupService.capturedDraft?.members.first.displayName, '小林');
    expect(
      groupService.capturedDraft?.members.first.preferences['interests'],
      contains('夜景'),
    );
    expect(find.textContaining('折中节奏：balanced_slow'), findsOneWidget);
    expect(find.textContaining('冲突：节奏冲突'), findsOneWidget);
    expect(find.textContaining('只展示汇总后的协调依据'), findsOneWidget);
  });
}

class EmptyTripDashboardService extends TripDashboardService {
  EmptyTripDashboardService() : super();

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String userId = 'guest',
    String? tripId,
  }) async {
    return TripDashboardPayload.fallback(userId: userId, tripId: tripId);
  }
}
