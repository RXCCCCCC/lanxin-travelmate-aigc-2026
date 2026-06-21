from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def _guest_headers(device_id: str) -> tuple[str, dict[str, str]]:
    response = client.post("/api/auth/guest", json={"deviceId": device_id, "displayName": "Scoped Guest"})
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_profile_me_defaults_to_authenticated_user_instead_of_global_guest():
    user_id, headers = _guest_headers(f"scope-profile-{uuid4().hex}")

    update = client.put(
        "/api/profile/me",
        headers=headers,
        json={
            "travelPace": "slow",
            "dietaryPreferences": ["no cilantro"],
            "interestTags": ["night view"],
            "transportPreferences": ["walking"],
            "personality": "concise_companion",
            "proactivityLevel": "quiet",
        },
    )

    assert update.status_code == 200
    assert update.json()["userId"] == user_id

    authenticated = client.get("/api/profile/me", headers=headers)
    assert authenticated.status_code == 200
    assert authenticated.json()["userId"] == user_id
    assert authenticated.json()["dietaryPreferences"] == ["no cilantro"]

    anonymous_guest = client.get("/api/profile/me")
    assert anonymous_guest.status_code == 200
    assert anonymous_guest.json()["userId"] == "guest"
    assert anonymous_guest.json()["dietaryPreferences"] != ["no cilantro"]


def test_memory_guest_payload_is_scoped_to_authenticated_user():
    user_id, headers = _guest_headers(f"scope-memory-{uuid4().hex}")
    memory_id = f"mem-scope-{uuid4().hex}"

    created = client.post(
        "/api/memory/capsules",
        headers=headers,
        json={
            "id": memory_id,
            "userId": "guest",
            "title": "Night views",
            "content": "Prefer night-view stops.",
            "scope": "longTerm",
        },
    )

    assert created.status_code == 200
    assert created.json()["userId"] == user_id

    authenticated = client.get("/api/memory/capsules", headers=headers)
    assert authenticated.status_code == 200
    assert any(item["id"] == memory_id for item in authenticated.json()["items"])

    global_guest = client.get("/api/memory/capsules")
    assert global_guest.status_code == 200
    assert all(item["id"] != memory_id for item in global_guest.json()["items"])


def test_agent_chat_loads_authenticated_profile_when_user_id_is_omitted():
    user_id, headers = _guest_headers(f"scope-agent-{uuid4().hex}")
    update = client.put(
        "/api/profile/me",
        headers=headers,
        json={
            "travelPace": "slow",
            "personality": "gentle_companion",
            "proactivityLevel": "quiet",
            "syncStrategy": "selectedOnly",
            "notificationEnabled": False,
            "voiceEnabled": True,
            "textModePreferred": True,
            "customPrompt": "Keep authenticated suggestions calm.",
        },
    )
    assert update.status_code == 200
    assert update.json()["userId"] == user_id

    chat = client.post(
        "/api/agent/chat",
        headers=headers,
        json={"sessionId": "auth-scope-session", "message": "Plan a quiet afternoon nearby."},
    )

    assert chat.status_code == 200
    audit = client.get("/api/audit/model-calls", params={"provider": "mock", "limit": 5})
    assert audit.status_code == 200
    latest = audit.json()["items"][0]
    assert latest["requestSummary"]["userSettings"]["customPrompt"] == "Keep authenticated suggestions calm."

