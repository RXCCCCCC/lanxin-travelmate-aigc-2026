import json

from fastapi.testclient import TestClient
from uuid import uuid4

from app.main import app


client = TestClient(app)


def _guest_headers(device_id: str) -> tuple[str, dict[str, str]]:
    response = client.post("/api/auth/guest", json={"deviceId": device_id, "displayName": "Review Aggregate Test Guest"})
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_trip_review_aggregates_persisted_photos_reminders_and_tasks():
    user_id, headers = _guest_headers(f"review-aggregate-user-a-{uuid4().hex}")
    trip_id = "review-aggregate-trip-a"

    photo = client.post(
        "/api/photo/candidates",
        headers=headers,
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
        headers=headers,
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
        headers=headers,
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
        headers=headers,
        json={"userId": user_id, "tripId": trip_id, "message": "生成真实复盘"},
    )

    assert review.status_code == 200
    payload = review.json()
    assert "真实夜景观景台" in payload["highlightPhotos"]
    assert any(item["id"] == "task-photo-night" for item in payload["completedTasks"])
    assert any(item["triggerType"] == "status" for item in payload["reminderHighlights"])
    assert any("盲盒" in item or "提醒" in item for item in payload["avatarStatusChanges"])


def test_trip_review_falls_back_to_persisted_context_when_model_returns_empty(monkeypatch):
    from app.api.routes import trip

    class EmptyReviewGraph:
        def invoke_review_only(self, state):
            return {
                **state,
                "review": {
                    "route": "",
                    "highlightPhotos": [],
                    "newMemories": [],
                    "completedTasks": [],
                    "reminderHighlights": [],
                    "avatarStatusChanges": ["完成盲盒任务: 默契值 +1（affection +2、rapport +1）"],
                    "nextTripSuggestions": [
                        "Reserve another highlight photo stop around 无法仅凭画面确认 based on this trip's saved photos."
                    ],
                    "temporaryMemoryPromotions": [],
                    "profileContext": {},
                },
                "model_call_logs": [],
            }

    monkeypatch.setattr(trip, "TravelMateGraph", EmptyReviewGraph)
    user_id, headers = _guest_headers(f"review-empty-model-user-{uuid4().hex}")
    trip_id = "review-empty-model-trip"

    photo = client.post(
        "/api/photo/candidates",
        headers=headers,
        json={
            "id": f"review-empty-model-photo-{uuid4().hex}",
            "userId": user_id,
            "tripId": trip_id,
            "remoteUrl": "https://cdn.example.test/real-photo.jpg",
            "location": "广州塔江边夜景",
            "score": 8.8,
            "description": "真实上传照片，适合进入复盘精彩瞬间。",
            "tags": ["城市夜景", "江边散步"],
            "canAddToReview": True,
        },
    )
    assert photo.status_code == 200

    memory = client.post(
        "/api/memory/capsules",
        headers=headers,
        json={
            "id": f"review-empty-model-memory-{uuid4().hex}",
            "userId": user_id,
            "title": "喜欢广州江边轻松散步",
            "content": "用户本次行程偏好低强度、江边夜景和轻松节奏。",
            "scope": "currentTrip",
            "category": "travel_preference",
            "status": "confirmed",
            "sourceText": trip_id,
            "confidence": 0.92,
        },
    )
    assert memory.status_code == 200

    review = client.post(
        "/api/trip/review",
        headers=headers,
        json={"userId": user_id, "tripId": trip_id, "message": "生成真实复盘"},
    )

    assert review.status_code == 200
    payload = review.json()
    assert "广州塔江边夜景" in payload["highlightPhotos"]
    assert "喜欢广州江边轻松散步" in payload["newMemories"]
    review_text = json.dumps(payload, ensure_ascii=False)
    assert "affection" not in review_text
    assert "rapport" not in review_text
    assert "Reserve another" not in review_text
    assert "based on this trip" not in review_text
    assert "好感度 +2" in review_text
    assert "默契值 +1" in review_text
    assert "高光拍照点" in review_text


def test_trip_review_replaces_unknown_photo_location_with_numbered_label():
    user_id, headers = _guest_headers(f"review-placeholder-photo-user-{uuid4().hex}")
    trip_id = "review-placeholder-photo-trip"

    photo = client.post(
        "/api/photo/candidates",
        headers=headers,
        json={
            "id": f"review-placeholder-photo-{uuid4().hex}",
            "userId": user_id,
            "tripId": trip_id,
            "remoteUrl": "https://cdn.example.test/unknown-photo.jpg",
            "location": "无法仅凭画面确认",
            "score": 8.2,
            "description": "真实上传照片，地点无法确认。",
            "tags": ["城市街景", "旅行记录"],
            "canAddToReview": True,
        },
    )
    assert photo.status_code == 200

    review = client.post(
        "/api/trip/review",
        headers=headers,
        json={"userId": user_id, "tripId": trip_id, "message": "生成真实复盘"},
    )

    assert review.status_code == 200
    payload = review.json()
    review_text = json.dumps(payload, ensure_ascii=False)
    assert "无法仅凭画面确认" not in review_text
    assert "图片1" in payload["highlightPhotos"]
    assert all("无法仅凭画面确认" not in item for item in payload["nextTripSuggestions"])
