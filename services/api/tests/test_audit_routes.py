from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_audit_tool_call_logs_are_readable_and_filterable():
    first = client.post(
        "/api/tools/weather_tool/call",
        json={"userId": "audit-user-a", "payload": {"city": "Hangzhou"}},
    )
    second = client.post(
        "/api/audio/asr",
        json={"userId": "audit-user-a", "audioRef": "audio-a", "mockText": "hello"},
    )
    assert first.status_code == 200
    assert second.status_code == 200

    response = client.get(
        "/api/audit/tool-calls",
        params={"toolName": "weather_tool", "fallback": True, "limit": 5},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["total"] >= 1
    assert payload["items"]
    assert all(item["toolName"] == "weather_tool" for item in payload["items"])
    assert all(item["fallback"] is True for item in payload["items"])
    assert payload["items"][0]["toolTraceId"].startswith("tool-")


def test_audit_model_call_logs_hide_request_summary_details():
    chat = client.post(
        "/api/agent/chat",
        json={
            "message": "周末想规划一条路线 secret travel prompt that should not appear in audit output",
            "sessionId": "audit-session-a",
            "userId": "audit-user-b",
            "tripId": "audit-trip-b",
        },
    )
    assert chat.status_code == 200

    response = client.get(
        "/api/audit/model-calls",
        params={"scenario": "trip_planning", "limit": 5},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["items"]
    assert any(item["scenario"] == "trip_planning" for item in payload["items"])
    response_text = response.text
    assert "secret travel prompt" not in response_text