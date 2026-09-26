from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def _guest_headers(device_id: str) -> tuple[str, dict[str, str]]:
    response = client.post("/api/auth/guest", json={"deviceId": device_id, "displayName": "Scoped Guest"})
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_trip_core_routes_scope_guest_payload_to_authenticated_user():
    user_id, headers = _guest_headers(f"scope-trip-{uuid4().hex}")
    trip_id = f"trip-scope-{uuid4().hex}"

    plan = client.post(
        "/api/trip/plan",
        headers=headers,
        json={"userId": "guest", "tripId": trip_id, "destination": "Suzhou", "message": "Plan a slow trip."},
    )
    assert plan.status_code == 200

    current = client.get("/api/trip/current", headers=headers)
    assert current.status_code == 200
    assert current.json()["userId"] == user_id
    assert current.json()["tripId"] == trip_id

    route = client.post(
        "/api/trip/route-points",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": trip_id,
            "points": [{"label": "Hotel", "latitude": 31.3, "longitude": 120.6}],
        },
    )
    assert route.status_code == 200

    reminder = client.post(
        "/api/trip/reminders/trigger",
        headers=headers,
        json={"userId": "guest", "tripId": trip_id, "triggerType": "location", "location": "Hotel"},
    )
    assert reminder.status_code == 200

    avatar = client.post(
        "/api/trip/avatar-state/events",
        headers=headers,
        json={"userId": "guest", "tripId": trip_id, "eventType": "memory_confirmed", "title": "Scoped event"},
    )
    assert avatar.status_code == 200
    assert avatar.json()["userId"] == user_id

    blind_box = client.post(
        "/api/trip/blind-box/tasks/task-photo-night/status",
        headers=headers,
        json={"userId": "guest", "tripId": trip_id, "status": "completed"},
    )
    assert blind_box.status_code == 200
    assert blind_box.json()["userId"] == user_id

    dashboard = client.get("/api/trip/dashboard", headers=headers, params={"tripId": trip_id})
    assert dashboard.status_code == 200
    payload = dashboard.json()
    assert payload["userId"] == user_id
    assert payload["currentTrip"]["tripId"] == trip_id
    assert payload["routePoints"]["points"][0]["label"] == "Hotel"
    assert payload["reminderHistory"]["items"]
    assert any(item["eventType"] == "memory_confirmed" for item in payload["avatarStateEvents"]["items"])
    assert any(item["id"] == "task-photo-night" and item["status"] == "completed" for item in payload["blindBoxTasks"]["items"])

    history = client.get("/api/trip/reminders/history", headers=headers, params={"tripId": trip_id})
    assert history.status_code == 200
    assert history.json()["items"]

    review = client.post("/api/trip/review", headers=headers, json={"userId": "guest", "tripId": trip_id})
    assert review.status_code == 200
    assert review.json()["tripId"] == trip_id

    read_review = client.get("/api/trip/review", headers=headers, params={"tripId": trip_id})
    assert read_review.status_code == 200
    assert read_review.json()["reviewId"] == review.json()["reviewId"]

    global_read_review = client.get("/api/trip/review", params={"tripId": trip_id})
    assert global_read_review.status_code == 200
    assert global_read_review.json()["reviewId"] is None

    global_guest = client.get("/api/trip/current")
    assert global_guest.status_code == 200
    assert global_guest.json()["tripId"] != trip_id
