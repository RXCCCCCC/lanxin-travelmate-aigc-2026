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
    memory_id = f"sync-mem-{uuid4().hex}"
    trip_id = f"sync-trip-{uuid4().hex}"
    push = client.post(
        "/api/sync/push",
        headers=headers,
        json={
            "userId": "guest",
            "memories": [
                {
                    "id": memory_id,
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
                    "id": trip_id,
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
    assert payload["memories"][0]["id"] == memory_id
    assert payload["trips"][0]["id"] == trip_id

    selected = client.post(
        "/api/sync/selected-memory",
        headers=headers,
        json={"userId": "guest", "memoryIds": [memory_id]},
    )
    assert selected.status_code == 200
    assert selected.json()["selected"][0]["id"] == memory_id


def test_clear_memory_and_current_trip_endpoints():
    user_id, headers = _guest_headers(f"clear-user-a-{uuid4().hex}")
    memory_id = f"clear-mem-{uuid4().hex}"
    trip_id = f"clear-trip-{uuid4().hex}"
    client.post(
        "/api/memory/capsules",
        headers=headers,
        json={
            "id": memory_id,
            "userId": "guest",
            "title": "不吃香菜",
            "content": "点单提醒。",
            "scope": "longTerm",
        },
    )
    exported = client.get("/api/memory/export", headers=headers)
    assert any(item["id"] == memory_id for item in exported.json()["items"])

    cleared = client.delete("/api/memory/capsules", headers=headers)
    assert cleared.status_code == 200
    assert cleared.json()["deleted"] >= 1

    client.post(
        "/api/trip/plan",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": trip_id,
            "destination": "重庆",
            "message": "周末想去重庆两天",
        },
    )
    current = client.get("/api/trip/current", headers=headers)
    assert current.json()["tripId"] == trip_id

    cleared_trip = client.delete("/api/trip/current", headers=headers)
    assert cleared_trip.status_code == 200
    assert cleared_trip.json()["deleted"] >= 1
    empty = client.get("/api/trip/current", headers=headers)
    assert empty.json()["status"] == "empty"


def test_clear_current_trip_deletes_only_latest_trip():
    user_id, headers = _guest_headers(f"clear-current-only-{uuid4().hex}")
    older_trip_id = f"older-trip-{uuid4().hex}"
    latest_trip_id = f"latest-trip-{uuid4().hex}"
    for trip_id, destination in [
        (older_trip_id, "广州"),
        (latest_trip_id, "深圳"),
    ]:
        response = client.post(
            "/api/trip/plan",
            headers=headers,
            json={
                "userId": "guest",
                "tripId": trip_id,
                "destination": destination,
                "message": f"规划{destination}行程",
            },
        )
        assert response.status_code == 200

    current = client.get("/api/trip/current", headers=headers)
    assert current.json()["tripId"] == latest_trip_id

    cleared_trip = client.delete("/api/trip/current", headers=headers)

    assert cleared_trip.status_code == 200
    assert cleared_trip.json()["deleted"] == 1
    remaining = client.get("/api/trip/current", headers=headers)
    assert remaining.json()["tripId"] == older_trip_id
