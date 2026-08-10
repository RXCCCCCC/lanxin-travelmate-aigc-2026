from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def _guest_headers(label: str) -> dict[str, str]:
    response = client.post(
        "/api/auth/guest",
        json={"deviceId": f"sync-conflict-{label}-{uuid4().hex}", "displayName": "Sync Guest"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['accessToken']}"}


def test_sync_push_reports_memory_conflict_when_client_copy_is_older():
    suffix = uuid4().hex
    headers = _guest_headers("server-wins")
    memory_id = f"sync-conflict-memory-a-{suffix}"

    first = client.post(
        "/api/sync/push",
        headers=headers,
        json={
            "userId": "guest",
            "memories": [
                {
                    "id": memory_id,
                    "title": "server version",
                    "content": "server content",
                    "scope": "longTerm",
                    "updatedAt": "2026-06-20T10:00:00+08:00",
                }
            ],
        },
    )
    assert first.status_code == 200
    assert first.json()["pushed"]["memories"] == 1

    older = client.post(
        "/api/sync/push",
        headers=headers,
        json={
            "userId": "guest",
            "conflictStrategy": "serverWins",
            "memories": [
                {
                    "id": memory_id,
                    "title": "older client version",
                    "content": "older client content",
                    "scope": "longTerm",
                    "updatedAt": "2026-06-20T09:00:00+08:00",
                }
            ],
        },
    )

    assert older.status_code == 200
    payload = older.json()
    assert payload["pushed"]["memories"] == 0
    assert payload["conflicts"]
    conflict = payload["conflicts"][0]
    assert conflict["entityType"] == "memory"
    assert conflict["entityId"] == memory_id
    assert conflict["resolution"] == "serverWins"

    pulled = client.get("/api/sync/pull", headers=headers)
    item = next(memory for memory in pulled.json()["memories"] if memory["id"] == memory_id)
    assert item["title"] == "server version"


def test_sync_push_client_wins_can_resolve_memory_conflict():
    suffix = uuid4().hex
    headers = _guest_headers("client-wins")
    memory_id = f"sync-conflict-memory-b-{suffix}"

    created = client.post(
        "/api/sync/push",
        headers=headers,
        json={
            "userId": "guest",
            "memories": [
                {
                    "id": memory_id,
                    "title": "server original",
                    "content": "server content",
                    "scope": "longTerm",
                    "updatedAt": "2026-06-20T10:00:00+08:00",
                }
            ],
        },
    )
    assert created.status_code == 200
    assert created.json()["pushed"]["memories"] == 1

    client_wins = client.post(
        "/api/sync/push",
        headers=headers,
        json={
            "userId": "guest",
            "conflictStrategy": "clientWins",
            "memories": [
                {
                    "id": memory_id,
                    "title": "client chosen version",
                    "content": "client content",
                    "scope": "currentTrip",
                    "updatedAt": "2026-06-20T09:00:00+08:00",
                }
            ],
        },
    )

    assert client_wins.status_code == 200
    payload = client_wins.json()
    assert payload["pushed"]["memories"] == 1
    assert payload["conflicts"][0]["resolution"] == "clientWins"

    pulled = client.get("/api/sync/pull", headers=headers)
    item = next(memory for memory in pulled.json()["memories"] if memory["id"] == memory_id)
    assert item["title"] == "client chosen version"
    assert item["scope"] == "currentTrip"
