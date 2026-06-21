from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_memory_capsules_are_persisted_per_user():
    response = client.post(
        "/api/memory/capsules",
        json={
            "id": "mem-db-user-a",
            "userId": "user-a",
            "title": "喜欢夜景",
            "content": "规划时保留夜景点。",
            "scope": "longTerm",
        },
    )
    assert response.status_code == 200

    user_a = client.get("/api/memory/capsules", params={"userId": "user-a"})
    user_b = client.get("/api/memory/capsules", params={"userId": "user-b"})

    assert any(item["id"] == "mem-db-user-a" for item in user_a.json()["items"])
    assert all(item["id"] != "mem-db-user-a" for item in user_b.json()["items"])


def test_profile_is_persisted_per_user():
    update = client.put(
        "/api/profile/me",
        params={"userId": "profile-user-a"},
        json={
            "travelPace": "慢节奏",
            "dietaryPreferences": ["不吃香菜"],
            "interestTags": ["夜景", "老街"],
            "transportPreferences": ["少换乘"],
            "budgetPreference": "中低预算",
            "expressionStyle": "轻松口语",
        },
    )
    assert update.status_code == 200

    read_back = client.get("/api/profile/me", params={"userId": "profile-user-a"})

    assert read_back.status_code == 200
    payload = read_back.json()
    assert payload["travelPace"] == "慢节奏"
    assert payload["transportPreferences"] == ["少换乘"]
    assert payload["expressionStyle"] == "轻松口语"


def test_trip_plan_is_saved_as_current_trip():
    plan = client.post(
        "/api/trip/plan",
        json={
            "userId": "trip-user-a",
            "tripId": "trip-db-a",
            "destination": "重庆",
            "message": "周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜",
        },
    )
    assert plan.status_code == 200

    current = client.get("/api/trip/current", params={"userId": "trip-user-a"})

    assert current.status_code == 200
    payload = current.json()
    assert payload["tripId"] == "trip-db-a"
    assert payload["destination"] == "重庆"
    assert payload["status"] == "planning"
    assert payload["plan"]["title"] == plan.json()["title"]


# ── 3.1 边界与错误路径测试 ─────────────────────────────────────────────────


def test_memory_capsule_update_and_delete():
    """更新已有记忆胶囊后删除。"""
    mem_id = "persist-update-test"
    user_id = "persist-user"
    client.post("/api/memory/capsules", json={
        "id": mem_id, "userId": user_id,
        "title": "原始标题", "content": "原始内容", "scope": "longTerm",
    })
    update = client.put(
        f"/api/memory/capsules/{mem_id}",
        json={"title": "修改后标题", "content": "修改后内容", "scope": "currentTrip"},
    )
    assert update.status_code == 200
    assert update.json()["title"] == "修改后标题"
    assert update.json()["scope"] == "currentTrip"

    delete = client.delete(f"/api/memory/capsules/{mem_id}")
    assert delete.status_code == 200
    assert delete.json()["deleted"] is True


def test_memory_capsule_delete_nonexistent_returns_404():
    """删除不存在的记忆胶囊返回 404。"""
    resp = client.delete("/api/memory/capsules/nonexistent-memory-xyz")
    assert resp.status_code == 404


def test_memory_update_nonexistent_returns_404():
    """更新不存在的记忆胶囊返回 404。"""
    resp = client.put(
        "/api/memory/capsules/nonexistent-xyz",
        json={"title": "无", "content": "无"},
    )
    assert resp.status_code == 404


def test_profile_read_default_user_returns_empty_fields():
    """从未设置过 profile 的用户读回合理的默认值。"""
    resp = client.get("/api/profile/me", params={"userId": "never-existed-user-abc"})
    assert resp.status_code == 200
    body = resp.json()
    assert "travelPace" in body
    assert "interestTags" in body
    assert "dietaryPreferences" in body
    assert "budgetPreference" in body


def test_clear_memory_and_trip_endpoints():
    """清空记忆和当前旅行 API 可用。"""
    user_id = "clear-test-user"
    client.post("/api/memory/capsules", json={
        "id": "clear-mem", "userId": user_id,
        "title": "测试", "content": "测试", "scope": "temporary",
    })

    clear_mem = client.delete("/api/memory/capsules", params={"userId": user_id})
    assert clear_mem.status_code == 200

    clear_trip = client.delete("/api/trip/current", params={"userId": user_id})
    assert clear_trip.status_code == 200


def test_memory_capsule_create_without_required_id():
    """缺少必填字段时返回 422。"""
    resp = client.post("/api/memory/capsules", json={
        "title": "无ID", "content": "无", "scope": "longTerm",
    })
    assert resp.status_code == 422


def test_trip_plan_without_message_returns_422():
    """空消息规划返回 422。"""
    resp = client.post("/api/trip/plan", json={
        "userId": "test-user", "tripId": "test-trip",
    })
    assert resp.status_code == 422