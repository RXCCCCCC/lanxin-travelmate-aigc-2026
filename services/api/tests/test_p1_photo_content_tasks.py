from uuid import uuid4

from fastapi.testclient import TestClient

from app.api.routes import photo
from app.main import app


client = TestClient(app)

PNG_1X1_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="


def _guest_headers(device_id: str) -> tuple[str, dict[str, str]]:
    response = client.post("/api/auth/guest", json={"deviceId": device_id, "displayName": "Photo Test Guest"})
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_photo_candidates_return_tags_scores_and_review_flag():
    _user_id, headers = _guest_headers(f"photo-tags-{uuid4().hex}")
    create = client.post(
        "/api/photo/candidates",
        headers=headers,
        json={
            "id": "photo-night",
            "userId": "guest",
            "tripId": "trip-photo-a",
            "location": "洪崖洞",
            "score": 9.3,
            "description": "夜景灯光层次明显，适合做今日高光。",
            "tags": ["夜景", "山城", "高光照片"],
            "canAddToReview": True,
        },
    )
    assert create.status_code == 200

    response = client.get("/api/photo/candidates", headers=headers)

    assert response.status_code == 200
    items = response.json()["items"]
    assert items
    assert items[0]["tags"]
    assert items[0]["score"] >= 8
    assert items[0]["canAddToReview"] is True


def test_photo_upload_metadata_does_not_persist_device_local_path():
    _user_id, headers = _guest_headers(f"photo-metadata-{uuid4().hex}")
    response = client.post(
        "/api/photo/upload-metadata",
        headers=headers,
        json={
            "userId": "guest",
            "filename": "night.jpg",
            "contentType": "image/jpeg",
            "localPath": "content://photo/night.jpg",
        },
    )

    assert response.status_code == 200
    assert response.json()["filename"] == "night.jpg"
    assert response.json()["localPath"] is None
    assert response.json()["privacy"]["localPathStored"] is False


