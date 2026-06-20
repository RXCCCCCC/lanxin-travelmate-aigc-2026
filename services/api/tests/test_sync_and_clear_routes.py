from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_sync_push_pull_and_selected_memory():
    user_id = "sync-user-a"
    push = client.post(
        "/api/sync/push",
        json={
            "userId": user_id,
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

    pull = client.get("/api/sync/pull", params={"userId": user_id})
    assert pull.status_code == 200
    payload = pull.json()
    assert payload["profile"]["travelPace"] == "慢节奏"
    assert payload["memories"][0]["id"] == "sync-mem-a"
    assert payload["trips"][0]["id"] == "sync-trip-a"

    selected = client.post(
        "/api/sync/selected-memory",
        json={"userId": user_id, "memoryIds": ["sync-mem-a"]},
    )
    assert selected.status_code == 200
    assert selected.json()["selected"][0]["id"] == "sync-mem-a"


def test_clear_memory_and_current_trip_endpoints():
    user_id = "clear-user-a"
    client.post(
        "/api/memory/capsules",
        json={
            "id": "clear-mem-a",
            "userId": user_id,
            "title": "不吃香菜",
            "content": "点单提醒。",
            "scope": "longTerm",
        },
    )
    exported = client.get("/api/memory/export", params={"userId": user_id})
    assert any(item["id"] == "clear-mem-a" for item in exported.json()["items"])

    cleared = client.delete("/api/memory/capsules", params={"userId": user_id})
    assert cleared.status_code == 200
    assert cleared.json()["deleted"] >= 1

    client.post(
        "/api/trip/plan",
        json={
            "userId": user_id,
            "tripId": "clear-trip-a",
            "destination": "重庆",
            "message": "周末想去重庆两天",
        },
    )
    current = client.get("/api/trip/current", params={"userId": user_id})
    assert current.json()["tripId"] == "clear-trip-a"

    cleared_trip = client.delete("/api/trip/current", params={"userId": user_id})
    assert cleared_trip.status_code == 200
    assert cleared_trip.json()["deleted"] >= 1
    empty = client.get("/api/trip/current", params={"userId": user_id})
    assert empty.json()["status"] == "empty"