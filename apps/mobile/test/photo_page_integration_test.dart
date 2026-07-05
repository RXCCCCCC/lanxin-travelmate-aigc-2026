import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/photo/data/photo_experience_service.dart';
import 'package:lanxin_travelmate/features/photo/data/photo_selection_service.dart';
import 'package:lanxin_travelmate/features/photo/photo_page.dart';
import 'package:lanxin_travelmate/features/trip/data/trip_dashboard_service.dart';

class StubPhotoExperienceService extends PhotoExperienceService {
  StubPhotoExperienceService() : super(dio: Dio());

  bool createdCandidate = false;
  String? createdCandidateLocalUri;
  final List<String> updatedTaskStatuses = [];

  @override
  Future<List<Map<String, dynamic>>> fetchCandidates() async {
    return const [
      {
        'id': 'photo-night',
        'location': '洪崖洞',
        'score': 9.3,
        'description': '夜景高光',
        'tags': ['夜景'],
        'canAddToReview': true,
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> createUploadMetadata({
    String userId = 'guest',
    required String filename,
    String contentType = 'image/jpeg',
    String? localPath,
    String? remoteUrl,
  }) async {
    return const {
      'id': 'file-manual',
      'filename': 'manual-night.jpg',
      'contentType': 'image/jpeg',
      'localPath': null,
      'remoteUrl': 'https://cdn.example/manual-night.jpg',
      'privacy': {'localPathStored': false},
    };
  }

  @override
  Future<Map<String, dynamic>> createCandidate({
    String userId = 'guest',
    String? id,
    String? tripId,
    String? remoteUrl,
    required String location,
    required double score,
    required String description,
    List<String> tags = const [],
    bool canAddToReview = true,
  }) async {
    createdCandidate = true;
    return {
      'id': id ?? 'photo-manual',
      'location': location,
      'score': score,
      'description': description,
      'tags': tags,
      'localUri': null,
      'remoteUrl': remoteUrl,
      'canAddToReview': canAddToReview,
    };
  }

  @override
  Future<Map<String, dynamic>> generateCopywriting({
    List<String> photoIds = const [],
    String persona = '活泼向导',
    String style = '轻松',
  }) async {
    return const {
      'moments': '朋友圈文案：重庆夜色刚刚好。',
      'xiaohongshu': '小红书文案：重庆夜景线。',
      'diary': '旅行日记：夜景很美。',
      'vlogNarration': 'Vlog 旁白：山城亮灯了。',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBlindBoxTasks() async {
    return const [
      {'id': 'task-photo', 'type': 'photo', 'title': '拍一张夜景'},
    ];
  }

  @override
  Future<Map<String, dynamic>> updateBlindBoxTaskStatus({
    String userId = 'guest',
    required String tripId,
    required String taskId,
    required String status,
    String? note,
  }) async {
    updatedTaskStatuses.add('$taskId:$status');
    return {
      'id': 'record-$taskId',
      'taskId': taskId,
      'status': status,
      'title': '拍一张夜景',
      'rewardApplied': status == 'completed',
      'note': note,
    };
  }
}

class EmptyPhotoExperienceService extends StubPhotoExperienceService {
  @override
  Future<List<Map<String, dynamic>>> fetchCandidates() async => const [];

  @override
  Future<List<Map<String, dynamic>>> fetchBlindBoxTasks() async => const [];
}

class EmptyPhotoDashboardService extends TripDashboardService {
  EmptyPhotoDashboardService() : super(dio: Dio());

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String userId = 'guest',
    String? tripId,
  }) async {
    return TripDashboardPayload.fallback(userId: userId, tripId: tripId);
  }
}

class EmptyTripPhotoDashboardService extends TripDashboardService {
  EmptyTripPhotoDashboardService() : super(dio: Dio());

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String userId = 'guest',
    String? tripId,
  }) async {
    return TripDashboardPayload.fallback(userId: userId, tripId: 'photo-trip');
  }
}

class StubPhotoSelectionService extends PhotoSelectionService {
  static final Uint8List previewBytes = Uint8List.fromList(const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x02,
    0x00,
    0x00,
    0x00,
    0x90,
    0x77,
    0x53,
    0xDE,
    0x00,
    0x00,
    0x00,
    0x0C,
    0x49,
    0x44,
    0x41,
    0x54,
    0x08,
    0xD7,
    0x63,
    0xF8,
    0xCF,
    0xC0,
    0x00,
    0x00,
    0x03,
    0x01,
    0x01,
    0x00,
    0x18,
    0xDD,
    0x8D,
    0xB0,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  @override
  Future<SelectedPhoto?> pickFromGallery() async {
    return SelectedPhoto(
      localUri: 'content://photos/manual-night.jpg',
      filename: 'manual-night.jpg',
      mimeType: 'image/jpeg',
      source: 'gallery',
      previewBytes: previewBytes,
    );
  }
}

class StubPhotoDashboardService extends TripDashboardService {
  StubPhotoDashboardService() : super();

