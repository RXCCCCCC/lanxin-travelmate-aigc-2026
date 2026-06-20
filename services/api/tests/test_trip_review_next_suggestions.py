from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_trip_review_next_suggestions_use_persisted_trip_context():
    user_id = "review-next-user-a"
    trip_id = "review-next-trip-a"

    memory = client.post(
        "/api/memory/capsules",
        json={
            "id": "review-next-memory-a",
            "userId": user_id,
            "title": "prefers river night walks",
            "content": "The traveler repeatedly chose riverside night walk stops.",
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
        json={
            "userId": user_id,
            "tripId": trip_id,
            "points": [
                {"label": "Riverside Gate", "latitude": 29.56, "longitude": 106.55},
                {"label": "Quiet Alley", "latitude": 29.57, "longitude": 106.56},
            ],
        },
    )
    assert route.status_code == 200

    photo = client.post(
        "/api/photo/candidates",
        json={
            "id": "review-next-photo-a",
            "userId": user_id,
            "tripId": trip_id,
            "remoteUrl": "https://cdn.example.test/river-night.jpg",
            "location": "Riverside Gate",
            "score": 9.1,
            "description": "A real reviewable trip photo candidate.",
            "tags": ["night", "river"],
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
            "location": "Quiet Alley",
            "eventPayload": {"energy": 24},
        },
    )
    assert reminder.status_code == 200

    review = client.post(
        "/api/trip/review",
        json={"userId": user_id, "tripId": trip_id, "message": "Create a real review"},
    )

    assert review.status_code == 200
    suggestions = review.json()["nextTripSuggestions"]
    suggestion_text = " ".join(suggestions)
    assert "Riverside Gate" in suggestion_text
    assert "prefers river night walks" in suggestion_text
    assert "Quiet Alley" in suggestion_text