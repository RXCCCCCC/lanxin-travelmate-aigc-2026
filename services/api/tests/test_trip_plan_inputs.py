from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_trip_plan_persists_real_inputs_and_replan_reason():
    user_id = f"plan-user-{uuid4().hex}"
    trip_id = f"plan-trip-{uuid4().hex}"

    first = client.post(
        "/api/trip/plan",
        json={
            "userId": user_id,
            "tripId": trip_id,
            "message": "Plan Hangzhou with my family, relaxed pace.",
            "destination": "Hangzhou",
            "startDate": "2026-07-01",
            "endDate": "2026-07-03",
            "budget": "medium",
            "companions": ["mother", "child"],
            "preferences": ["night view", "less walking"],
            "transportMode": "transit",
            "tripStyle": "family_relaxed",
        },
    )

    assert first.status_code == 200
    plan = first.json()
    assert plan["planningInputs"]["destination"] == "Hangzhou"
    assert plan["planningInputs"]["dateRange"] == {"startDate": "2026-07-01", "endDate": "2026-07-03"}
    assert plan["planningInputs"]["budget"] == "medium"
    assert plan["planningInputs"]["companions"] == ["mother", "child"]
    assert plan["planningInputs"]["preferences"] == ["night view", "less walking"]
    assert any("medium" in item for item in plan["profileMatches"])
    assert any("transit" in item for item in plan["profileMatches"])

    second = client.post(
        "/api/trip/plan",
        json={
            "userId": user_id,
            "tripId": trip_id,
            "message": "Replan: rain is coming, reduce outdoor walking.",
            "destination": "Hangzhou",
            "startDate": "2026-07-01",
            "endDate": "2026-07-03",
            "budget": "medium",
            "companions": ["mother", "child"],
            "preferences": ["indoor", "less walking"],
            "transportMode": "transit",
            "tripStyle": "family_relaxed",
            "replanReason": "weather_risk",
        },
    )

    assert second.status_code == 200
    replanned = second.json()
    assert replanned["planningInputs"]["replanReason"] == "weather_risk"
    assert any("weather_risk" in item for item in replanned["risks"])

    current = client.get("/api/trip/current", params={"userId": user_id})
    assert current.status_code == 200
    current_payload = current.json()
    assert current_payload["tripId"] == trip_id
    assert current_payload["destination"] == "Hangzhou"
    assert current_payload["startDate"] == "2026-07-01"
    assert current_payload["endDate"] == "2026-07-03"
    assert current_payload["budget"] == "medium"
    assert current_payload["companions"] == ["mother", "child"]
    assert current_payload["tripStyle"] == "family_relaxed"
    assert current_payload["plan"]["planningInputs"]["preferences"] == ["indoor", "less walking"]


def test_trip_plan_keeps_group_coordination_context_in_planning_inputs():
    user_id = f"plan-group-user-{uuid4().hex}"
    trip_id = f"plan-group-trip-{uuid4().hex}"

    response = client.post(
        "/api/trip/plan",
        json={
            "userId": user_id,
            "tripId": trip_id,
            "message": "Plan a group trip with compromise context.",
            "destination": "Chongqing",
            "groupCoordination": {
                "coordinationId": "group-test",
                "conflicts": [{"type": "pace", "title": "pace conflict"}],
                "compromisePlan": {
                    "pace": "balanced_slow",
                    "budget": "low_first",
                    "sharedInterests": ["night view"],
                },
                "privacySummary": {"publicRule": "show aggregate only"},
            },
        },
    )

    assert response.status_code == 200
    plan = response.json()
    coordination = plan["planningInputs"]["groupCoordination"]
    assert coordination["coordinationId"] == "group-test"
    assert coordination["compromisePlan"]["pace"] == "balanced_slow"
    assert coordination["conflicts"][0]["type"] == "pace"
