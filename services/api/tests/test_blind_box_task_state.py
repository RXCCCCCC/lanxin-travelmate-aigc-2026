from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_blind_box_task_status_persists_and_completed_tasks_enter_review():
    user_id = "blind-user-a"
    trip_id = "blind-trip-a"

    accept = client.post(
        "/api/trip/blind-box/tasks/task-photo-night/status",
        json={"userId": user_id, "tripId": trip_id, "status": "accepted"},
    )
    assert accept.status_code == 200
    accepted = accept.json()
    assert accepted["taskId"] == "task-photo-night"
    assert accepted["status"] == "accepted"
    assert accepted["acceptedAt"] is not None
    assert accepted["completedAt"] is None

    complete = client.post(
        "/api/trip/blind-box/tasks/task-photo-night/status",
        json={"userId": user_id, "tripId": trip_id, "status": "completed", "note": "拍到了江边夜景"},
    )
    assert complete.status_code == 200
    completed = complete.json()
    assert completed["status"] == "completed"
    assert completed["completedAt"] is not None
    assert completed["rewardApplied"] is True
    assert completed["note"] == "拍到了江边夜景"

    tasks = client.get("/api/trip/blind-box/tasks", params={"userId": user_id, "tripId": trip_id})
    assert tasks.status_code == 200
    task = next(item for item in tasks.json()["items"] if item["id"] == "task-photo-night")
    assert task["status"] == "completed"
    assert task["rewardApplied"] is True

    review = client.post(
        "/api/trip/review",
        json={"userId": user_id, "tripId": trip_id, "message": "生成今天旅行复盘"},
    )
    assert review.status_code == 200
    review_payload = review.json()
    assert any(item["id"] == "task-photo-night" for item in review_payload["completedTasks"])


def test_blind_box_task_can_be_skipped_without_review_reward():
    response = client.post(
        "/api/trip/blind-box/tasks/task-food-no-cilantro/status",
        json={"userId": "blind-user-b", "tripId": "blind-trip-b", "status": "skipped", "note": "今天不吃正餐"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "skipped"
    assert payload["rewardApplied"] is False
    assert payload["note"] == "今天不吃正餐"