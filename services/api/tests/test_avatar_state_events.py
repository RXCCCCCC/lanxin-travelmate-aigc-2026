from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_avatar_state_events_are_persisted_readable_and_used_by_review():
    user_id = "avatar-user-a"
    trip_id = "avatar-trip-a"

    created = client.post(
        "/api/trip/avatar-state/events",
        json={
            "userId": user_id,
            "tripId": trip_id,
            "eventType": "memory_confirmed",
            "title": "确认了不吃香菜记忆",
            "deltas": {"rapport": 2, "affection": 1},
            "reason": "用户确认长期记忆，默契提升",
        },
    )

    assert created.status_code == 200
    payload = created.json()
    assert payload["eventId"].startswith("avatar-event-")
    assert payload["deltas"]["rapport"] == 2

    history = client.get("/api/trip/avatar-state/events", params={"userId": user_id, "tripId": trip_id})

    assert history.status_code == 200
    items = history.json()["items"]
    assert items[0]["title"] == "确认了不吃香菜记忆"

    review = client.post(
        "/api/trip/review",
        json={"userId": user_id, "tripId": trip_id, "message": "生成状态复盘"},
    )

    assert review.status_code == 200
    assert any("确认了不吃香菜记忆" in item for item in review.json()["avatarStatusChanges"])


def test_completed_blind_box_task_creates_avatar_state_event():
    user_id = "avatar-user-b"
    trip_id = "avatar-trip-b"

    task = client.post(
        "/api/trip/blind-box/tasks/task-photo-night/status",
        json={"userId": user_id, "tripId": trip_id, "status": "completed", "note": "完成夜景任务"},
    )

    assert task.status_code == 200
    history = client.get("/api/trip/avatar-state/events", params={"userId": user_id, "tripId": trip_id})
    assert history.status_code == 200
    items = history.json()["items"]
    assert any(item["eventType"] == "blind_box_completed" for item in items)
    assert any("好感度" in item["title"] for item in items)