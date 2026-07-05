import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/core/constants/avatar_states.dart';
import 'package:lanxin_travelmate/data/agent_response_cache.dart';
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
  setUp(() {
    latestAgentResponse.value = null;
  });

  tearDown(() {
    latestAgentResponse.value = null;
  });

  Future<void> enterTextWhenVisible(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(finder, text);
  }

  Future<void> tapWhenVisible(
    WidgetTester tester,
    Finder finder, {
    double delta = 180,
  }) async {
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(finder, delta, scrollable: scrollable);
    await tester.pumpAndSettle();
    final rect = tester.getRect(finder);
    if (rect.bottom > 580) {
      await tester.drag(scrollable, Offset(0, -(rect.bottom - 560)));
      await tester.pumpAndSettle();
    } else if (rect.top < 20) {
      await tester.drag(scrollable, Offset(0, 40 - rect.top));
      await tester.pumpAndSettle();
    }
    await tester.tap(finder);
  }

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

  testWidgets('TripPage hides internal and meaningless planning text', (
    tester,
  ) async {
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
            'title': '广州轻松两日线',
            'destination': '广州',
            'dateRange': '周末两天',
            'profileMatches': [
              'medium budget applied',
              'night view preference',
            ],
            'days': [],
            'dynamicAdjustment': {
              'trigger': 'model fallback',
              'suggestion': 'route_tool 缺少坐标，需手动规划',
            },
            'risks': ['路线规划工具因为缺少坐标信息无法生成详细步行路线，需手动规划点位间交通'],
            'alternatives': [
              {
                'title': '备选方案 1',
                'summary': 'fallback model text',
                'bestFor': '真实模型返回的文本备选方案',
              },
            ],
            'externalContext': {
              'route': {
                'mode': 'transit',
                'fallbackReason':
                    '路线接口需要 originLocation 与 destinationLocation 坐标。',
              },
            },
            'toolTrace': [
              {
                'tool': 'model_provider',
                'provider': 'mock',
                'fallbackReason': '当前使用 MockModelProvider',
              },
            ],
          },
        },
      ],
    );

    await tester.pumpWidget(const MaterialApp(home: TripPage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('真实模型', skipOffstage: false), findsNothing);
    expect(find.textContaining('model', skipOffstage: false), findsNothing);
    expect(
      find.textContaining('route_tool', skipOffstage: false),
      findsNothing,
    );
    expect(find.textContaining('路线规划工具', skipOffstage: false), findsNothing);
    expect(find.textContaining('缺少坐标', skipOffstage: false), findsNothing);
    expect(find.textContaining('provider=', skipOffstage: false), findsNothing);
    expect(
      find.textContaining('MockModelProvider', skipOffstage: false),
      findsNothing,
    );
    expect(find.textContaining('中等预算', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('夜景', skipOffstage: false), findsOneWidget);
    expect(
      find.textContaining('出发前在地图 App 再确认一次', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('天气变化或体力不足', skipOffstage: false),
      findsOneWidget,
    );
  });

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
      expect(find.textContaining('夜景'), findsOneWidget);
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

    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('trip-destination-input')),
      'Hangzhou',
    );
    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('trip-companions-input')),
      'mother, child',
    );
    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('trip-preferences-input')),
      'night view, less walking',
    );
    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('trip-budget-medium')),
    );
    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('trip-transport-transit')),
    );
    final createButton = find.byKey(const ValueKey('trip-create-plan-button'));
    await tapWhenVisible(tester, createButton);
    await tester.pumpAndSettle();

    expect(planService.capturedDraft?.destination, 'Hangzhou');
    expect(planService.capturedDraft?.originCoordinate, isNull);
    expect(planService.capturedDraft?.destinationCoordinate, isNull);
    expect(planService.capturedDraft?.startDate, isNull);
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

    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('trip-destination-input')),
      'Hangzhou',
    );
    final createButton = find.byKey(const ValueKey('trip-create-plan-button'));
    await tapWhenVisible(tester, createButton);
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

    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('trip-destination-input')),
      'Hangzhou',
    );
    final createButton = find.byKey(const ValueKey('trip-create-plan-button'));
    await tapWhenVisible(tester, createButton);
    await tester.pumpAndSettle();

    final replanButton = find.byKey(const ValueKey('trip-replan-weather-risk'));
    await tapWhenVisible(tester, replanButton);
    await tester.pumpAndSettle();

    expect(planService.requests, hasLength(2));
    expect(planService.requests.last.replanReason, 'weather_risk');
    expect(planService.requests.last.destination, 'Hangzhou');
  });
  testWidgets('TripPage includes group coordination in plan request', (
    tester,
  ) async {
    final groupService = StubTripGroupService();
    final planService = StubTripPlanService();
    await tester.pumpWidget(
      MaterialApp(
        home: TripPage(
          dashboardService: EmptyTripDashboardService(),
          groupService: groupService,
          planService: planService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('trip-destination-input')),
      '重庆',
    );
    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('group-member-a-preferences-input')),
      '慢节奏, 夜景',
    );
    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('group-member-b-preferences-input')),
      '预算低, 夜景',
    );
    final coordinateButton = find.byKey(
      const ValueKey('trip-coordinate-group-button'),
    );
    await tapWhenVisible(tester, coordinateButton);
    await tester.pumpAndSettle();

    final createButton = find.byKey(const ValueKey('trip-create-plan-button'));
    await tapWhenVisible(tester, createButton, delta: -180);
    await tester.pumpAndSettle();

    final coordination = planService.capturedDraft?.groupCoordination;
    expect(coordination?['coordinationId'], 'group-test');
    expect(coordination?['compromisePlan'], isA<Map<String, dynamic>>());
    expect(coordination?['conflicts'], isA<List<dynamic>>());
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

    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('trip-destination-input')),
      '重庆',
    );
    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('group-member-a-name-input')),
      '小林',
    );
    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('group-member-a-preferences-input')),
      '慢节奏, 夜景, 不吃香菜',
    );
    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('group-member-b-name-input')),
      '阿远',
    );
    await enterTextWhenVisible(
      tester,
      find.byKey(const ValueKey('group-member-b-preferences-input')),
      '预算低, 夜景, 山城步道',
    );
    final coordinateButton = find.byKey(
      const ValueKey('trip-coordinate-group-button'),
    );
    await tapWhenVisible(tester, coordinateButton);
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
