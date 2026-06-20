from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_trip_review_is_persisted_and_readable_by_trip_id():
    trip_id = "review-persist-trip-a"
    create_response = client.post(
        "/api/trip/review",
        json={
            "userId": "review-user-a",
            "tripId": trip_id,
            "message": "生成今天旅行复盘",
            "completedTasks": [{"id": "task-a", "title": "完成一次夜景拍照", "status": "completed"}],
            "temporaryMemories": [{"id": "mem-a", "title": "不想太累", "content": "减少跨区移动"}],
        },
    )

    assert create_response.status_code == 200
    created = create_response.json()
    assert created["reviewId"].startswith("review-")

    read_response = client.get("/api/trip/review", params={"tripId": trip_id})

    assert read_response.status_code == 200
    payload = read_response.json()
    assert payload["reviewId"] == created["reviewId"]
    assert payload["tripId"] == trip_id
    assert payload["review"]["completedTasks"][0]["title"] == "完成一次夜景拍照"


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