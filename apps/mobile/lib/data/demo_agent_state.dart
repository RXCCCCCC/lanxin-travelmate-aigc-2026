import 'package:flutter/foundation.dart';

import '../features/chat/data/agent_chat_models.dart';

final ValueNotifier<AgentChatResponse?> latestAgentResponse =
    ValueNotifier<AgentChatResponse?>(null);

Map<String, dynamic>? agentCardPayload(AgentChatResponse? response, String type) {
  if (response == null) return null;
  for (final card in response.cards) {
    if (card['type'] == type && card['payload'] is Map<String, dynamic>) {
      return card['payload'] as Map<String, dynamic>;
    }
  }
  return null;
}

List<Map<String, dynamic>> agentCardPayloadList(AgentChatResponse? response, String type) {
  if (response == null) return const [];
  for (final card in response.cards) {
    if (card['type'] == type && card['payload'] is List<dynamic>) {
      return (card['payload'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
  }
  return const [];
}
