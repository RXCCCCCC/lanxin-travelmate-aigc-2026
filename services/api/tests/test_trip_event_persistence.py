from fastapi.testclient import TestClient
from uuid import uuid4

from app.main import app


client = TestClient(app)


def test_trip_review_is_persisted_and_readable_by_trip_id():
    user_id = f"review-user-{uuid4().hex}"
    trip_id = f"review-persist-trip-{uuid4().hex}"
    create_response = client.post(
        "/api/trip/review",
        json={
            "userId": user_id,
            "tripId": trip_id,
            "message": "生成今天旅行复盘",
            "completedTasks": [{"id": "task-a", "title": "完成一次夜景拍照", "status": "completed"}],
            "temporaryMemories": [{"id": "mem-a", "title": "不想太累", "content": "减少跨区移动"}],
        },
    )

    assert create_response.status_code == 200
    created = create_response.json()
    assert created["reviewId"].startswith("review-")

    read_response = client.get("/api/trip/review", params={"userId": user_id, "tripId": trip_id})

    assert read_response.status_code == 200
    payload = read_response.json()
    assert payload["reviewId"] == created["reviewId"]
    assert payload["tripId"] == trip_id
    assert payload["review"]["completedTasks"][0]["title"] == "完成一次夜景拍照"


def test_trip_review_read_returns_latest_review_for_user():
    user_id = "review-latest-user-a"
    trip_id = "review-latest-trip-a"
    first_response = client.post(
        "/api/trip/review",
        json={
            "userId": user_id,
            "tripId": trip_id,
            "message": "生成第一次旅行复盘",
            "completedTasks": [{"id": "task-a", "title": "第一次复盘任务", "status": "completed"}],
        },
    )
    second_response = client.post(
        "/api/trip/review",
        json={
            "userId": user_id,
            "tripId": trip_id,
            "message": "生成第二次旅行复盘",
            "completedTasks": [{"id": "task-b", "title": "第二次复盘任务", "status": "completed"}],
        },
    )

    assert first_response.status_code == 200
    assert second_response.status_code == 200

    read_response = client.get("/api/trip/review", params={"userId": user_id, "tripId": trip_id})

    assert read_response.status_code == 200
    payload = read_response.json()
    assert payload["reviewId"] == second_response.json()["reviewId"]
    assert payload["review"]["completedTasks"][0]["title"] == "第二次复盘任务"


def test_reminder_trigger_is_persisted_in_history():
    user_id = "reminder-history-user-a"
    trigger_response = client.post(
        "/api/trip/reminders/trigger",
        json={
            "userId": user_id,
            "tripId": "reminder-trip-a",
            "triggerType": "status",
            "location": "解放碑",
            "eventPayload": {"energy": 28},
        },
    )

    assert trigger_response.status_code == 200
    triggered = trigger_response.json()
    assert triggered["historyId"].startswith("reminder-")

    history_response = client.get("/api/trip/reminders/history", params={"userId": user_id})

    assert history_response.status_code == 200
    items = history_response.json()["items"]
    assert items[0]["historyId"] == triggered["historyId"]
    assert items[0]["triggerType"] == "status"
    assert items[0]["eventPayload"]["energy"] == 28
    assert items[0]["items"]


def test_tool_call_endpoint_records_trace_id_and_provider():
    response = client.post(
        "/api/tools/weather_tool/call",
        json={"userId": "tool-call-user-a", "payload": {"city": "杭州"}},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["toolTraceId"].startswith("tool-")
    assert payload["toolName"] == "weather_tool"
    assert payload["result"]["provider"] in {"unconfigured", "amap"}
