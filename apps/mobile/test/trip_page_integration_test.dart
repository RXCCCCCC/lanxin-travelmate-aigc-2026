import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanxin_travelmate/core/constants/avatar_states.dart';
import 'package:lanxin_travelmate/data/demo_agent_state.dart';
import 'package:lanxin_travelmate/features/chat/data/agent_chat_models.dart';
import 'package:lanxin_travelmate/features/trip/trip_page.dart';

void main() {
  tearDown(() {
    latestAgentResponse.value = null;
  });

  testWidgets('TripPage displays alternatives and navigation links from agent plan', (tester) async {
    latestAgentResponse.value = const AgentChatResponse(
      replyText: '规划完成',
      voiceText: '规划完成',
      avatarState: AvatarState.planning,
      emotion: 'curious',
      memoryCandidates: [],
      toolTrace: [],
      nextActions: [],
      syncSuggestions: [],
      errors: [],
      cards: [
        {
          'type': 'tripPlan',
          'payload': {
            'title': '重庆两日轻松夜景线',
            'destination': '重庆',
            'dateRange': '周末两天',
            'profileMatches': [],
            'days': [],
            'risks': [],
            'alternatives': [
              {
                'title': '雨天室内轻松版',
                'summary': '改去三峡博物馆和来福士室内观景。',
              }
            ],
            'navigationLinks': [
              {
                'label': '打开高德导航到洪崖洞',
                'url': 'androidamap://route?dname=洪崖洞',
              }
            ],
          },
        }
      ],
    );

    await tester.pumpWidget(const MaterialApp(home: TripPage()));

    expect(find.text('雨天室内轻松版'), findsOneWidget);
    expect(find.text('打开高德导航到洪崖洞'), findsOneWidget);
  });
}
