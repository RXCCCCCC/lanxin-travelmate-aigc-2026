from fastapi.testclient import TestClient
from uuid import uuid4

from app.main import app


client = TestClient(app)


def _guest_headers(label: str) -> tuple[str, dict[str, str]]:
    response = client.post(
        "/api/auth/guest",
        json={"deviceId": f"persistence-{label}-{uuid4().hex}", "displayName": "Persistence Guest"},
    )
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_memory_capsules_are_persisted_per_user():
    user_a_id, user_a_headers = _guest_headers("memory-a")
    _user_b_id, user_b_headers = _guest_headers("memory-b")
    memory_id = f"mem-db-{uuid4().hex}"
    response = client.post(
        "/api/memory/capsules",
        headers=user_a_headers,
        json={
            "id": memory_id,
            "userId": "guest",
            "title": "喜欢夜景",
            "content": "规划时保留夜景点。",
            "scope": "longTerm",
        },
    )
    assert response.status_code == 200

    user_a = client.get("/api/memory/capsules", headers=user_a_headers)
    user_b = client.get("/api/memory/capsules", headers=user_b_headers)

    assert any(item["id"] == memory_id and item["userId"] == user_a_id for item in user_a.json()["items"])
    assert all(item["id"] != memory_id for item in user_b.json()["items"])


def test_profile_is_persisted_per_user():
    user_id, headers = _guest_headers("profile")
    update = client.put(
        "/api/profile/me",
        headers=headers,
        json={
            "travelPace": "慢节奏",
            "dietaryPreferences": ["不吃香菜"],
            "interestTags": ["夜景", "老街"],
            "transportPreferences": ["少换乘"],
            "budgetPreference": "中低预算",
            "expressionStyle": "轻松口语",
        },
    )
    assert update.status_code == 200

    read_back = client.get("/api/profile/me", headers=headers)

    assert read_back.status_code == 200
    payload = read_back.json()
    assert payload["userId"] == user_id
    assert payload["travelPace"] == "慢节奏"
    assert payload["transportPreferences"] == ["少换乘"]
    assert payload["expressionStyle"] == "轻松口语"


def test_trip_plan_is_saved_as_current_trip():
    _user_id, headers = _guest_headers("trip")
    trip_id = f"trip-db-{uuid4().hex}"
    plan = client.post(
        "/api/trip/plan",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": trip_id,
            "destination": "重庆",
            "message": "周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜",
        },
    )
    assert plan.status_code == 200

    current = client.get("/api/trip/current", headers=headers)

    assert current.status_code == 200
    payload = current.json()
    assert payload["tripId"] == trip_id
    assert payload["destination"] == "重庆"
    assert payload["status"] == "planning"
    assert payload["plan"]["title"] == plan.json()["title"]
