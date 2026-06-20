from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_memory_capsules_are_persisted_per_user():
    response = client.post(
        "/api/memory/capsules",
        json={
            "id": "mem-db-user-a",
            "userId": "user-a",
            "title": "喜欢夜景",
            "content": "规划时保留夜景点。",
            "scope": "longTerm",
        },
    )
    assert response.status_code == 200

    user_a = client.get("/api/memory/capsules", params={"userId": "user-a"})
    user_b = client.get("/api/memory/capsules", params={"userId": "user-b"})

    assert any(item["id"] == "mem-db-user-a" for item in user_a.json()["items"])
    assert all(item["id"] != "mem-db-user-a" for item in user_b.json()["items"])


def test_profile_is_persisted_per_user():
    update = client.put(
        "/api/profile/me",
        params={"userId": "profile-user-a"},
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

    read_back = client.get("/api/profile/me", params={"userId": "profile-user-a"})

    assert read_back.status_code == 200
    payload = read_back.json()
    assert payload["travelPace"] == "慢节奏"
    assert payload["transportPreferences"] == ["少换乘"]
    assert payload["expressionStyle"] == "轻松口语"


def test_trip_plan_is_saved_as_current_trip():
    plan = client.post(
        "/api/trip/plan",
        json={
            "userId": "trip-user-a",
            "tripId": "trip-db-a",
            "destination": "重庆",
            "message": "周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜",
        },
    )
    assert plan.status_code == 200

    current = client.get("/api/trip/current", params={"userId": "trip-user-a"})

    assert current.status_code == 200
    payload = current.json()
    assert payload["tripId"] == "trip-db-a"
    assert payload["destination"] == "重庆"
    assert payload["status"] == "planning"
    assert payload["plan"]["title"] == plan.json()["title"]