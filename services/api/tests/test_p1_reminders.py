from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_reminder_trigger_supports_behavior_status_and_external_events():
    behavior_response = client.post(
        "/api/trip/reminders/trigger",
        json={"triggerType": "behavior", "eventPayload": {"event": "newPhoto"}},
    )
    status_response = client.post(
        "/api/trip/reminders/trigger",
        json={"triggerType": "status", "eventPayload": {"energy": 32}},
    )
    external_response = client.post(
        "/api/trip/reminders/trigger",
        json={"triggerType": "external", "eventPayload": {"event": "weatherChanged"}},
    )

    assert behavior_response.status_code == 200
    assert status_response.status_code == 200
    assert external_response.status_code == 200
    assert any(item["triggerType"] == "behavior" for item in behavior_response.json()["items"])
    assert any(item["triggerType"] == "status" for item in status_response.json()["items"])
    assert any(item["triggerType"] == "external" for item in external_response.json()["items"])
