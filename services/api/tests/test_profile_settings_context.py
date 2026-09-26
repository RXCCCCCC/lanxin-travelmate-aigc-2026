import json
from uuid import uuid4

from fastapi.testclient import TestClient
from sqlmodel import Session, select

from app.db.models import ModelCallLog
from app.db.session import engine
from app.main import app


client = TestClient(app)


def test_profile_settings_are_persisted_and_loaded_into_agent_context():
    auth = client.post(
        "/api/auth/guest",
        json={"deviceId": f"profile-context-{uuid4().hex}", "displayName": "Profile Context Guest"},
    )
    assert auth.status_code == 200
    user_id = auth.json()["userId"]
    headers = {"Authorization": f"Bearer {auth.json()['accessToken']}"}

    update = client.put(
        "/api/profile/me",
        headers=headers,
        params={"userId": user_id},
        json={
            "travelPace": "slow",
            "personality": "gentle_companion",
            "proactivityLevel": "quiet",
            "syncStrategy": "selectedOnly",
            "notificationEnabled": False,
            "voiceEnabled": True,
            "textModePreferred": True,
            "customPrompt": "Keep suggestions concise and calm.",
        },
    )
    assert update.status_code == 200

    profile = client.get("/api/profile/me", headers=headers)
    assert profile.status_code == 200
    profile_payload = profile.json()
    assert profile_payload["personality"] == "gentle_companion"
    assert profile_payload["proactivityLevel"] == "quiet"
    assert profile_payload["syncStrategy"] == "selectedOnly"
    assert profile_payload["notificationEnabled"] is False
    assert profile_payload["voiceEnabled"] is True
    assert profile_payload["textModePreferred"] is True

    chat = client.post(
        "/api/agent/chat",
        headers=headers,
        json={
            "sessionId": "settings-context-session",
            "message": "Plan a quiet afternoon nearby.",
        },
    )
    assert chat.status_code == 200

    with Session(engine) as session:
        records = session.exec(
            select(ModelCallLog).where(
                ModelCallLog.scenario == "trip_planning",
            )
        ).all()

    latest = next(record for record in records if user_id in record.request_summary_json)
    summary = json.loads(latest.request_summary_json)
    assert summary["userSettings"]["personality"] == "gentle_companion"
    assert summary["userSettings"]["proactivityLevel"] == "quiet"
    assert summary["userSettings"]["syncStrategy"] == "selectedOnly"
