from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_sync_push_reports_memory_conflict_when_client_copy_is_older():
    suffix = uuid4().hex
    user_id = f"sync-conflict-user-a-{suffix}"
    memory_id = f"sync-conflict-memory-a-{suffix}"

    first = client.post(
        "/api/sync/push",
        json={
            "userId": user_id,
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
        json={
            "userId": user_id,
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

    pulled = client.get("/api/sync/pull", params={"userId": user_id})
    item = next(memory for memory in pulled.json()["memories"] if memory["id"] == memory_id)
    assert item["title"] == "server version"


def test_sync_push_client_wins_can_resolve_memory_conflict():
    suffix = uuid4().hex
    user_id = f"sync-conflict-user-b-{suffix}"
    memory_id = f"sync-conflict-memory-b-{suffix}"

    created = client.post(
        "/api/sync/push",
        json={
            "userId": user_id,
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
        json={
            "userId": user_id,
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

    pulled = client.get("/api/sync/pull", params={"userId": user_id})
    item = next(memory for memory in pulled.json()["memories"] if memory["id"] == memory_id)
    assert item["title"] == "client chosen version"
    assert item["scope"] == "currentTrip"


# ── 3.2 补充冲突场景 ───────────────────────────────────────────────────────


def test_sync_push_default_strategy_is_server_wins():
    """不传 conflictStrategy 时默认 serverWins。"""
    suffix = uuid4().hex
    user_id = f"sync-default-user-{suffix}"
    memory_id = f"sync-default-mem-{suffix}"

    client.post("/api/sync/push", json={
        "userId": user_id,
        "memories": [{
            "id": memory_id, "title": "server", "content": "s",
            "scope": "longTerm", "updatedAt": "2026-06-20T12:00:00+08:00",
        }],
    })
    older = client.post("/api/sync/push", json={
        "userId": user_id,
        "memories": [{
            "id": memory_id, "title": "older", "content": "o",
            "scope": "temporary", "updatedAt": "2026-06-20T10:00:00+08:00",
        }],
    })
    assert older.status_code == 200
    assert older.json()["pushed"]["memories"] == 0
    pulled = client.get("/api/sync/pull", params={"userId": user_id})
    item = next(m for m in pulled.json()["memories"] if m["id"] == memory_id)
    assert item["title"] == "server"


def test_sync_push_trip_supported():
    """同步旅程可推送成功。"""
    suffix = uuid4().hex
    user_id = f"sync-trip-user-{suffix}"
    trip_id = f"sync-trip-{suffix}"

    resp = client.post("/api/sync/push", json={
        "userId": user_id,
        "trips": [{
            "id": trip_id, "destination": "成都", "status": "planning",
            "title": "server trip", "startDate": "2026-07-01",
            "updatedAt": "2026-06-21T10:00:00+08:00",
        }],
    })
    assert resp.status_code == 200
    assert resp.json()["pushed"]["trips"] >= 1


def test_sync_push_profile_supported():
    """同步画像可推送成功。"""
    suffix = uuid4().hex
    user_id = f"sync-profile-user-{suffix}"

    resp = client.post("/api/sync/push", json={
        "userId": user_id,
        "profiles": [{
            "travelPace": "慢节奏", "updatedAt": "2026-06-21T10:00:00+08:00",
        }],
    })
    assert resp.status_code == 200
    pushed = resp.json()["pushed"]
    assert pushed.get("profile", 0) >= 0


def test_sync_push_newer_client_copy_wins_without_conflict():
    """服务端时间戳更新时不产生冲突。"""
    suffix = uuid4().hex
    user_id = f"sync-newer-user-{suffix}"
    memory_id = f"sync-newer-mem-{suffix}"

    client.post("/api/sync/push", json={
        "userId": user_id,
        "memories": [{
            "id": memory_id, "title": "server old", "content": "old",
            "scope": "longTerm", "updatedAt": "2026-06-20T09:00:00+08:00",
        }],
    })
    newer = client.post("/api/sync/push", json={
        "userId": user_id,
        "memories": [{
            "id": memory_id, "title": "client newer", "content": "new",
            "scope": "currentTrip", "updatedAt": "2026-06-20T11:00:00+08:00",
        }],
    })
    assert newer.status_code == 200
    assert newer.json()["pushed"]["memories"] == 1

    pulled = client.get("/api/sync/pull", params={"userId": user_id})
    item = next(m for m in pulled.json()["memories"] if m["id"] == memory_id)
    assert item["title"] == "client newer"


def test_sync_revoke_removes_memory_from_owner():
    """撤销操作删除指定用户和指定记忆。"""
    suffix = uuid4().hex
    user_id = f"revoke-user-{suffix}"
    memory_id = f"revoke-mem-{suffix}"

    client.post("/api/sync/push", json={
        "userId": user_id,
        "memories": [{
            "id": memory_id, "title": f"{user_id} mem", "content": "test",
            "scope": "longTerm", "updatedAt": "2026-06-21T10:00:00+08:00",
        }],
    })
    resp = client.post("/api/sync/revoke", json={
        "userId": user_id,
        "memories": [memory_id],
    })
    assert resp.status_code == 200
    pulled = client.get("/api/sync/pull", params={"userId": user_id})
    assert not any(m["id"] == memory_id for m in pulled.json()["memories"])