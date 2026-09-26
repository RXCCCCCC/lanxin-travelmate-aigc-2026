import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/features/chat/data/chat_history_service.dart';

void main() {
  group('ChatHistoryMetadata', () {
    test('infers a readable title from destination in user message', () {
      final title = ChatHistoryMetadata.inferSessionTitle(
        '周末想去杭州两天，不想太累，喜欢夜景',
        'session-1',
      );

      expect(title, '杭州行程对话');
    });

    test('groups a new destination message under trip title', () {
      final now = DateTime(2026, 7, 4, 18, 30);
      final metadata = ChatHistoryMetadata.nextAfterMessage(
        current: null,
        sessionId: 'session-1',
        text: '我想去重庆三天，想吃火锅但不要太赶',
        now: now,
      );

      expect(metadata.title, '重庆行程对话');
      expect(metadata.tripTitle, '重庆行程');
      expect(metadata.destination, '重庆');
      expect(metadata.lastMessage, '我想去重庆三天，想吃火锅但不要太赶');
      expect(metadata.messageCount, 1);
    });

    test('preserves existing trip binding when later messages omit city', () {
      final current = ChatHistoryMetadata(
        title: '杭州行程对话',
        tripTitle: '杭州周末行程',
        lastMessage: '周末想去杭州',
        updatedAt: DateTime(2026, 7, 4, 10),
        messageCount: 2,
        tripId: 'trip-hangzhou',
        destination: '杭州',
      );

      final next = ChatHistoryMetadata.nextAfterMessage(
        current: current,
        sessionId: 'session-1',
        text: '第二天想轻松一点',
        now: DateTime(2026, 7, 4, 11),
      );

      expect(next.tripTitle, '杭州周末行程');
      expect(next.tripId, 'trip-hangzhou');
      expect(next.destination, '杭州');
      expect(next.messageCount, 3);
    });

    test('decodes plain old summaries as unbound sessions', () {
      final metadata = ChatHistoryMetadata.fromJson(
        '旧版摘要文本',
        fallbackSessionId: 'session-old',
      );

      expect(metadata.title, 'session-old');
      expect(metadata.tripTitle, '未绑定行程');
      expect(metadata.lastMessage, '旧版摘要文本');
    });
  });
}
