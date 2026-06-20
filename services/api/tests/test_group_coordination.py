from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_group_coordination_persists_conflicts_compromise_and_privacy_summary():
    trip_id = "group-trip-a"
    response = client.post(
        "/api/trip/group/coordinate",
        json={
            "userId": "organizer-a",
            "tripId": trip_id,
            "destination": "重庆",
            "members": [
                {
                    "memberId": "member-a",
                    "displayName": "小林",
                    "preferences": {
                        "pace": "slow",
                        "dietary": ["不吃香菜"],
                        "interests": ["夜景"],
                        "budget": "medium",
                    },
                    "sensitivePreferences": {"health": "脚踝不适，不能久走"},
                },
                {
                    "memberId": "member-b",
                    "displayName": "阿远",
                    "preferences": {
                        "pace": "packed",
                        "dietary": ["想吃火锅"],
                        "interests": ["夜景", "山城步道"],
                        "budget": "low",
                    },
                    "sensitivePreferences": {"relationship": "不想公开同行关系"},
                },
            ],
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["coordinationId"].startswith("group-")
    assert payload["tripId"] == trip_id
    assert len(payload["members"]) == 2
    assert payload["conflicts"]
    assert any(conflict["type"] == "pace" for conflict in payload["conflicts"])
    assert any(conflict["type"] == "budget" for conflict in payload["conflicts"])
    assert payload["compromisePlan"]["pace"] == "balanced_slow"
    assert "夜景" in payload["compromisePlan"]["sharedInterests"]
    assert payload["privacySummary"]["sensitiveMemberDetailsHidden"] is True
    assert "脚踝不适" not in str(payload["privacySummary"])

    read_back = client.get("/api/trip/group/coordination", params={"tripId": trip_id})

    assert read_back.status_code == 200
    saved = read_back.json()
    assert saved["coordinationId"] == payload["coordinationId"]
    assert saved["compromisePlan"]["pace"] == "balanced_slow"


def test_group_coordination_requires_at_least_two_members():
    response = client.post(
        "/api/trip/group/coordinate",
        json={
            "tripId": "group-trip-invalid",
            "members": [
                {
                    "memberId": "member-a",
                    "displayName": "小林",
                    "preferences": {"pace": "slow"},
                }
            ],
        },
    )

    assert response.status_code == 422