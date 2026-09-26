from fastapi.testclient import TestClient
from uuid import uuid4

from app.api.routes import photo
from app.main import app


client = TestClient(app)


def _guest_headers(label: str) -> tuple[str, dict[str, str]]:
    response = client.post(
        "/api/auth/guest",
        json={"deviceId": f"audit-{label}-{uuid4().hex}", "displayName": "Audit Guest"},
    )
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_audit_tool_call_logs_are_readable_and_filterable():
    user_id, headers = _guest_headers("tools")
    first = client.post(
        "/api/tools/weather_tool/call",
        headers=headers,
        json={"userId": "guest", "payload": {"city": "Hangzhou"}},
    )
    second = client.post(
        "/api/audio/asr",
        headers=headers,
        json={"userId": "guest", "audioRef": "audio-a", "mockText": "hello"},
    )
    assert first.status_code == 200
    assert second.status_code == 200

    response = client.get(
        "/api/audit/tool-calls",
        headers=headers,
        params={"toolName": "asr_tool", "fallback": True, "limit": 5},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["total"] >= 1
    assert payload["items"]
    assert all(item["toolName"] == "asr_tool" for item in payload["items"])
    assert all(item["fallback"] is True for item in payload["items"])
    assert all(item["userId"] == user_id for item in payload["items"])
    assert payload["items"][0]["toolTraceId"].startswith("tool-")


def test_audit_model_call_logs_hide_request_summary_details():
    user_id, headers = _guest_headers("chat")
    chat = client.post(
        "/api/agent/chat",
        headers=headers,
        json={
            "message": "周末想规划一条路线 secret travel prompt that should not appear in audit output",
            "sessionId": "audit-session-a",
            "userId": "guest",
            "tripId": "audit-trip-b",
        },
    )
    assert chat.status_code == 200

    response = client.get(
        "/api/audit/model-calls",
        headers=headers,
        params={"scenario": "trip_planning", "limit": 5},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["items"]
    assert any(item["scenario"] == "trip_planning" for item in payload["items"])
    assert all(item["requestSummary"].get("userId") == user_id for item in payload["items"])
    response_text = response.text
    assert "secret travel prompt" not in response_text


def test_audit_model_call_logs_include_direct_trip_plan_route():
    user_id, headers = _guest_headers("trip")
    response = client.post(
        "/api/trip/plan",
        headers=headers,
        json={
            "message": "请规划杭州两天轻松路线 direct trip plan secret text",
            "userId": "guest",
            "tripId": "audit-direct-plan-trip",
            "destination": "杭州",
            "preferences": ["夜景", "不太累"],
        },
    )
    assert response.status_code == 200

    audit = client.get(
        "/api/audit/model-calls",
        headers=headers,
        params={"scenario": "trip_planning", "limit": 20},
    )

    assert audit.status_code == 200
    items = audit.json()["items"]
    assert any(item["requestSummary"].get("tripId") == "audit-direct-plan-trip" for item in items)
    assert all(item["requestSummary"].get("userId") == user_id for item in items)
    assert "direct trip plan secret text" not in audit.text


def test_audit_model_call_logs_include_direct_photo_copywriting_route(monkeypatch):
    user_id, headers = _guest_headers("photo")
    class AuditCopywritingProvider:
        name = "audit-copywriting-provider"

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            return {
                "photoCopywriting": {
                    "photoIds": ["audit-photo-a"],
                    "persona": "quiet guide",
                    "style": "warm",
                    "moments": "Audit moments copy",
                    "xiaohongshu": "Audit XHS copy",
                    "diary": "Audit diary copy",
                    "vlogNarration": "Audit vlog copy",
                    "reviewSuggestion": "Audit review suggestion",
                }
            }

    monkeypatch.setattr(photo, "build_model_provider", lambda settings: AuditCopywritingProvider())
    create = client.post(
        "/api/photo/candidates",
        headers=headers,
        json={
            "id": "audit-photo-a",
            "userId": "guest",
            "location": "西湖",
            "score": 9.0,
            "description": "audit photo secret description",
            "tags": ["夜景"],
        },
    )
    assert create.status_code == 200
    response = client.post(
        "/api/photo/copywriting",
        headers=headers,
        json={
            "userId": "guest",
            "photoIds": ["audit-photo-a"],
            "persona": "quiet guide",
            "style": "warm",
        },
    )
    assert response.status_code == 200

    audit = client.get(
        "/api/audit/model-calls",
        headers=headers,
        params={
            "provider": "audit-copywriting-provider",
            "scenario": "photo_copywriting",
            "fallback": False,
            "limit": 5,
        },
    )

    assert audit.status_code == 200
    items = audit.json()["items"]
    assert items
    assert items[0]["requestSummary"]["photoCount"] == 1
    assert items[0]["requestSummary"]["photoIds"] == ["audit-photo-a"]
    assert items[0]["requestSummary"]["userId"] == user_id
    assert "audit photo secret description" not in audit.text
