from fastapi.testclient import TestClient
from uuid import uuid4

from app.main import app


client = TestClient(app)


def _guest_headers(device_id: str) -> tuple[str, dict[str, str]]:
    response = client.post("/api/auth/guest", json={"deviceId": device_id, "displayName": "Review Next Guest"})
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_trip_review_next_suggestions_use_persisted_trip_context():
    user_id, headers = _guest_headers(f"review-next-{uuid4().hex}")
    trip_id = "review-next-trip-a"
    memory_id = f"review-next-memory-{uuid4().hex}"
    photo_id = f"review-next-photo-{uuid4().hex}"

    memory = client.post(
        "/api/memory/capsules",
        headers=headers,
        json={
            "id": memory_id,
            "userId": user_id,
            "title": "偏好江边夜间散步",
            "content": "用户多次选择江边夜景与低强度散步路线。",
            "scope": "longTerm",
            "category": "travel_preference",
            "status": "confirmed",
            "sourceText": trip_id,
            "confidence": 0.93,
        },
    )
    assert memory.status_code == 200

    route = client.post(
        "/api/trip/route-points",
        headers=headers,
        json={
            "userId": user_id,
            "tripId": trip_id,
            "points": [
                {"label": "江边入口", "latitude": 29.56, "longitude": 106.55},
                {"label": "安静小巷", "latitude": 29.57, "longitude": 106.56},
            ],
        },
    )
    assert route.status_code == 200

    photo = client.post(
        "/api/photo/candidates",
        headers=headers,
        json={
            "id": photo_id,
            "userId": user_id,
            "tripId": trip_id,
            "remoteUrl": "https://cdn.example.test/river-night.jpg",
            "location": "江边入口",
            "score": 9.1,
            "description": "A real reviewable trip photo candidate.",
            "tags": ["night", "river"],
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
            "location": "安静小巷",
            "eventPayload": {"energy": 24},
        },
    )
    assert reminder.status_code == 200

    review = client.post(
        "/api/trip/review",
        headers=headers,
        json={"userId": user_id, "tripId": trip_id, "message": "生成真实复盘"},
    )

    assert review.status_code == 200
    suggestions = review.json()["nextTripSuggestions"]
    suggestion_text = " ".join(suggestions)
    assert "江边入口" in suggestion_text
    assert "偏好江边夜间散步" in suggestion_text
    assert "安静小巷" in suggestion_text
    assert not any("a" <= char.lower() <= "z" for char in suggestion_text)