def test_photo_analyze_uses_preview_bytes_for_chinese_analysis():
    _user_id, headers = _guest_headers(f"photo-analyze-{uuid4().hex}")
    response = client.post(
        "/api/photo/analyze",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": "photo-analyze-trip",
            "filename": "preview.png",
            "contentType": "image/png",
            "imageBase64": PNG_1X1_BASE64,
            "source": "camera",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["width"] == 1
    assert payload["height"] == 1
    assert payload["orientation"] == "方图"
    assert payload["score"] > 0
    assert "旅拍" in payload["description"]
    assert "复盘" in payload["reviewSuggestion"]
    assert {"真实旅拍", "旅行场景"} <= set(payload["tags"])
    for technical_word in ["尺寸", "文件", "KB", "像素", "1x1"]:
        assert technical_word not in payload["description"]
    assert "待分析" not in payload["tags"]
    assert all("imageBase64" not in str(value) for value in payload.values())


def test_photo_copywriting_returns_multiple_share_formats():
    _user_id, headers = _guest_headers(f"photo-copy-{uuid4().hex}")
    client.post(
        "/api/photo/candidates",
        headers=headers,
        json={
            "id": "photo-copy-a",
            "userId": "guest",
            "location": "山城步道",
            "score": 8.8,
            "description": "街巷纵深感强。",
            "tags": ["街巷", "慢旅行"],
            "canAddToReview": True,
        },
    )
    response = client.post(
        "/api/photo/copywriting",
        headers=headers,
        json={
            "userId": "guest",
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


def test_photo_copywriting_uses_valid_model_provider_output(monkeypatch):
    _user_id, headers = _guest_headers(f"photo-model-{uuid4().hex}")

    class CopywritingProvider:
        name = "copywriting-provider"

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            assert scenario == "photo_copywriting"
            return {
                "photoCopywriting": {
                    "photoIds": ["photo-model-a"],
                    "persona": "quiet guide",
                    "style": "warm",
                    "moments": "Model moments copy",
                    "xiaohongshu": "Model XHS copy",
                    "diary": "Model diary copy",
                    "vlogNarration": "Model vlog copy",
                    "reviewSuggestion": "Model review suggestion",
                }
            }

    monkeypatch.setattr(photo, "build_model_provider", lambda settings: CopywritingProvider())
    client.post(
        "/api/photo/candidates",
        headers=headers,
        json={
            "id": "photo-model-a",
            "userId": "guest",
            "location": "River Walk",
            "score": 9.1,
            "description": "real model candidate",
            "tags": ["river"],
        },
    )

    response = client.post(
        "/api/photo/copywriting",
        headers=headers,
        json={"userId": "guest", "photoIds": ["photo-model-a"]},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["moments"] == "Model moments copy"
    assert payload["provider"] == "copywriting-provider"
    assert payload["fallback"] is False


def test_photo_copywriting_normalizes_real_provider_aliases(monkeypatch):
    _user_id, headers = _guest_headers(f"photo-alias-{uuid4().hex}")

    class AliasCopywritingProvider:
        name = "alias-copywriting-provider"

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            assert scenario == "photo_copywriting"
            return {
                "wechat": "Alias moments copy",
                "xhs": "Alias XHS copy",
                "travelDiary": "Alias diary copy",
                "vlog": "Alias vlog copy",
            }

    monkeypatch.setattr(photo, "build_model_provider", lambda settings: AliasCopywritingProvider())
    client.post(
        "/api/photo/candidates",
        headers=headers,
        json={
            "id": "photo-alias-a",
            "userId": "guest",
            "location": "West Lake",
            "score": 8.9,
            "description": "alias model candidate",
            "tags": ["night"],
        },
    )

    response = client.post(
        "/api/photo/copywriting",
        headers=headers,
        json={
            "userId": "guest",
            "photoIds": ["photo-alias-a"],
            "persona": "quiet guide",
            "style": "warm",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["moments"] == "Alias moments copy"
    assert payload["xiaohongshu"] == "Alias XHS copy"
    assert payload["diary"] == "Alias diary copy"
    assert payload["vlogNarration"] == "Alias vlog copy"
    assert payload["persona"] == "quiet guide"
    assert payload["style"] == "warm"
    assert payload["fallback"] is False


def test_photo_copywriting_falls_back_when_model_schema_is_invalid(monkeypatch):
    _user_id, headers = _guest_headers(f"photo-invalid-{uuid4().hex}")

    class InvalidCopywritingProvider:
        name = "invalid-copywriting-provider"

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            return {"photoCopywriting": {"photoIds": ["photo-invalid-a"], "moments": "missing fields"}}

    monkeypatch.setattr(photo, "build_model_provider", lambda settings: InvalidCopywritingProvider())
    client.post(
        "/api/photo/candidates",
        headers=headers,
        json={
            "id": "photo-invalid-a",
            "userId": "guest",
            "location": "Mountain Street",
            "score": 8.7,
            "description": "invalid model candidate",
            "tags": ["street"],
        },
    )

    response = client.post(
        "/api/photo/copywriting",
        headers=headers,
        json={"userId": "guest", "photoIds": ["photo-invalid-a"]},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["fallback"] is True
    assert payload["provider"] == "invalid-copywriting-provider"
    assert payload["errorType"] == "schema_validation"
    assert payload["moments"]


def test_blind_box_tasks_return_five_demo_task_types():
    response = client.get("/api/trip/blind-box/tasks")

    assert response.status_code == 200
    tasks = response.json()["items"]
    assert len(tasks) >= 5
    assert {task["type"] for task in tasks} >= {"photo", "food", "route", "interaction", "story"}

def test_photo_candidates_do_not_return_device_local_uri():
    _user_id, headers = _guest_headers(f"photo-local-uri-{uuid4().hex}")
    create = client.post(
        "/api/photo/candidates",
        headers=headers,
        json={
            "id": "photo-local-uri",
            "userId": "guest",
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
