from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def _guest_headers(device_id: str) -> tuple[str, dict[str, str]]:
    response = client.post("/api/auth/guest", json={"deviceId": device_id, "displayName": "Scoped Guest"})
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_photo_routes_scope_guest_payload_to_authenticated_user():
    user_id, headers = _guest_headers(f"scope-photo-{uuid4().hex}")
    photo_id = f"photo-scope-{uuid4().hex}"

    created = client.post(
        "/api/photo/candidates",
        headers=headers,
        json={
            "id": photo_id,
            "userId": "guest",
            "location": "River Walk",
            "score": 8.4,
            "description": "Candidate owned by authenticated user.",
            "tags": ["river"],
        },
    )
    assert created.status_code == 200
    assert created.json()["userId"] == user_id

    metadata = client.post(
        "/api/photo/upload-metadata",
        headers=headers,
        json={"userId": "guest", "filename": "river.jpg", "contentType": "image/jpeg"},
    )
    assert metadata.status_code == 200
    assert metadata.json()["userId"] == user_id

    scoped = client.get("/api/photo/candidates", headers=headers)
    assert scoped.status_code == 200
    assert any(item["id"] == photo_id for item in scoped.json()["items"])

    global_guest = client.get("/api/photo/candidates")
    assert global_guest.status_code == 200
    assert all(item["id"] != photo_id for item in global_guest.json()["items"])


def test_sync_routes_scope_guest_payload_to_authenticated_user():
    user_id, headers = _guest_headers(f"scope-sync-{uuid4().hex}")
    memory_id = f"sync-scope-memory-{uuid4().hex}"
    trip_id = f"sync-scope-trip-{uuid4().hex}"

    pushed = client.post(
        "/api/sync/push",
        headers=headers,
        json={
            "userId": "guest",
            "memories": [
                {
                    "id": memory_id,
                    "title": "Quiet cafes",
                    "content": "Prefer quiet cafes during breaks.",
                    "scope": "longTerm",
                }
            ],
            "profile": {"travelPace": "slow", "interestTags": ["cafes"]},
            "trips": [{"id": trip_id, "destination": "Suzhou", "status": "planning", "plan": {"title": "Slow trip"}}],
        },
    )
    assert pushed.status_code == 200
    assert pushed.json()["pushed"] == {"memories": 1, "profile": 1, "trips": 1}

    pulled = client.get("/api/sync/pull", headers=headers)
    assert pulled.status_code == 200
    payload = pulled.json()
    assert payload["userId"] == user_id
    assert any(item["id"] == memory_id for item in payload["memories"])
    assert any(item["id"] == trip_id for item in payload["trips"])

    selected = client.post(
        "/api/sync/selected-memory",
        headers=headers,
        json={"userId": "guest", "memoryIds": [memory_id]},
    )
    assert selected.status_code == 200
    assert selected.json()["selected"][0]["id"] == memory_id


def test_sync_and_memory_routes_reject_cross_user_record_hijack():
    _user_a, headers_a = _guest_headers(f"scope-hijack-a-{uuid4().hex}")
    _user_b, headers_b = _guest_headers(f"scope-hijack-b-{uuid4().hex}")
    memory_id = f"hijack-memory-{uuid4().hex}"
    trip_id = f"hijack-trip-{uuid4().hex}"

    created = client.post(
        "/api/memory/capsules",
        headers=headers_a,
        json={
            "id": memory_id,
            "userId": "guest",
            "title": "Owner A",
            "content": "A owns this memory.",
            "scope": "longTerm",
        },
    )
    assert created.status_code == 200

    hijack_memory = client.post(
        "/api/memory/capsules",
        headers=headers_b,
        json={
            "id": memory_id,
            "userId": "guest",
            "title": "Owner B",
            "content": "B must not take this memory.",
            "scope": "longTerm",
        },
    )
    assert hijack_memory.status_code == 403

    pushed_a = client.post(
        "/api/sync/push",
        headers=headers_a,
        json={
            "userId": "guest",
            "trips": [
                {
                    "id": trip_id,
                    "destination": "杭州",
                    "status": "planning",
                    "plan": {"title": "A trip"},
                }
            ],
        },
    )
    assert pushed_a.status_code == 200

    hijack_sync = client.post(
        "/api/sync/push",
        headers=headers_b,
        json={
            "userId": "guest",
            "memories": [
                {
                    "id": memory_id,
                    "title": "Owner B",
                    "content": "B must not update A memory.",
                    "scope": "longTerm",
                }
            ],
            "trips": [
                {
                    "id": trip_id,
                    "destination": "广州",
                    "status": "planning",
                    "plan": {"title": "B trip"},
                }
            ],
        },
    )
    assert hijack_sync.status_code == 403


def test_tool_call_response_scopes_guest_payload_to_authenticated_user():
    user_id, headers = _guest_headers(f"scope-tool-{uuid4().hex}")

    response = client.post(
        "/api/tools/weather_tool/call",
        headers=headers,
        json={"userId": "guest", "payload": {"city": "Suzhou"}},
    )

    assert response.status_code == 200
    assert response.json()["userId"] == user_id
