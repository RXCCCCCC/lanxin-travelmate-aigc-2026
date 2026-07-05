from fastapi.testclient import TestClient
from uuid import uuid4

from app.main import app


client = TestClient(app)


def _guest_headers(device_id: str) -> tuple[str, dict[str, str]]:
    response = client.post("/api/auth/guest", json={"deviceId": device_id, "displayName": "Review Memory Test Guest"})
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_trip_review_uses_persisted_memories_for_new_memories_and_promotions():
    user_id, headers = _guest_headers(f"review-memory-user-{uuid4().hex}")
    trip_id = "review-memory-trip-a"

    current_trip_memory = client.post(
        "/api/memory/capsules",
        headers=headers,
        json={
            "id": "review-memory-current-a",
            "userId": user_id,
            "title": "本次喜欢江边夜景",
            "content": "用户在本次旅程中多次选择江边夜景点位。",
            "scope": "currentTrip",
            "category": "travel_preference",
            "status": "confirmed",
            "sourceText": trip_id,
            "confidence": 0.91,
        },
    )
    assert current_trip_memory.status_code == 200

    temporary_memory = client.post(
        "/api/memory/capsules",
        headers=headers,
        json={
            "id": "review-memory-temp-a",
            "userId": user_id,
            "title": "今天不想走太远",
            "content": "用户今天体力较低，偏好短距离路线。",
            "scope": "temporary",
            "category": "pace",
            "status": "confirmed",
            "sourceText": trip_id,
            "confidence": 0.84,
        },
    )
    assert temporary_memory.status_code == 200

    review = client.post(
        "/api/trip/review",
        headers=headers,
        json={"userId": user_id, "tripId": trip_id, "message": "生成记忆沉淀复盘"},
    )

    assert review.status_code == 200
    payload = review.json()
    assert "本次喜欢江边夜景" in payload["newMemories"]
    promotions = payload["temporaryMemoryPromotions"]
    assert any(item["id"] == "review-memory-temp-a" for item in promotions)
    assert any(item["suggestedScope"] == "longTerm" for item in promotions)
