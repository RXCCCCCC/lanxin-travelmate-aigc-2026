import '../../../core/constants/avatar_states.dart';

class MemoryCandidate {
  const MemoryCandidate({
    required this.id,
    required this.title,
    required this.content,
    required this.scopeOptions,
    required this.recommendedScope,
    required this.reason,
  });

  final String id;
  final String title;
  final String content;
  final List<String> scopeOptions;
  final String recommendedScope;
  final String reason;

  factory MemoryCandidate.fromJson(Map<String, dynamic> json) {
    return MemoryCandidate(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      scopeOptions: (json['scopeOptions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      recommendedScope: json['recommendedScope'] as String? ?? 'currentTrip',
      reason: json['reason'] as String? ?? '',
    );
  }
}

class AgentChatResponse {
  const AgentChatResponse({
    required this.replyText,
    required this.voiceText,
    required this.avatarState,
    required this.emotion,
    required this.cards,
    required this.memoryCandidates,
    required this.toolTrace,
    required this.nextActions,
    required this.syncSuggestions,
    required this.errors,
  });

  final String replyText;
  final String voiceText;
  final AvatarState avatarState;
  final String emotion;
  final List<Map<String, dynamic>> cards;
  final List<MemoryCandidate> memoryCandidates;
  final List<Map<String, dynamic>> toolTrace;
  final List<Map<String, dynamic>> nextActions;
  final List<Map<String, dynamic>> syncSuggestions;
  final List<Map<String, dynamic>> errors;

  factory AgentChatResponse.fromJson(Map<String, dynamic> json) {
    return AgentChatResponse(
      replyText: json['replyText'] as String? ?? '',
      voiceText: json['voiceText'] as String? ?? '',
      avatarState: AvatarState.fromApiName(json['avatarState'] as String? ?? ''),
      emotion: json['emotion'] as String? ?? 'calm',
      cards: _mapList(json['cards']),
      memoryCandidates: (json['memoryCandidates'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MemoryCandidate.fromJson)
          .toList(),
      toolTrace: _mapList(json['toolTrace']),
      nextActions: _mapList(json['nextActions']),
      syncSuggestions: _mapList(json['syncSuggestions']),
      errors: _mapList(json['errors']),
    );
  }

  factory AgentChatResponse.fallback(String message) {
    return AgentChatResponse(
      replyText: message,
      voiceText: message,
      avatarState: AvatarState.thinking,
      emotion: 'fallback',
      cards: const [],
      memoryCandidates: const [],
      toolTrace: const [],
      nextActions: const [],
      syncSuggestions: const [],
      errors: const [
        {'code': 'NETWORK_FALLBACK', 'message': '后端暂不可用，已切换本地降级回复。'},
      ],
    );
  }
}

List<Map<String, dynamic>> _mapList(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();
}
