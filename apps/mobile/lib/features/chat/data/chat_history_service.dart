import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/constants/avatar_states.dart';
import '../../../data/local/app_database.dart' hide AvatarState, ChatMessage;
import '../../../shared/models/travelmate_models.dart';

class ChatSessionEntry {
  const ChatSessionEntry({
    required this.sessionId,
    required this.title,
    required this.tripTitle,
    required this.lastMessage,
    required this.updatedAt,
    required this.messageCount,
    this.tripId,
    this.destination,
  });

  final String sessionId;
  final String title;
  final String tripTitle;
  final String lastMessage;
  final DateTime updatedAt;
  final int messageCount;
  final String? tripId;
  final String? destination;

  bool get isTripBound => tripId != null || destination != null;
}

class TripConversationGroup {
  const TripConversationGroup({
    required this.tripTitle,
    required this.sessions,
    this.tripId,
  });

  final String tripTitle;
  final String? tripId;
  final List<ChatSessionEntry> sessions;
}

class ChatHistoryMetadata {
  const ChatHistoryMetadata({
    required this.title,
    required this.tripTitle,
    required this.lastMessage,
    required this.updatedAt,
    required this.messageCount,
    this.tripId,
    this.destination,
  });

  final String title;
  final String tripTitle;
  final String lastMessage;
  final DateTime updatedAt;
  final int messageCount;
  final String? tripId;
  final String? destination;

  Map<String, dynamic> toJson() => {
    'title': title,
    'tripTitle': tripTitle,
    'lastMessage': lastMessage,
    'updatedAt': updatedAt.toIso8601String(),
    'messageCount': messageCount,
    if (tripId != null) 'tripId': tripId,
    if (destination != null) 'destination': destination,
  };

  static ChatHistoryMetadata fromJson(
    String raw, {
    required String fallbackSessionId,
  }) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final updatedAt =
            DateTime.tryParse(decoded['updatedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return ChatHistoryMetadata(
          title: _safeText(decoded['title']) ?? '新的对话',
          tripTitle: _safeText(decoded['tripTitle']) ?? '未绑定行程',
          lastMessage: _safeText(decoded['lastMessage']) ?? '',
          updatedAt: updatedAt,
          messageCount:
              int.tryParse(decoded['messageCount']?.toString() ?? '') ?? 0,
          tripId: _safeText(decoded['tripId']),
          destination: _safeText(decoded['destination']),
        );
      }
    } catch (_) {
      // Old summaries may contain plain text. Fall through to a readable entry.
    }
    return ChatHistoryMetadata(
      title: fallbackSessionId,
      tripTitle: '未绑定行程',
      lastMessage: raw,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      messageCount: 0,
    );
  }

  static ChatHistoryMetadata nextAfterMessage({
    required ChatHistoryMetadata? current,
    required String sessionId,
    required String text,
    required DateTime now,
  }) {
    final destination = current?.destination ?? inferDestination(text);
    final tripTitle =
        current?.tripTitle ??
        (destination == null ? '未绑定行程' : '$destination行程');
    final title = current?.title ?? inferSessionTitle(text, sessionId);
    return ChatHistoryMetadata(
      title: title,
      tripTitle: tripTitle,
      lastMessage: text,
      updatedAt: now,
      messageCount: (current?.messageCount ?? 0) + 1,
      tripId: current?.tripId,
      destination: destination,
    );
  }

  static String inferSessionTitle(String text, String sessionId) {
    final destination = inferDestination(text);
    if (destination != null) return '$destination行程对话';
    final compact = text.replaceAll(RegExp(r'\s+'), '');
    if (compact.isNotEmpty) {
      return compact.length > 12 ? '${compact.substring(0, 12)}...' : compact;
    }
    return sessionId;
  }

  static String? inferDestination(String text) {
    const knownDestinations = [
      '杭州',
      '重庆',
      '北京',
      '上海',
      '广州',
      '深圳',
      '成都',
      '苏州',
      '南京',
      '西安',
      '厦门',
      '长沙',
      '武汉',
      '青岛',
      '大理',
      '丽江',
      '三亚',
      '拉萨',
      '东京',
      '大阪',
      '首尔',
      '曼谷',
      '新加坡',
    ];
    for (final destination in knownDestinations) {
      if (text.contains(destination)) return destination;
    }
    final match = RegExp(
      r'(?:去|到|在)([\u4e00-\u9fa5]{2,6})(?:玩|旅游|旅行|两天|三天|周末|出发|看|逛)',
    ).firstMatch(text);
    return match?.group(1);
  }

  ChatHistoryMetadata copyWith({
    String? title,
    String? tripTitle,
    String? lastMessage,
    DateTime? updatedAt,
    int? messageCount,
    String? tripId,
    String? destination,
  }) {
    return ChatHistoryMetadata(
      title: title ?? this.title,
      tripTitle: tripTitle ?? this.tripTitle,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      tripId: tripId ?? this.tripId,
      destination: destination ?? this.destination,
    );
  }
}

class ChatHistoryService {
  ChatHistoryService(this._db);

  final AppDatabase _db;

  Future<String> createSession({required String userId}) async {
    final now = DateTime.now();
    final sessionId = 'session-${now.microsecondsSinceEpoch}';
    final metadata = ChatHistoryMetadata(
      title: '新的对话',
      tripTitle: '未绑定行程',
      lastMessage: '',
      updatedAt: now,
      messageCount: 0,
    );
    await _writeMetadata(sessionId, metadata);
    return sessionId;
  }

