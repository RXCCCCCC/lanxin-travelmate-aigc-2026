import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/data/local/app_database.dart';
import 'package:lanxin_travelmate/data/repositories/memory_repository.dart';
import 'package:lanxin_travelmate/features/chat/chat_page.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_service.dart';
import 'package:lanxin_travelmate/features/home/home_page.dart';
import 'package:lanxin_travelmate/features/photo/data/photo_experience_service.dart';
import 'package:lanxin_travelmate/features/photo/photo_page.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_dashboard_service.dart';

class _StubPhotoExperienceService extends PhotoExperienceService {
  _StubPhotoExperienceService() : super(dio: Dio());

  @override
  Future<List<Map<String, dynamic>>> fetchCandidates() async {
    return const [
      {
        'id': 'photo-night',
        'location': '洪崖洞',
        'score': 9.3,
        'description': '夜景高光，适合复盘展示。',
        'tags': ['夜景', '高光照片'],
        'canAddToReview': true,
      },
      {
        'id': 'photo-river',
        'location': '嘉陵江边',
        'score': 8.8,
        'description': '开阔水面和城市灯光适合横构图。',
        'tags': ['江景'],
        'canAddToReview': true,
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBlindBoxTasks() async {
    return const [
      {'id': 'task-photo', 'type': 'photo', 'title': '拍一张夜景高光'},
    ];
  }
}

class _EmptyPhotoDashboardService extends TripDashboardService {
  _EmptyPhotoDashboardService() : super(dio: Dio());

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String userId = 'guest',
    String? tripId,
  }) async {
    return TripDashboardPayload.fallback(userId: userId, tripId: 'photo-trip');
  }
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child, {
  required Size size,
  double textScale = 1,
  bool settle = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, appChild) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: appChild!,
        );
      },
      home: child,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (child is HomePage) {
    await tester.pump(const Duration(seconds: 1));
  }
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('HomePage fits compact portrait and landscape phones', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      const HomePage(),
      size: const Size(360, 780),
      textScale: 1.2,
    );
    await _pumpAtSize(tester, const HomePage(), size: const Size(812, 375));
  });

  testWidgets(
    'ChatPage keeps input and shortcuts usable on compact large text',
    (tester) async {
      final database = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(database.close);

      await _pumpAtSize(
        tester,
        ChatPage(
          agentChatService: AgentChatService(dio: Dio()),
          memoryRepository: MemoryRepository(database),
        ),
        size: const Size(360, 780),
        textScale: 1.4,
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    },
  );

  testWidgets('PhotoPage adapts grid on compact and landscape screens', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      PhotoPage(
        photoExperienceService: _StubPhotoExperienceService(),
        dashboardService: _EmptyPhotoDashboardService(),
      ),
      size: const Size(360, 780),
      textScale: 1.4,
      settle: true,
    );
    await _pumpAtSize(
      tester,
      PhotoPage(
        photoExperienceService: _StubPhotoExperienceService(),
        dashboardService: _EmptyPhotoDashboardService(),
      ),
      size: const Size(812, 375),
      settle: true,
    );
  });
}
