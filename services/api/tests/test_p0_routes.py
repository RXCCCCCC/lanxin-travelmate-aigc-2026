from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_memory_capsule_crud_endpoints():
    create_response = client.post(
        "/api/memory/capsules",
        json={
            "id": "mem-test",
            "title": "不吃香菜",
            "content": "后续推荐避开香菜。",
            "scope": "longTerm",
        },
    )
    assert create_response.status_code == 200
    assert create_response.json()["title"] == "不吃香菜"

    list_response = client.get("/api/memory/capsules")
    assert list_response.status_code == 200
    assert any(item["id"] == "mem-test" for item in list_response.json()["items"])

    update_response = client.put(
        "/api/memory/capsules/mem-test",
        json={"title": "不要香菜", "content": "点单提醒不要香菜。"},
    )
    assert update_response.status_code == 200
    assert update_response.json()["title"] == "不要香菜"

    delete_response = client.delete("/api/memory/capsules/mem-test")
    assert delete_response.status_code == 200
    assert delete_response.json()["deleted"] is True


def test_profile_read_write_endpoint():
    response = client.put(
        "/api/profile/me",
        json={
            "travelPace": "轻松",
            "dietaryPreferences": ["不吃香菜"],
            "interestTags": ["夜景"],
        },
    )

    assert response.status_code == 200
    assert response.json()["travelPace"] == "轻松"
    assert "夜景" in response.json()["interestTags"]


def test_trip_plan_reminder_and_avatar_endpoints():
    plan_response = client.post(
        "/api/trip/plan",
        json={"message": "周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜"},
    )
    assert plan_response.status_code == 200
    assert plan_response.json()["title"] == "重庆两日轻松夜景线"

    reminder_response = client.post(
        "/api/trip/reminders/trigger",
        json={"triggerType": "time", "location": "洪崖洞"},
    )
    assert reminder_response.status_code == 200
    assert len(reminder_response.json()["items"]) >= 2

    avatar_response = client.get("/api/agent/avatar-state")
    assert avatar_response.status_code == 200
    assert set(avatar_response.json()) == {"energy", "mood", "curiosity", "rapport", "affection"}
