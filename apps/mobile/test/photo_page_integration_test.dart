import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/photo/data/photo_experience_service.dart';
import 'package:lanxin_travelmate/features/photo/photo_page.dart';

class StubPhotoExperienceService extends PhotoExperienceService {
  StubPhotoExperienceService() : super(dio: Dio());

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
      }
    ];
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
      {'id': 'task-photo', 'type': 'photo', 'title': '拍一张夜景'}
    ];
  }
}

void main() {
  testWidgets('PhotoPage shows candidates blind box tasks and generated copywriting', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PhotoPage(photoExperienceService: StubPhotoExperienceService()),
    ));
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
  });
}
