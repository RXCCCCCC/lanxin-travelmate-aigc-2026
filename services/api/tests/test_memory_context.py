import json
from uuid import uuid4

from fastapi.testclient import TestClient
from sqlmodel import Session

from app.agents.travelmate import nodes as travelmate_nodes
from app.agents.travelmate.state import create_initial_state
from app.api.routes import agent as agent_route
from app.db.models import CloudMemory
from app.db.session import engine
from app.main import app


client = TestClient(app)


def _guest_headers(label: str) -> tuple[str, dict[str, str]]:
    response = client.post(
        "/api/auth/guest",
        json={"deviceId": f"memory-context-{label}-{uuid4().hex}", "displayName": "Memory Context Guest"},
    )
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def _memory(
    user_id: str,
    memory_id: str,
    *,
    scope: str,
    status: str = "confirmed",
    category: str = "travel_preference",
    title: str = "偏好",
    content: str = "用户有一个旅行偏好。",
    source_text: str | None = None,
) -> CloudMemory:
    return CloudMemory(
        id=memory_id,
        user_id=user_id,
        title=title,
        content=content,
        scope=scope,
        status=status,
        category=category,
        source_text=source_text,
    )


def test_context_loader_aggregates_generic_memory_categories_without_fixture_profile():
    state = create_initial_state(
        message="帮我规划杭州行程",
        context={
            "memoryContext": {
                "items": [
                    {
                        "memoryId": "mem-diet",
                        "title": "饮食偏好",
                        "content": "不吃海鲜",
                        "category": "dietary_preference",
                        "scope": "longTerm",
                    },
                    {
                        "memoryId": "mem-pace",
                        "title": "出行节奏",
                        "content": "希望少走路",
                        "category": "pace_preference",
                        "scope": "currentTrip",
                    },
                    {
                        "memoryId": "mem-interest",
                        "title": "兴趣",
                        "content": "喜欢博物馆",
                        "category": "interest",
                        "scope": "longTerm",
                    },
                ]
            }
        },
    )

    result = travelmate_nodes.real_nodes.context_loader(state)

    assert result["user_profile"]["dietaryPreferences"] == ["不吃海鲜"]
    assert result["user_profile"]["travelPace"] == "希望少走路"
    assert result["user_profile"]["interestTags"] == ["喜欢博物馆"]
    assert result["context"]["memoryContext"]["items"][0]["memoryId"] == "mem-diet"


def test_agent_route_loads_only_confirmed_memory_in_current_scope(monkeypatch):
    user_id, headers = _guest_headers("route")
    trip_id = f"trip-{uuid4().hex}"
    records = [
        _memory(user_id, f"mem-long-{uuid4().hex}", scope="longTerm", title="饮食", content="不吃海鲜", category="dietary_preference"),
        _memory(user_id, f"mem-current-{uuid4().hex}", scope="currentTrip", source_text=trip_id, title="节奏", content="少走路", category="pace_preference"),
        _memory(user_id, f"mem-other-trip-{uuid4().hex}", scope="currentTrip", source_text="other-trip", title="其他行程", content="不去商圈"),
        _memory(user_id, f"mem-temp-{uuid4().hex}", scope="temporary", title="临时", content="只在当前对话使用"),
        _memory(user_id, f"mem-pending-{uuid4().hex}", scope="longTerm", status="pending_confirmation", title="待确认", content="不应使用"),
    ]
    expected_ids = {records[0].id, records[1].id}
    excluded_ids = {records[2].id, records[3].id, records[4].id}
    with Session(engine) as session:
        for record in records:
            session.add(record)
        session.commit()

    captured: dict[str, object] = {}

    def fake_route(_graph: object, state: dict[str, object]) -> dict[str, object]:
        captured.update(state)
        return {
            **state,
            "response": {
                "replyText": "已读取当前用户上下文。",
                "voiceText": "",
                "avatarState": "idle",
                "emotion": "calm",
                "cards": [],
                "memoryCandidates": [],
                "toolTrace": [],
                "nextActions": [],
                "syncSuggestions": [],
                "errors": [],
            },
            "model_call_logs": [],
        }

    monkeypatch.setattr(agent_route, "_route_agent_graph", fake_route)
    response = client.post(
        "/api/agent/chat",
        headers=headers,
        json={"sessionId": f"session-{uuid4().hex}", "tripId": trip_id, "message": "帮我规划杭州行程"},
    )

    assert response.status_code == 200
    memory_context = captured["context"]["memoryContext"]  # type: ignore[index]
    ids = {item["memoryId"] for item in memory_context["items"]}
    assert ids == expected_ids
    assert ids.isdisjoint(excluded_ids)


def test_trip_plan_contains_structured_memory_references_without_sensitive_content():
    state = create_initial_state(
        message="帮我规划杭州行程",
        context={
            "memoryContext": {
                "items": [
                    {
                        "memoryId": "mem-diet",
                        "title": "饮食偏好",
                        "content": "[敏感记忆已确认，仅保留结构化约束]",
                        "category": "health",
                        "scope": "currentTrip",
                        "sensitive": True,
                    },
                    {
                        "memoryId": "mem-interest",
                        "title": "兴趣偏好",
                        "content": "喜欢博物馆",
                        "category": "interest",
                        "scope": "longTerm",
                        "sensitive": False,
                    },
                ]
            }
        },
    )

    result = travelmate_nodes.real_nodes._merge_trip_plan_tool_context(
        {"profileMatches": []},
        state,
    )

    assert result["memoryReferences"] == [
        {
            "memoryId": "mem-diet",
            "title": "饮食偏好",
            "scope": "currentTrip",
            "appliedReason": "已作为当前行程的结构化约束参考。",
        },
        {
            "memoryId": "mem-interest",
            "title": "兴趣偏好",
            "scope": "longTerm",
            "appliedReason": "已作为长期旅行偏好参考。",
        },
    ]
    assert "喜欢博物馆" not in json.dumps(result["memoryReferences"], ensure_ascii=False)
