from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_trip_review_endpoint_returns_p1_review_fields():
    response = client.post(
        "/api/trip/review",
        json={
            "message": "生成今天重庆夜景行程复盘",
            "tripId": "demo-chongqing-weekend",
            "completedTasks": [
                {
                    "id": "task-night-photo",
                    "title": "拍一张不是游客照的重庆夜景",
                    "status": "completed",
                }
            ],
            "temporaryMemories": [
                {
                    "id": "mem-slow-pace",
                    "title": "本次旅行想轻松一点",
                    "content": "本次行程希望低强度，减少跨区移动。",
                }
            ],
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["route"] == "解放碑 → 山城步道 → 洪崖洞 → 南山一棵树"
    assert payload["completedTasks"][0]["title"] == "拍一张不是游客照的重庆夜景"
    assert payload["nextTripSuggestions"]
    assert payload["temporaryMemoryPromotions"][0]["suggestedScope"] == "longTerm"


def test_trip_review_endpoint_has_mock_fallback_without_request_context():
    response = client.post("/api/trip/review", json={})

    assert response.status_code == 200
    payload = response.json()
    assert payload["completedTasks"]
    assert payload["temporaryMemoryPromotions"]
