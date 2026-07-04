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
