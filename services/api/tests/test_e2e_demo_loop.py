"""端到端演示闭环测试：记忆 → 规划 → 提醒 → 盲盒 → 复盘。

覆盖 P0 完整链路，确保各环节衔接不出错。
"""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_e2e_chat_returns_full_demo_response():
    """Agent 聊天返回记忆候选、规划、提醒、复盘和工具追踪。"""
    response = client.post(
        "/api/agent/chat",
        json={
            "message": "周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜",
            "sessionId": "e2e-demo",
            "userId": "e2e-user",
            "tripId": "e2e-trip",
        },
    )

    assert response.status_code == 200
    body = response.json()

    assert "replyText" in body
    assert "重庆" in body["replyText"]

    cards = body.get("cards") or []
    card_types = {card["type"] for card in cards}
    assert "tripPlan" in card_types
    assert "reminders" in card_types

    memory_candidates = body.get("memoryCandidates") or []
    assert len(memory_candidates) >= 2, "期望至少 2 条记忆候选"

    tool_trace = body.get("toolTrace") or []
    assert len(tool_trace) >= 1, "期望至少 1 条工具追踪"

    assert body.get("avatarState") in ("planning", "thinking")


def test_e2e_memory_crud_flow():
    """记忆胶囊完整 CRUD 闭环。"""
    user_id = "e2e-mem-user"
    memory = {
        "id": "e2e-mem-cilantro",
        "title": "不吃香菜",
        "content": "用户明确表示不吃香菜，后续推荐避开。",
        "scope": "longTerm",
        "category": "dietary_preference",
        "userId": user_id,
    }

    create = client.post("/api/memory/capsules", json=memory)
    assert create.status_code == 200
    assert create.json()["title"] == "不吃香菜"

    read = client.get("/api/memory/capsules", params={"userId": user_id})
    assert read.status_code == 200
    items = read.json()["items"]
    assert any(item["id"] == "e2e-mem-cilantro" for item in items)

    update = client.put(
        "/api/memory/capsules/e2e-mem-cilantro",
        json={"title": "不要香菜", "content": "更新：所有菜品避开香菜"},
    )
    assert update.status_code == 200
    assert update.json()["title"] == "不要香菜"

    delete = client.delete("/api/memory/capsules/e2e-mem-cilantro")
    assert delete.status_code == 200
    assert delete.json()["deleted"] is True


def test_e2e_trip_plan_and_reminder_flow():
    """行程规划 + 提醒触发闭环。"""
    plan = client.post(
        "/api/trip/plan",
        json={
            "message": "周末想去重庆两天，不想太累，喜欢夜景",
            "userId": "e2e-user",
            "tripId": "e2e-trip",
            "destination": "重庆",
            "durationDays": 2,
            "budget": "中等",
            "transportMode": "mixed",
            "tripStyle": "轻松",
        },
    )
    assert plan.status_code == 200
    plan_body = plan.json()
    assert plan_body["title"]
    assert plan_body["destination"] == "重庆"

    reminder = client.post(
        "/api/trip/reminders/trigger",
        json={
            "triggerType": "time",
            "location": "洪崖洞",
            "userId": "e2e-user",
            "tripId": "e2e-trip",
        },
    )
    assert reminder.status_code == 200
    reminder_items = reminder.json().get("items") or []
    assert len(reminder_items) >= 1

    read = client.get(
        "/api/trip/current",
        params={"userId": "e2e-user"},
    )
    assert read.status_code == 200
    assert read.json()["tripId"] == "e2e-trip"


