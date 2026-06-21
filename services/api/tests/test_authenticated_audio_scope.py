from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def _guest_headers(device_id: str) -> tuple[str, dict[str, str]]:
    response = client.post("/api/auth/guest", json={"deviceId": device_id, "displayName": "Audio Guest"})
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def _audit_item_by_trace_id(trace_id: str) -> dict[str, object]:
    response = client.get("/api/audit/tool-calls", params={"limit": 50})
    assert response.status_code == 200
    for item in response.json()["items"]:
        if item["toolTraceId"] == trace_id:
            return item
    raise AssertionError(f"tool trace {trace_id} was not found in audit logs")


def test_audio_routes_audit_guest_payload_as_authenticated_user():
    user_id, headers = _guest_headers(f"scope-audio-{uuid4().hex}")

    asr = client.post(
        "/api/audio/asr",
        headers=headers,
        json={"userId": "guest", "audioRef": "audio-auth-scope", "mockText": "hello"},
    )
    tts = client.post(
        "/api/audio/tts",
        headers=headers,
        json={"userId": "guest", "text": "hello", "voice": "lanxiaoxin"},
    )

    assert asr.status_code == 200
    assert tts.status_code == 200
    assert asr.json()["userId"] == user_id
    assert tts.json()["userId"] == user_id

    asr_audit = _audit_item_by_trace_id(asr.json()["toolTraceId"])
    tts_audit = _audit_item_by_trace_id(tts.json()["toolTraceId"])
    assert asr_audit["toolName"] == "asr_tool"
    assert tts_audit["toolName"] == "tts_tool"
    assert asr_audit["userId"] == user_id
    assert tts_audit["userId"] == user_id
