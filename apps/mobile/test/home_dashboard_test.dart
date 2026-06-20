import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/home/home_page.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_dashboard_service.dart';

class StubHomeDashboardService extends TripDashboardService {
  StubHomeDashboardService() : super();

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String userId = 'guest',
    String? tripId,
  }) async {
    return TripDashboardPayload(
      userId: userId,
      tripId: tripId ?? 'trip-home',
      currentTrip: const {
        'tripId': 'trip-home',
        'destination': 'Hangzhou',
        'status': 'active',
        'plan': {'title': 'West Lake night route'},
      },
      routePoints: const {'route': 'Hotel -> West Lake'},
      reminderHistory: const [
        {
          'items': [
            {'title': 'Rain reminder'},
          ],
        },
      ],
      blindBoxTasks: const [],
      avatarStateEvents: const [
        {'eventType': 'chat_interaction'},
      ],
      latestReview: const {},
      photoCandidates: const [],
      memories: const [
        {'title': 'Prefers night views'},
        {'title': 'Avoids cilantro'},
      ],
    );
  }
}

void main() {
  testWidgets('HomePage displays dashboard trip summary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomePage(dashboardService: StubHomeDashboardService())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Hangzhou'), findsOneWidget);
    expect(find.textContaining('2 memories'), findsOneWidget);
    expect(find.textContaining('1 reminder'), findsOneWidget);
  });
}