def test_e2e_blind_box_and_review_flow():
    """盲盒任务 + 复盘生成闭环。"""
    tasks = client.get(
        "/api/trip/blind-box/tasks",
        params={"userId": "e2e-user", "tripId": "e2e-trip"},
    )
    assert tasks.status_code == 200
    task_items = tasks.json()["items"]
    assert len(task_items) >= 3

    first_task_id = task_items[0]["id"]
    accept = client.post(
        f"/api/trip/blind-box/tasks/{first_task_id}/status",
        json={
            "userId": "e2e-user",
            "tripId": "e2e-trip",
            "status": "accepted",
        },
    )
    assert accept.status_code == 200
    assert accept.json()["status"] == "accepted"

    complete = client.post(
        f"/api/trip/blind-box/tasks/{first_task_id}/status",
        json={
            "userId": "e2e-user",
            "tripId": "e2e-trip",
            "status": "completed",
        },
    )
    assert complete.status_code == 200
    assert complete.json()["status"] == "completed"

    review = client.post(
        "/api/trip/review",
        json={
            "userId": "e2e-user",
            "tripId": "e2e-trip",
        },
    )
    assert review.status_code == 200
    review_body = review.json()
    assert "reviewId" in review_body or "route" in review_body

    read = client.get(
        "/api/trip/review",
        params={"userId": "e2e-user", "tripId": "e2e-trip"},
    )
    assert read.status_code == 200


def test_e2e_dashboard_aggregates_full_context():
    """Dashboard 聚合本次旅程的完整上下文。"""
    dashboard = client.get(
        "/api/trip/dashboard",
        params={"userId": "e2e-user", "tripId": "e2e-trip"},
    )
    assert dashboard.status_code == 200
    body = dashboard.json()

    assert "currentTrip" in body
    assert "memories" in body
    assert "reminderHistory" in body


def test_e2e_empty_state_handling():
    """从未交互的用户的空状态处理。"""
    resp = client.get(
        "/api/trip/dashboard",
        params={"userId": "fresh-user-never-interacted"},
    )
    assert resp.status_code == 200
    body = resp.json()
    current = body.get("currentTrip", {})
    assert current.get("status") in ("empty", None, "planning")


def test_e2e_group_coordination_and_plan():
    """多人组队协调 + 规划闭环。"""
    coord = client.post(
        "/api/trip/group/coordinate",
        json={
            "userId": "e2e-user",
            "tripId": "e2e-group-trip",
            "destination": "重庆",
            "members": [
                {
                    "memberId": "member-a",
                    "displayName": "成员A",
                    "preferences": {
                        "pace": "轻松",
                        "budget": "中等",
                        "interests": ["夜景", "美食"],
                        "dietary": ["不吃香菜"],
                    },
                },
                {
                    "memberId": "member-b",
                    "displayName": "成员B",
                    "preferences": {
                        "pace": "紧凑",
                        "budget": "经济",
                        "interests": ["历史", "徒步"],
                        "dietary": [],
                    },
                },
            ],
        },
    )
    assert coord.status_code == 200
    body = coord.json()
    assert len(body.get("conflicts") or []) >= 1
    assert body.get("compromisePlan", {}).get("pace") is not None
    assert body.get("privacySummary") is not None

    read = client.get(
        "/api/trip/group/coordination",
        params={"tripId": "e2e-group-trip"},
    )
    assert read.status_code == 200


def test_e2e_route_points_and_avatar_events():
    """路线轨迹点 + 蓝小心状态事件写入与读取。"""
    route = client.post(
        "/api/trip/route-points",
        json={
            "userId": "e2e-user",
            "tripId": "e2e-trip",
            "points": [
                {"latitude": 29.563, "longitude": 106.588, "label": "洪崖洞",
                 "recordedAt": "2026-06-20T19:00:00Z"},
            ],
        },
    )
    assert route.status_code == 200

    read_route = client.get(
        "/api/trip/route-points",
        params={"userId": "e2e-user", "tripId": "e2e-trip"},
    )
    assert read_route.status_code == 200
    assert len(read_route.json().get("points") or []) >= 1

    avatar = client.post(
        "/api/trip/avatar-state/events",
        json={
            "userId": "e2e-user",
            "tripId": "e2e-trip",
            "eventType": "mood_change",
            "title": "心情变好",
            "deltas": {"mood": 5},
            "reason": "看到夜景",
        },
    )
    assert avatar.status_code == 200

    read_avatar = client.get(
        "/api/trip/avatar-state/events",
        params={"userId": "e2e-user", "tripId": "e2e-trip"},
    )
    assert read_avatar.status_code == 200
    assert len(read_avatar.json().get("items") or []) >= 1