  Future<void> bindSessionToTrip({
    required String sessionId,
    required String tripTitle,
    String? destination,
    String? tripId,
  }) async {
    final current = await _readMetadata(sessionId);
    final next =
        (current ??
                ChatHistoryMetadata(
                  title: '新的对话',
                  tripTitle: '未绑定行程',
                  lastMessage: '',
                  updatedAt: DateTime.now(),
                  messageCount: 0,
                ))
            .copyWith(
              tripTitle: tripTitle.trim().isEmpty ? '未命名行程' : tripTitle.trim(),
              destination: destination,
              tripId: tripId,
              updatedAt: DateTime.now(),
            );
    await _writeMetadata(sessionId, next);
  }

  Future<void> saveMessage({
    required String sessionId,
    required MessageSender sender,
    required String text,
    AvatarState? avatarState,
    Map<String, dynamic>? tripPlanCard,
  }) async {
    final now = DateTime.now();
    await _db
        .into(_db.chatMessages)
        .insert(
          ChatMessagesCompanion.insert(
            id: 'msg-${now.microsecondsSinceEpoch}',
            sessionId: sessionId,
            sender: sender.name,
            body: text,
            avatarState: Value(avatarState?.name),
            cardPayload: Value(
              tripPlanCard == null || tripPlanCard.isEmpty
                  ? null
                  : jsonEncode(tripPlanCard),
            ),
            createdAt: Value(now),
          ),
        );
    final current = await _readMetadata(sessionId);
    final next = ChatHistoryMetadata.nextAfterMessage(
      current: current,
      sessionId: sessionId,
      text: text,
      now: now,
    );
    await _writeMetadata(sessionId, next);
  }

  Future<List<ChatMessage>> loadMessages(String sessionId) async {
    final rows =
        await (_db.select(_db.chatMessages)
              ..where((row) => row.sessionId.equals(sessionId))
              ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
            .get();
    return rows
        .map(
          (row) => ChatMessage(
            id: row.id,
            sender: row.sender == MessageSender.user.name
                ? MessageSender.user
                : MessageSender.assistant,
            text: row.body,
            time: _formatTime(row.createdAt),
            avatarState: row.avatarState == null
                ? null
                : AvatarState.fromApiName(row.avatarState!),
            tripPlanCard: _decodeCardPayload(row.cardPayload),
          ),
        )
        .toList();
  }

  /// 返回最近一条有消息的会话，用于首页自动恢复上次对话。
  /// 无历史时返回 null。
  Future<ChatSessionEntry?> latestSession({required String userId}) async {
    final groups = await listGroupedSessions(userId: userId);
    ChatSessionEntry? latest;
    for (final group in groups) {
      for (final session in group.sessions) {
        if (session.messageCount <= 0) continue;
        if (latest == null || session.updatedAt.isAfter(latest.updatedAt)) {
          latest = session;
        }
      }
    }
    return latest;
  }

  Future<void> deleteSession(String sessionId) async {
    await (_db.delete(
      _db.chatMessages,
    )..where((row) => row.sessionId.equals(sessionId))).go();
    await (_db.delete(
      _db.chatSummaries,
    )..where((row) => row.sessionId.equals(sessionId))).go();
  }

  Future<List<TripConversationGroup>> listGroupedSessions({
    required String userId,
    String? includeEmptySessionId,
  }) async {
    final summaries = await (_db.select(
      _db.chatSummaries,
    )..orderBy([(row) => OrderingTerm.desc(row.summary)])).get();
    final sessions =
        summaries
            .map((row) {
              final metadata = ChatHistoryMetadata.fromJson(
                row.summary,
                fallbackSessionId: row.sessionId,
              );
              return ChatSessionEntry(
                sessionId: row.sessionId,
                title: metadata.title,
                tripTitle: metadata.tripTitle,
                lastMessage: metadata.lastMessage,
                updatedAt: metadata.updatedAt,
                messageCount: metadata.messageCount,
                tripId: metadata.tripId,
                destination: metadata.destination,
              );
            })
            .where(
              (session) =>
                  session.messageCount > 0 ||
                  session.sessionId == includeEmptySessionId,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final grouped = <String, List<ChatSessionEntry>>{};
    for (final session in sessions) {
      grouped.putIfAbsent(session.tripTitle, () => []).add(session);
    }
    return grouped.entries
        .map(
          (entry) => TripConversationGroup(
            tripTitle: entry.key,
            tripId: entry.value.first.tripId,
            sessions: entry.value,
          ),
        )
        .toList();
  }

  Future<ChatHistoryMetadata?> _readMetadata(String sessionId) async {
    final row = await (_db.select(
      _db.chatSummaries,
    )..where((item) => item.sessionId.equals(sessionId))).getSingleOrNull();
    if (row == null) return null;
    return ChatHistoryMetadata.fromJson(
      row.summary,
      fallbackSessionId: sessionId,
    );
  }

  Future<void> _writeMetadata(
    String sessionId,
    ChatHistoryMetadata metadata,
  ) async {
    await _db
        .into(_db.chatSummaries)
        .insert(
          ChatSummariesCompanion.insert(
            id: sessionId,
            sessionId: sessionId,
            summary: jsonEncode(metadata.toJson()),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

String? _safeText(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

Map<String, dynamic>? _decodeCardPayload(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {
    // 旧数据或损坏 JSON 直接忽略，退化为纯文本消息。
  }
  return null;
}
