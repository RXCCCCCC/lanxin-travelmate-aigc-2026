import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/data/demo_agent_state.dart';
import 'package:lanxin_travelmate/features/review/data/trip_review_service.dart';
import 'package:lanxin_travelmate/features/review/review_page.dart';

class StubTripReviewService extends TripReviewService {
  StubTripReviewService() : super(dio: Dio());

  @override
  Future<TripReviewPayload> generateReview({
    String message = '生成今天旅行复盘',
    String? tripId,
    List<Map<String, dynamic>> completedTasks = const [],
    List<Map<String, dynamic>> temporaryMemories = const [],
  }) async {
    return const TripReviewPayload(
      route: '测试路线：解放碑 → 洪崖洞',
      highlightPhotos: ['洪崖洞夜景'],
      newMemories: ['喜欢夜景'],
      completedTasks: [
        {'id': 'task-night-photo', 'title': '拍一张夜景', 'status': 'completed'}
      ],
      avatarStatusChanges: ['好感度 +2'],
      nextTripSuggestions: ['成都慢节奏美食线'],
      temporaryMemoryPromotions: [
        {'id': 'mem-slow-pace', 'title': '想轻松一点', 'suggestedScope': 'longTerm'}
      ],
    );
  }
}

void main() {
  tearDown(() {
    latestAgentResponse.value = null;
  });

  testWidgets('ReviewPage fetches generated review when no chat response exists', (tester) async {
    latestAgentResponse.value = null;

    await tester.pumpWidget(MaterialApp(
      home: ReviewPage(tripReviewService: StubTripReviewService()),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('测试路线'), findsOneWidget);
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
  });
}
