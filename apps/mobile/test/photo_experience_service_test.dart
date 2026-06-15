import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/photo/data/photo_experience_service.dart';

void main() {
  test('PhotoExperienceService fetches candidates copywriting and blind box tasks', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path == '/api/photo/candidates') {
          handler.resolve(Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'items': [
                {
                  'id': 'photo-night',
                  'location': '洪崖洞',
                  'score': 9.3,
                  'description': '夜景高光',
                  'tags': ['夜景'],
                  'canAddToReview': true,
                }
              ]
            },
          ));
          return;
        }
        if (options.path == '/api/photo/copywriting') {
          handler.resolve(Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'moments': '朋友圈文案：重庆夜色刚刚好。',
              'xiaohongshu': '小红书文案：重庆夜景线。',
              'diary': '旅行日记',
              'vlogNarration': 'Vlog 旁白',
            },
          ));
          return;
        }
        handler.resolve(Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'items': [
              {'id': 'task-photo', 'type': 'photo', 'title': '拍一张夜景'}
            ]
          },
        ));
      },
    ));

    final service = PhotoExperienceService(dio: dio);
    final candidates = await service.fetchCandidates();
    final copywriting = await service.generateCopywriting(photoIds: const ['photo-night']);
    final tasks = await service.fetchBlindBoxTasks();

    expect(candidates.single['location'], '洪崖洞');
    expect(copywriting['moments'], contains('朋友圈'));
    expect(tasks.single['type'], 'photo');
  });
}
