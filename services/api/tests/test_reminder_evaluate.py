from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def _guest_headers(label: str) -> dict[str, str]:
    response = client.post(
        "/api/auth/guest",
        json={"deviceId": f"reminder-{label}-{uuid4().hex}", "displayName": "Reminder Guest"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['accessToken']}"}


def test_reminder_evaluate_triggers_from_context_and_respects_cooldown():
    headers = _guest_headers("evaluate")
    trip_id = f"trip-{uuid4().hex}"
    payload = {
        "userId": "guest",
        "tripId": trip_id,
        "proactivityLevel": "standard",
        "currentTime": "2026-06-20T18:20:00+08:00",
        "location": "Hongyadong",
        "status": {"energy": 31},
        "external": {"weatherWarning": "rain", "queueLevel": "high"},
    }

    first = client.post("/api/trip/reminders/evaluate", headers=headers, json=payload)
    second = client.post("/api/trip/reminders/evaluate", headers=headers, json=payload)

    assert first.status_code == 200
    first_payload = first.json()
    assert first_payload["triggered"] is True
    assert first_payload["historyId"].startswith("reminder-")
    assert {item["triggerType"] for item in first_payload["items"]} >= {"time", "location", "status", "external"}

    assert second.status_code == 200
    second_payload = second.json()
    assert second_payload["triggered"] is False
    assert second_payload["historyId"] is None
    assert second_payload["suppressedReason"] == "cooldown"
    assert second_payload["cooldownRemainingSeconds"] > 0

    history = client.get(
        "/api/trip/reminders/history",
        headers=headers,
        params={"tripId": trip_id},
    )
    assert history.status_code == 200
    assert len(history.json()["items"]) == 1


def test_reminder_evaluate_honors_quiet_proactivity():
    headers = _guest_headers("quiet")
    response = client.post(
        "/api/trip/reminders/evaluate",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": f"trip-{uuid4().hex}",
            "proactivityLevel": "quiet",
            "currentTime": "2026-06-20T18:20:00+08:00",
            "location": "Hongyadong",
            "status": {"energy": 28},
            "external": {"queueLevel": "high"},
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["triggered"] is True
    assert {item["triggerType"] for item in payload["items"]} == {"status"}
