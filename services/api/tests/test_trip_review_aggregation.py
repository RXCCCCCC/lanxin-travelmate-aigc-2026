from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_trip_review_aggregates_persisted_photos_reminders_and_tasks():
    user_id = "review-aggregate-user-a"
    trip_id = "review-aggregate-trip-a"

    photo = client.post(
        "/api/photo/candidates",
        json={
            "id": "review-aggregate-photo-a",
            "userId": user_id,
            "tripId": trip_id,
            "remoteUrl": "https://cdn.example.test/review-photo.jpg",
            "location": "真实夜景观景台",
            "score": 9.5,
            "description": "适合进入复盘的真实候选照片",
            "tags": ["夜景", "高光照片"],
            "canAddToReview": True,
        },
    )
    assert photo.status_code == 200

    reminder = client.post(
        "/api/trip/reminders/trigger",
        json={
            "userId": user_id,
            "tripId": trip_id,
            "triggerType": "status",
            "location": "真实夜景观景台",
            "eventPayload": {"energy": 26},
        },
    )
    assert reminder.status_code == 200

    task = client.post(
        "/api/trip/blind-box/tasks/task-photo-night/status",
        json={
            "userId": user_id,
            "tripId": trip_id,
            "status": "completed",
            "note": "完成了夜景盲盒",
        },
    )
    assert task.status_code == 200

    review = client.post(
        "/api/trip/review",
        json={"userId": user_id, "tripId": trip_id, "message": "生成真实复盘"},
    )

    assert review.status_code == 200
    payload = review.json()
    assert "真实夜景观景台" in payload["highlightPhotos"]
    assert any(item["id"] == "task-photo-night" for item in payload["completedTasks"])
    assert any(item["triggerType"] == "status" for item in payload["reminderHighlights"])
    assert any("盲盒" in item or "提醒" in item for item in payload["avatarStatusChanges"])