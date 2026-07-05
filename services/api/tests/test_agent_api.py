import json

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health_endpoint_returns_service_status():
    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["service"] == "lanxin-travelmate-api"


def test_agent_chat_returns_unified_mock_response():
    response = client.post(
        "/api/agent/chat",
        json={
            "message": "周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜",
            "sessionId": "demo-session",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert set(payload) == {
        "replyText",
        "voiceText",
        "avatarState",
        "emotion",
        "cards",
        "memoryCandidates",
        "toolTrace",
        "nextActions",
        "syncSuggestions",
        "errors",
    }
    assert payload["avatarState"] == "planning"
    assert payload["errors"] == []
    assert len(payload["memoryCandidates"]) >= 3
    assert any(item["title"] == "不吃香菜" for item in payload["memoryCandidates"])
    assert any(card["type"] == "tripPlan" for card in payload["cards"])
    assert any(step["tool"] == "weather_tool" for step in payload["toolTrace"])


def test_agent_chat_plain_message_uses_chat_only_graph(monkeypatch):
    from app.api.routes import agent

    calls: list[str] = []

    class ChatOnlyGraph:
        def invoke(self, state):
            raise AssertionError("plain agent chat must not run the full graph")

        def invoke_plan_only(self, state):
            raise AssertionError("plain agent chat must not run planning graph")

        def invoke_review_only(self, state):
            raise AssertionError("plain agent chat must not run review graph")

        def invoke_chat_only(self, state):
            calls.append(state["message"])
            return {
                **state,
                "model_call_logs": [],
                "response": {
                    "replyText": "我在，刚刚这句会走快速聊天链路。",
                    "voiceText": "我在，刚刚这句会走快速聊天链路。",
                    "avatarState": "hello",
                    "emotion": "warm",
                    "cards": [],
                    "memoryCandidates": [],
                    "toolTrace": [{"tool": "chat_only"}],
                    "nextActions": [],
                    "syncSuggestions": [],
                    "errors": [],
                },
            }

    monkeypatch.setattr(agent, "TravelMateGraph", ChatOnlyGraph)

    response = client.post(
        "/api/agent/chat",
        json={
            "message": "你好",
            "sessionId": "chat-only-session",
            "userId": "guest",
            "tripId": "chat-only-trip",
        },
    )

    assert response.status_code == 200
    assert calls == ["你好"]
    assert response.json()["toolTrace"] == [{"tool": "chat_only"}]


def test_agent_chat_memory_preference_prompts_explicit_confirmation():
    response = client.post(
        "/api/agent/chat",
        json={
            "message": "我不吃香菜",
            "sessionId": "memory-confirm-session",
            "userId": "guest",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert any(item["title"] == "不吃香菜" for item in payload["memoryCandidates"])
    assert "确认记忆胶囊" in payload["replyText"]
    assert "真正记入画像" in payload["replyText"]


def test_agent_chat_plan_reply_summarizes_plan_instead_of_only_redirecting(monkeypatch):
    from app.api.routes import agent

    class PlanOnlyGraph:
        def invoke_plan_only(self, state):
            return {
                **state,
                "model_call_logs": [],
                "trip_plan": {
                    "title": "广州轻松两日行程",
                    "destination": "广州",
                    "summary": "上午逛沙面，下午去永庆坊，晚上看珠江夜景。",
                    "risks": ["晚高峰过江路段可能拥堵。"],
                    "alternatives": [
                        {
                            "title": "雨天室内版",
                            "summary": "把户外街区替换为广东省博物馆和室内商圈。",
                        }
                    ],
                },
                "tool_trace": [],
                "errors": [],
            }

    monkeypatch.setattr(agent, "TravelMateGraph", PlanOnlyGraph)

    response = client.post(
        "/api/agent/chat",
        json={
            "message": "帮我规划广州两天行程",
            "sessionId": "plan-chat-session",
            "userId": "guest",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert "广州" in payload["replyText"]
    assert "沙面" in payload["replyText"]
    assert "雨天室内版" in payload["replyText"]
    assert "蓝小心" in payload["replyText"]
    assert "查看行程" not in payload["replyText"]
    assert any(card["type"] == "tripPlan" for card in payload["cards"])


def test_agent_chat_plan_reply_hides_internal_plan_fragments(monkeypatch):
    from app.api.routes import agent

    class DirtyPlanOnlyGraph:
        def invoke_plan_only(self, state):
            return {
                **state,
                "model_call_logs": [],
                "trip_plan": {
                    "title": "model fallback plan",
                    "destination": "广州",
                    "summary": "route_tool 缺少坐标，需手动规划",
                    "alternatives": [
                        {
                            "title": "备选方案",
                            "summary": "fallback model text",
                        }
                    ],
                },
                "tool_trace": [],
                "errors": [],
            }

    monkeypatch.setattr(agent, "TravelMateGraph", DirtyPlanOnlyGraph)

    response = client.post(
        "/api/agent/chat",
        json={
            "message": "帮我规划广州两天行程",
            "sessionId": "dirty-plan-chat-session",
            "userId": "guest",
        },
    )

    assert response.status_code == 200
    reply = response.json()["replyText"]
    assert "广州" in reply
    assert "model" not in reply
    assert "route_tool" not in reply
    assert "缺少坐标" not in reply
    assert "手动规划" not in reply
    assert "地图 App" in reply or "天气" in reply


def test_agent_chat_plan_card_payload_is_sanitized_like_trip_plan(monkeypatch):
    from app.api.routes import agent

    class DirtyPlanOnlyGraph:
        def invoke_plan_only(self, state):
            return {
                **state,
                "model_call_logs": [],
                "trip_plan": {
                    "title": "北京周末路线",
                    "destination": "待确认目的地",
                    "summary": "路线规划工具因为缺少坐标信息无法生成详细步行路线，需手动规划点位间交通",
                    "profileMatches": ["medium", "night view"],
                    "risks": [
                        "工具返回的POI数据存在偏差（返回北京点位），可能影响行程点位准确性",
                        "天气接口无有效数据",
                    ],
                    "dynamicAdjustment": {
                        "trigger": "待确认目的地实时拥挤和天气变化",
                        "suggestion": "fallback model",
                    },
                    "alternatives": [
                        {
                            "title": "备选方案",
                            "summary": "真实模型返回的文本备选方案",
                            "reason": "provider=mock",
                            "bestFor": "适合在原计划拥挤，天气变化或体力不足时切换",
                        }
                    ],
                },
                "tool_trace": [],
                "errors": [],
            }

    monkeypatch.setattr(agent, "TravelMateGraph", DirtyPlanOnlyGraph)

    response = client.post(
        "/api/agent/chat",
        json={
            "message": "帮我规划广州两天行程，预算 medium，喜欢 night view",
            "sessionId": "dirty-plan-card-session",
            "userId": "guest",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    card = next(card for card in payload["cards"] if card["type"] == "tripPlan")
    plan = card["payload"]
    plan_text = json.dumps(plan, ensure_ascii=False)
    assert "待确认目的地" not in plan_text
    assert "天气接口无有效数据" not in plan_text
    assert "POI数据存在偏差" not in plan_text
    assert "fallback model" not in plan_text
    assert "provider=mock" not in plan_text
    assert "真实模型返回" not in plan_text
    assert "medium" not in plan_text
    assert "night view" not in plan_text
    assert "广州" in plan_text
