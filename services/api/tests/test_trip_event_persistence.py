from fastapi.testclient import TestClient
from uuid import uuid4

from app.main import app


client = TestClient(app)


def _guest_headers(label: str) -> dict[str, str]:
    response = client.post(
        "/api/auth/guest",
        json={"deviceId": f"trip-event-{label}-{uuid4().hex}", "displayName": "Trip Event Guest"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['accessToken']}"}


def test_trip_review_is_persisted_and_readable_by_trip_id():
    headers = _guest_headers("review")
    trip_id = f"review-persist-trip-{uuid4().hex}"
    create_response = client.post(
        "/api/trip/review",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": trip_id,
            "message": "生成今天旅行复盘",
            "completedTasks": [{"id": "task-a", "title": "完成一次夜景拍照", "status": "completed"}],
            "temporaryMemories": [{"id": "mem-a", "title": "不想太累", "content": "减少跨区移动"}],
        },
    )

    assert create_response.status_code == 200
    created = create_response.json()
    assert created["reviewId"].startswith("review-")

    read_response = client.get(
        "/api/trip/review",
        headers=headers,
        params={"tripId": trip_id},
    )

    assert read_response.status_code == 200
    payload = read_response.json()
    assert payload["reviewId"] == created["reviewId"]
    assert payload["tripId"] == trip_id
    assert payload["review"]["completedTasks"][0]["title"] == "完成一次夜景拍照"


def test_trip_review_read_returns_latest_review_for_user():
    headers = _guest_headers("latest-review")
    trip_id = f"review-latest-trip-{uuid4().hex}"
    first_response = client.post(
        "/api/trip/review",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": trip_id,
            "message": "生成第一次旅行复盘",
            "completedTasks": [{"id": "task-a", "title": "第一次复盘任务", "status": "completed"}],
        },
    )
    second_response = client.post(
        "/api/trip/review",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": trip_id,
            "message": "生成第二次旅行复盘",
            "completedTasks": [{"id": "task-b", "title": "第二次复盘任务", "status": "completed"}],
        },
    )

    assert first_response.status_code == 200
    assert second_response.status_code == 200

    read_response = client.get(
        "/api/trip/review",
        headers=headers,
        params={"tripId": trip_id},
    )

    assert read_response.status_code == 200
    payload = read_response.json()
    assert payload["reviewId"] == second_response.json()["reviewId"]
    assert payload["review"]["completedTasks"][0]["title"] == "第二次复盘任务"


def test_reminder_trigger_is_persisted_in_history():
    headers = _guest_headers("reminder")
    trip_id = f"reminder-trip-{uuid4().hex}"
    trigger_response = client.post(
        "/api/trip/reminders/trigger",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": trip_id,
            "triggerType": "status",
            "location": "解放碑",
            "eventPayload": {"energy": 28},
        },
    )

    assert trigger_response.status_code == 200
    triggered = trigger_response.json()
    assert triggered["historyId"].startswith("reminder-")

    history_response = client.get(
        "/api/trip/reminders/history",
        headers=headers,
        params={"tripId": trip_id},
    )

    assert history_response.status_code == 200
    items = history_response.json()["items"]
    assert items[0]["historyId"] == triggered["historyId"]
    assert items[0]["triggerType"] == "status"
    assert items[0]["eventPayload"]["energy"] == 28
    assert items[0]["items"]


def test_tool_call_endpoint_records_trace_id_and_provider():
    headers = _guest_headers("tool")
    response = client.post(
        "/api/tools/weather_tool/call",
        headers=headers,
        json={"userId": "guest", "payload": {"city": "杭州"}},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["toolTraceId"].startswith("tool-")
    assert payload["toolName"] == "weather_tool"
    assert payload["result"]["provider"] in {"unconfigured", "amap"}