  @override
  Future<TripDashboardPayload> fetchDashboard({
    String userId = 'guest',
    String? tripId,
  }) async {
    return TripDashboardPayload(
      userId: userId,
      tripId: tripId ?? 'photo-trip',
      currentTrip: const {'status': 'planning', 'plan': <String, dynamic>{}},
      routePoints: const {'route': '', 'points': []},
      reminderHistory: const [],
      blindBoxTasks: const [
        {
          'id': 'task-dashboard-photo',
          'type': 'photo',
          'title': 'Dashboard photo mission',
          'status': 'completed',
        },
      ],
      avatarStateEvents: const [],
      latestReview: const {},
      photoCandidates: const [
        {
          'id': 'dashboard-photo',
          'location': 'West Lake',
          'score': 8.8,
          'description': 'A real dashboard photo candidate.',
          'tags': ['lake', 'night'],
          'canAddToReview': true,
        },
      ],
      memories: const [],
    );
  }
}

void main() {
  testWidgets(
    'PhotoPage shows candidates blind box tasks and generated copywriting',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PhotoPage(
            photoExperienceService: StubPhotoExperienceService(),
            dashboardService: EmptyTripPhotoDashboardService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('洪崖洞'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('拍一张夜景'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('拍一张夜景'), findsOneWidget);

      await tester.tap(find.text('生成文案'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('朋友圈文案'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('朋友圈文案'), findsOneWidget);
      expect(find.textContaining('小红书文案'), findsOneWidget);
    },
  );

  testWidgets(
    'PhotoPage uses dashboard candidates and blind box tasks before fallback services',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PhotoPage(
            photoExperienceService: StubPhotoExperienceService(),
            dashboardService: StubPhotoDashboardService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('West Lake'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Dashboard photo mission'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Dashboard photo mission'), findsOneWidget);
    },
  );
  testWidgets('PhotoPage can update blind box task status through API', (
    tester,
  ) async {
    final service = StubPhotoExperienceService();

    await tester.pumpWidget(
      MaterialApp(
        home: PhotoPage(
          photoExperienceService: service,
          dashboardService: EmptyTripPhotoDashboardService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('拍一张夜景'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('blind-box-task-photo-accept')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('blind-box-task-photo-complete')),
    );
    await tester.pumpAndSettle();

    expect(service.updatedTaskStatuses, [
      'task-photo:accepted',
      'task-photo:completed',
    ]);
    expect(find.textContaining('完成盲盒任务'), findsOneWidget);
  });

  testWidgets('PhotoPage can register a manual photo candidate through API', (
    tester,
  ) async {
    final service = StubPhotoExperienceService();

    await tester.pumpWidget(
      MaterialApp(
        home: PhotoPage(
          photoExperienceService: service,
          dashboardService: EmptyTripPhotoDashboardService(),
          photoSelectionService: StubPhotoSelectionService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('登记候选'));
    await tester.pumpAndSettle();

    expect(service.createdCandidate, isTrue);
    expect(find.text('相册地点待确认'), findsOneWidget);
    expect(find.textContaining('真实旅拍'), findsWidgets);
    expect(find.textContaining('已登记 manual-night.jpg'), findsOneWidget);
  });
  testWidgets('PhotoPage renders selected gallery photo preview on device', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoPage(
          photoExperienceService: StubPhotoExperienceService(),
          dashboardService: EmptyTripPhotoDashboardService(),
          photoSelectionService: StubPhotoSelectionService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('登记候选'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('photo-preview-selected-photo')),
      findsOneWidget,
    );
  });
  testWidgets(
    'PhotoPage shows empty state and retry action for no photo data',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PhotoPage(
            photoExperienceService: EmptyPhotoExperienceService(),
            dashboardService: EmptyPhotoDashboardService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('还没有旅拍候选'), findsOneWidget);
      expect(find.text('重试加载'), findsOneWidget);
    },
  );
}
