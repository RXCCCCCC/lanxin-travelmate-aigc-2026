from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_photo_candidates_return_tags_scores_and_review_flag():
    response = client.get("/api/photo/candidates")

    assert response.status_code == 200
    items = response.json()["items"]
    assert items
    assert items[0]["tags"]
    assert items[0]["score"] >= 8
    assert items[0]["canAddToReview"] is True


def test_photo_copywriting_returns_multiple_share_formats():
    response = client.post(
        "/api/photo/copywriting",
        json={
            "photoIds": ["photo-night"],
            "persona": "活泼向导",
            "style": "轻松",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert "朋友圈" in payload["moments"]
    assert "小红书" in payload["xiaohongshu"]
    assert payload["diary"]
    assert payload["vlogNarration"]


def test_blind_box_tasks_return_five_demo_task_types():
    response = client.get("/api/trip/blind-box/tasks")

    assert response.status_code == 200
    tasks = response.json()["items"]
    assert len(tasks) >= 5
    assert {task["type"] for task in tasks} >= {"photo", "food", "route", "interaction", "story"}
