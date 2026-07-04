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
            "profileContext": {
                "travelPace": "light",
                "interestTags": ["夜景"],
                "dietaryPreferences": ["不吃香菜"],
            },
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["route"] == ""
    assert payload["highlightPhotos"] == []
    assert payload["completedTasks"][0]["title"] == "拍一张不是游客照的重庆夜景"
    assert payload["nextTripSuggestions"] == []
    assert payload["temporaryMemoryPromotions"][0]["suggestedScope"] == "longTerm"
    assert payload["profileContext"]["travelPace"] == "light"
    assert payload["profileContext"]["interestTags"] == ["夜景"]


def test_trip_review_endpoint_has_mock_fallback_without_request_context():
    response = client.post("/api/trip/review", json={})

    assert response.status_code == 200
    payload = response.json()
    assert payload["completedTasks"] == []
    assert payload["temporaryMemoryPromotions"] == []


def test_trip_review_empty_context_does_not_inject_fixed_city_fixtures():
    response = client.post("/api/trip/review", json={})

    assert response.status_code == 200
    payload = response.json()
    response_text = response.text
    assert "洪崖洞" not in response_text
    assert "解放碑" not in response_text
    assert "南山一棵树" not in response_text
    assert payload["route"] == ""
    assert payload["highlightPhotos"] == []
    assert payload["nextTripSuggestions"] == []


def test_direct_trip_review_uses_review_only_graph(monkeypatch):
    from app.api.routes import trip

    class ReviewOnlyGraph:
        def invoke(self, state):
            raise AssertionError("direct trip review route should not run the full agent graph")

        def invoke_review_only(self, state):
            return {
                **state,
                "completed_tasks": state["context"]["completedTasks"],
                "temporary_memory_promotions": [],
                "review": {
                    "route": state["context"]["route"],
                    "highlightPhotos": [],
                    "newMemories": [],
                    "completedTasks": state["context"]["completedTasks"],
                    "reminderHighlights": [],
                    "avatarStatusChanges": [],
                    "nextTripSuggestions": [],
                    "temporaryMemoryPromotions": [],
                    "profileContext": state["context"]["profileContext"],
                },
                "model_call_logs": [],
            }

    monkeypatch.setattr(trip, "TravelMateGraph", ReviewOnlyGraph)

    response = client.post(
        "/api/trip/review",
        json={
            "userId": "review-only-user",
            "tripId": "review-only-trip",
            "completedTasks": [{"id": "task-a", "title": "完成夜景拍照", "status": "completed"}],
        },
    )

    assert response.status_code == 200
    assert response.json()["completedTasks"][0]["title"] == "完成夜景拍照"
