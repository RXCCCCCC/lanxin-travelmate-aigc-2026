from fastapi.testclient import TestClient
from uuid import uuid4

from app.main import app


client = TestClient(app)


def _guest_headers(device_id: str) -> tuple[str, dict[str, str]]:
    response = client.post("/api/auth/guest", json={"deviceId": device_id, "displayName": "Scoped Guest"})
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_sync_push_pull_and_selected_memory():
    user_id, headers = _guest_headers(f"sync-user-a-{uuid4().hex}")
    push = client.post(
        "/api/sync/push",
        headers=headers,
        json={
            "userId": "guest",
            "memories": [
                {
                    "id": "sync-mem-a",
                    "title": "喜欢博物馆",
                    "content": "规划时优先保留博物馆。",
                    "scope": "longTerm",
                    "confidence": 0.9,
                }
            ],
            "profile": {
                "travelPace": "慢节奏",
                "dietaryPreferences": ["少辣"],
                "interestTags": ["博物馆"],
            },
            "trips": [
                {
                    "id": "sync-trip-a",
                    "destination": "成都",
                    "status": "planning",
                    "plan": {"title": "成都慢逛"},
                }
            ],
        },
    )
    assert push.status_code == 200
    assert push.json()["pushed"] == {"memories": 1, "profile": 1, "trips": 1}

    pull = client.get("/api/sync/pull", headers=headers)
    assert pull.status_code == 200
    payload = pull.json()
    assert payload["profile"]["travelPace"] == "慢节奏"
    assert payload["memories"][0]["id"] == "sync-mem-a"
    assert payload["trips"][0]["id"] == "sync-trip-a"

    selected = client.post(
        "/api/sync/selected-memory",
        headers=headers,
        json={"userId": "guest", "memoryIds": ["sync-mem-a"]},
    )
    assert selected.status_code == 200
    assert selected.json()["selected"][0]["id"] == "sync-mem-a"


def test_clear_memory_and_current_trip_endpoints():
    user_id, headers = _guest_headers(f"clear-user-a-{uuid4().hex}")
    client.post(
        "/api/memory/capsules",
        headers=headers,
        json={
            "id": "clear-mem-a",
            "userId": "guest",
            "title": "不吃香菜",
            "content": "点单提醒。",
            "scope": "longTerm",
        },
    )
    exported = client.get("/api/memory/export", headers=headers)
    assert any(item["id"] == "clear-mem-a" for item in exported.json()["items"])

    cleared = client.delete("/api/memory/capsules", headers=headers)
    assert cleared.status_code == 200
    assert cleared.json()["deleted"] >= 1

    client.post(
        "/api/trip/plan",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": "clear-trip-a",
            "destination": "重庆",
            "message": "周末想去重庆两天",
        },
    )
    current = client.get("/api/trip/current", headers=headers)
    assert current.json()["tripId"] == "clear-trip-a"

    cleared_trip = client.delete("/api/trip/current", headers=headers)
    assert cleared_trip.status_code == 200
    assert cleared_trip.json()["deleted"] >= 1
    empty = client.get("/api/trip/current", headers=headers)
    assert empty.json()["status"] == "empty"
