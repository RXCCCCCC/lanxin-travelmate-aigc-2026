from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_trip_route_points_are_persisted_readable_and_used_by_review():
    user_id = "route-user-a"
    trip_id = "route-trip-a"
    points = [
        {"label": "真实起点", "latitude": 29.56301, "longitude": 106.55156, "source": "device", "recordedAt": "2026-06-20T09:00:00+08:00"},
        {"label": "真实中途点", "latitude": 29.55890, "longitude": 106.54810, "source": "device", "recordedAt": "2026-06-20T10:10:00+08:00"},
        {"label": "真实终点", "latitude": 29.55220, "longitude": 106.54130, "source": "device", "recordedAt": "2026-06-20T11:20:00+08:00"},
    ]

    created = client.post(
        "/api/trip/route-points",
        json={"userId": user_id, "tripId": trip_id, "points": points},
    )

    assert created.status_code == 200
    created_payload = created.json()
    assert created_payload["saved"] == 3
    assert created_payload["route"] == "真实起点 → 真实中途点 → 真实终点"
    assert created_payload["points"][0]["source"] == "device"

    read_back = client.get("/api/trip/route-points", params={"userId": user_id, "tripId": trip_id})

    assert read_back.status_code == 200
    payload = read_back.json()
    assert len(payload["points"]) == 3
    assert payload["route"] == "真实起点 → 真实中途点 → 真实终点"

    review = client.post(
        "/api/trip/review",
        json={"userId": user_id, "tripId": trip_id, "message": "生成真实路线复盘"},
    )

    assert review.status_code == 200
    assert review.json()["route"] == "真实起点 → 真实中途点 → 真实终点"