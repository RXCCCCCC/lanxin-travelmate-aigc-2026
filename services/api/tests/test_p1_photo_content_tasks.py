from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_photo_candidates_return_tags_scores_and_review_flag():
    create = client.post(
        "/api/photo/candidates",
        json={
            "id": "photo-night",
            "userId": "photo-user-a",
            "tripId": "trip-photo-a",
            "location": "洪崖洞",
            "score": 9.3,
            "description": "夜景灯光层次明显，适合做今日高光。",
            "tags": ["夜景", "山城", "高光照片"],
            "canAddToReview": True,
        },
    )
    assert create.status_code == 200

    response = client.get("/api/photo/candidates", params={"userId": "photo-user-a"})

    assert response.status_code == 200
    items = response.json()["items"]
    assert items
    assert items[0]["tags"]
    assert items[0]["score"] >= 8
    assert items[0]["canAddToReview"] is True


def test_photo_upload_metadata_does_not_persist_device_local_path():
    response = client.post(
        "/api/photo/upload-metadata",
        json={
            "userId": "photo-user-a",
            "filename": "night.jpg",
            "contentType": "image/jpeg",
            "localPath": "content://photo/night.jpg",
        },
    )

    assert response.status_code == 200
    assert response.json()["filename"] == "night.jpg"
    assert response.json()["localPath"] is None
    assert response.json()["privacy"]["localPathStored"] is False


def test_photo_copywriting_returns_multiple_share_formats():
    client.post(
        "/api/photo/candidates",
        json={
            "id": "photo-copy-a",
            "userId": "photo-copy-user",
            "location": "山城步道",
            "score": 8.8,
            "description": "街巷纵深感强。",
            "tags": ["街巷", "慢旅行"],
            "canAddToReview": True,
        },
    )
    response = client.post(
        "/api/photo/copywriting",
        json={
            "userId": "photo-copy-user",
            "photoIds": ["photo-copy-a"],
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
    assert payload["photoIds"] == ["photo-copy-a"]


def test_blind_box_tasks_return_five_demo_task_types():
    response = client.get("/api/trip/blind-box/tasks")

    assert response.status_code == 200
    tasks = response.json()["items"]
    assert len(tasks) >= 5
    assert {task["type"] for task in tasks} >= {"photo", "food", "route", "interaction", "story"}

def test_photo_candidates_do_not_return_device_local_uri():
    create = client.post(
        "/api/photo/candidates",
        json={
            "id": "photo-local-uri",
            "userId": "photo-user-private",
            "localUri": "content://media/external/images/42",
            "remoteUrl": "https://cdn.example.test/photo.jpg",
            "location": "Local Only",
            "score": 8.1,
            "description": "local uri should stay on device",
            "tags": ["privacy"],
        },
    )

    assert create.status_code == 200
    payload = create.json()
    assert payload["localUri"] is None
    assert payload["remoteUrl"] == "https://cdn.example.test/photo.jpg"
