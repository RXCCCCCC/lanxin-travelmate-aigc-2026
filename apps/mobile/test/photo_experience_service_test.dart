import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'package:lanxin_travelmate/features/photo/data/photo_experience_service.dart';

void main() {
  test(
    'PhotoExperienceService fetches candidates copywriting and blind box tasks',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/photo/candidates') {
              handler.resolve(
                Response<dynamic>(
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
                      },
                    ],
                  },
                ),
              );
              return;
            }
            if (options.path == '/api/photo/copywriting') {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'moments': '朋友圈文案：重庆夜色刚刚好。',
                    'xiaohongshu': '小红书文案：重庆夜景线。',
                    'diary': '旅行日记',
                    'vlogNarration': 'Vlog 旁白',
                  },
                ),
              );
              return;
            }
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'items': [
                    {'id': 'task-photo', 'type': 'photo', 'title': '拍一张夜景'},
                  ],
                },
              ),
            );
          },
        ),
      );

      final service = PhotoExperienceService(dio: dio);
      final candidates = await service.fetchCandidates();
      final copywriting = await service.generateCopywriting(
        photoIds: const ['photo-night'],
      );
      final tasks = await service.fetchBlindBoxTasks();

      expect(candidates.single['location'], '洪崖洞');
      expect(copywriting['moments'], contains('朋友圈'));
      expect(tasks.single['type'], 'photo');
    },
  );
  test(
    'PhotoExperienceService sends preview bytes to analysis endpoint',
    () async {
      RequestOptions? captured;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'location': '相机拍摄照片',
                  'score': 8.2,
                  'description': '这张照片适合作为旅拍高光，记录现场氛围。',
                  'tags': ['真实旅拍', '旅行场景', '横图'],
                  'reviewSuggestion': '建议加入复盘，补充当天地点和心情。',
                },
              ),
            );
          },
        ),
      );

      final result = await PhotoExperienceService(dio: dio).analyzePhoto(
        filename: 'preview.png',
        contentType: 'image/png',
        previewBytes: Uint8List.fromList([1, 2, 3, 4]),
        source: 'camera',
      );

      expect(captured?.path, '/api/photo/analyze');
      expect(captured?.data['imageBase64'], 'AQIDBA==');
      expect(captured?.data, isNot(contains('localPath')));
      expect(captured?.data, isNot(contains('localUri')));
      expect(result['tags'], contains('真实旅拍'));
      expect(result['description'], isNot(contains('KB')));
    },
  );

  test(
    'PhotoExperienceService offline analysis avoids placeholder wording',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: 'offline',
              ),
            );
          },
        ),
      );

      final result = await PhotoExperienceService(dio: dio).analyzePhoto(
        filename: 'offline.png',
        contentType: 'image/png',
        previewBytes: Uint8List.fromList([1, 2, 3, 4]),
        source: 'gallery',
      );

      final combined = [
        result['location'],
        result['description'],
        result['reviewSuggestion'],
        ...(result['tags'] as List<dynamic>? ?? const []),
      ].join(' ');

      expect(combined, contains('旅行场景'));
      expect(combined, contains('复盘'));
      for (final placeholder in ['地点待确认', '地点待标注', '补充地点', '旅拍候选']) {
        expect(combined, isNot(contains(placeholder)));
      }
    },
  );

  test(
    'PhotoExperienceService creates photo candidates and upload metadata',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            if (options.path == '/api/photo/upload-metadata') {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'file-a',
                    'filename': 'night.jpg',
                    'contentType': 'image/jpeg',
                    'localPath': null,
                    'remoteUrl': 'https://cdn.example/night.jpg',
                    'privacy': {'localPathStored': false},
                  },
                ),
              );
              return;
            }
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'photo-local-a',
                  'location': '洪崖洞',
                  'score': 8.9,
                  'description': '用户手动加入的夜景照片。',
                  'tags': ['手动导入', '夜景'],
                  'localUri': null,
                  'remoteUrl': 'https://cdn.example/night.jpg',
                  'canAddToReview': true,
                },
              ),
            );
          },
        ),
      );

      final service = PhotoExperienceService(dio: dio);
      final upload = await service.createUploadMetadata(
        filename: 'night.jpg',
        contentType: 'image/jpeg',
        localPath: '/device/private/night.jpg',
        remoteUrl: 'https://cdn.example/night.jpg',
      );
      final candidate = await service.createCandidate(
        id: 'photo-local-a',
        location: '洪崖洞',
        score: 8.9,
        description: '用户手动加入的夜景照片。',
        tags: const ['手动导入', '夜景'],
        remoteUrl: upload['remoteUrl']?.toString(),
      );

      expect(requests.first.path, '/api/photo/upload-metadata');
      expect(requests.first.data, isNot(contains('localPath')));
      expect(upload['privacy']['localPathStored'], isFalse);
      expect(candidate['location'], '洪崖洞');
      expect(candidate['localUri'], isNull);
      expect(candidate['tags'], contains('手动导入'));
    },
  );
  test('PhotoExperienceService updates blind box task status', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 'record-task-photo',
                'taskId': 'task-photo',
                'status': options.data['status'],
                'title': '拍一张夜景',
                'rewardApplied': options.data['status'] == 'completed',
              },
            ),
          );
        },
      ),
    );

    final result = await PhotoExperienceService(dio: dio)
        .updateBlindBoxTaskStatus(
          tripId: 'trip-a',
          taskId: 'task-photo',
          status: 'completed',
          note: 'done from mobile',
        );

    expect(captured?.path, '/api/trip/blind-box/tasks/task-photo/status');
    expect(captured?.data['tripId'], 'trip-a');
    expect(captured?.data['status'], 'completed');
    expect(result['rewardApplied'], isTrue);
  });
}
