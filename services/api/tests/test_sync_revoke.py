from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_sync_revoke_removes_selected_cloud_entities_without_clearing_everything():
    suffix = uuid4().hex
    user_id = f"sync-revoke-user-{suffix}"
    keep_memory_id = f"sync-revoke-keep-memory-{suffix}"
    revoke_memory_id = f"sync-revoke-memory-{suffix}"
    trip_id = f"sync-revoke-trip-{suffix}"

    pushed = client.post(
        "/api/sync/push",
        json={
            "userId": user_id,
            "memories": [
                {
                    "id": keep_memory_id,
                    "title": "keep memory",
                    "content": "this memory should remain",
                    "scope": "longTerm",
                    "updatedAt": "2026-06-20T10:00:00+08:00",
                },
                {
                    "id": revoke_memory_id,
                    "title": "revoke memory",
                    "content": "this memory should be removed from cloud sync",
                    "scope": "longTerm",
                    "updatedAt": "2026-06-20T10:00:00+08:00",
                },
            ],
            "profile": {"travelPace": "slow", "interestTags": ["night"]},
            "trips": [
                {
                    "id": trip_id,
                    "destination": "Chongqing",
                    "status": "planning",
                    "plan": {"title": "real plan"},
                }
            ],
        },
    )
    assert pushed.status_code == 200

    revoked = client.post(
        "/api/sync/revoke",
        json={
            "userId": user_id,
            "memories": [revoke_memory_id],
            "profile": True,
            "trips": [trip_id],
        },
    )

    assert revoked.status_code == 200
    payload = revoked.json()
    assert payload["revoked"] == {"memories": 1, "profile": 1, "trips": 1}
    assert {item["entityId"] for item in payload["records"]} >= {revoke_memory_id, trip_id}

    pulled = client.get("/api/sync/pull", params={"userId": user_id})
    assert pulled.status_code == 200
    cloud = pulled.json()
    assert [item["id"] for item in cloud["memories"]] == [keep_memory_id]
    assert cloud["profile"] is None
    assert cloud["trips"] == []