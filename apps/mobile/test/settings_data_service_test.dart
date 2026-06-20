import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/settings/data/settings_data_service.dart';

void main() {
  test('SettingsDataService maps privacy and data control endpoints', () async {
    final requests = <String>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add('${options.method} ${options.path}');
            switch ('${options.method} ${options.path}') {
              case 'GET /api/privacy/summary':
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'principles': ['Consent first'],
                      'permissions': [
                        {
                          'permission': 'location',
                          'label': 'Location',
                          'purpose': 'Route reminders',
                          'fallback': 'Manual destination input',
                        },
                      ],
                      'userControls': {'canExportData': true},
                    },
                  ),
                );
              case 'GET /api/memory/export':
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'items': [
                        {'id': 'm-1'},
                        {'id': 'm-2'},
                      ],
                    },
                  ),
                );
              case 'DELETE /api/memory/capsules':
                handler.resolve(
                  Response(requestOptions: options, data: {'deleted': 2}),
                );
              case 'DELETE /api/trip/current':
                handler.resolve(
                  Response(requestOptions: options, data: {'deleted': 1}),
                );
              case 'POST /api/sync/revoke':
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'revoked': {'memories': 1, 'profile': 1, 'trips': 0},
                    },
                  ),
                );
              default:
                handler.reject(
                  DioException(
                    requestOptions: options,
                    error: 'unexpected request',
                  ),
                );
            }
          },
        ),
      );

    final service = SettingsDataService(dio: dio);

    final privacy = await service.fetchPrivacySummary();
    final exported = await service.exportMemories();
    final clearedMemories = await service.clearAllMemories();
    final clearedTrip = await service.clearCurrentTrip();
    final revoked = await service.revokeCloudSync(
      memoryIds: const ['m-1'],
      revokeProfile: true,
    );

    expect(privacy.principles, contains('Consent first'));
    expect(privacy.permissions.single.label, 'Location');
    expect(exported.itemCount, 2);
    expect(clearedMemories.deleted, 2);
    expect(clearedTrip.deleted, 1);
    expect(revoked.revoked['profile'], 1);
    expect(requests, contains('GET /api/privacy/summary'));
    expect(requests, contains('POST /api/sync/revoke'));
  });

  test('SettingsDataService pushes memory drafts and maps conflicts', () async {
    Map<String, dynamic>? capturedBody;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = Map<String, dynamic>.from(options.data as Map);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'status': 'ok',
                  'pushed': {'memories': 0, 'profile': 0, 'trips': 0},
                  'conflicts': [
                    {
                      'entityType': 'memory',
                      'entityId': 'm-1',
                      'resolution': 'serverWins',
                      'clientUpdatedAt': '2026-06-19T08:00:00Z',
                      'serverUpdatedAt': '2026-06-20T08:00:00Z',
                      'server': {'title': 'server title'},
                      'client': {'title': 'client title'},
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

    final service = SettingsDataService(dio: dio);

    final result = await service.pushSync(
      conflictStrategy: 'serverWins',
      memories: const [
        SyncMemoryDraft(
          id: 'm-1',
          title: 'client title',
          content: 'client content',
          scope: 'longTerm',
          updatedAt: '2026-06-19T08:00:00Z',
        ),
      ],
    );

    expect(capturedBody?['conflictStrategy'], 'serverWins');
    expect((capturedBody?['memories'] as List).single['id'], 'm-1');
    expect(result.conflicts.single.entityId, 'm-1');
    expect(result.conflicts.single.resolution, 'serverWins');
    expect(result.conflicts.single.server['title'], 'server title');
  });
}
