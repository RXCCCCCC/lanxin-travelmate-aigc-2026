from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def _guest_headers(device_id: str) -> tuple[str, dict[str, str]]:
    response = client.post("/api/auth/guest", json={"deviceId": device_id, "displayName": "Trip Test Guest"})
    assert response.status_code == 200
    payload = response.json()
    return payload["userId"], {"Authorization": f"Bearer {payload['accessToken']}"}


def test_trip_plan_persists_real_inputs_and_replan_reason():
    user_id, headers = _guest_headers(f"plan-user-{uuid4().hex}")
    trip_id = f"plan-trip-{uuid4().hex}"

    first = client.post(
        "/api/trip/plan",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": trip_id,
            "message": "Plan Hangzhou with my family, relaxed pace.",
            "destination": "Hangzhou",
            "originCoordinate": {"latitude": 30.245, "longitude": 120.165},
            "destinationCoordinate": {"latitude": 30.259, "longitude": 120.130},
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
    assert plan["planningInputs"]["originCoordinate"] == {"latitude": 30.245, "longitude": 120.165}
    assert plan["planningInputs"]["destinationCoordinate"] == {"latitude": 30.259, "longitude": 120.130}
    assert plan["planningInputs"]["dateRange"] == {"startDate": "2026-07-01", "endDate": "2026-07-03"}
    assert plan["planningInputs"]["budget"] == "medium"
    assert plan["planningInputs"]["companions"] == ["mother", "child"]
    assert plan["planningInputs"]["preferences"] == ["night view", "less walking"]
    explanation_text = "\n".join(plan["profileMatches"] + plan["risks"])
    assert "medium" not in explanation_text
    assert "transit" not in explanation_text
    assert "night view" not in explanation_text
    assert "less walking" not in explanation_text
    assert "中等预算" in explanation_text
    assert "公共交通" in explanation_text
    assert "夜景" in explanation_text
    assert "少走路" in explanation_text

    second = client.post(
        "/api/trip/plan",
        headers=headers,
        json={
            "userId": "guest",
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
    assert not any("weather_risk" in item for item in replanned["risks"])
    assert any("天气风险" in item for item in replanned["risks"])

    current = client.get("/api/trip/current", headers=headers, params={"userId": user_id})
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
    _user_id, headers = _guest_headers(f"plan-group-user-{uuid4().hex}")
    trip_id = f"plan-group-trip-{uuid4().hex}"

    response = client.post(
        "/api/trip/plan",
        headers=headers,
        json={
            "userId": "guest",
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


def test_direct_trip_plan_uses_plan_only_graph(monkeypatch):
    from app.api.routes import trip
    _user_id, headers = _guest_headers(f"plan-only-user-{uuid4().hex}")

    class PlanOnlyGraph:
        def invoke(self, state):
            raise AssertionError("direct trip plan route should not run the full agent graph")

        def invoke_plan_only(self, state):
            return {
                **state,
                "trip_plan": {
                    "title": "杭州轻松行程",
                    "destination": "杭州",
                    "summary": "按轻松节奏安排西湖和夜景。",
                    "profileMatches": [],
                    "risks": [],
                    "alternatives": [],
                },
                "model_call_logs": [],
            }

    monkeypatch.setattr(trip, "TravelMateGraph", PlanOnlyGraph)

    response = client.post(
        "/api/trip/plan",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": f"plan-only-trip-{uuid4().hex}",
            "message": "请规划杭州两天轻松路线",
            "destination": "杭州",
        },
    )

    assert response.status_code == 200
    assert response.json()["title"] == "杭州轻松行程"


def test_trip_plan_input_explanations_are_chinese():
    _user_id, headers = _guest_headers(f"plan-cn-user-{uuid4().hex}")
    response = client.post(
        "/api/trip/plan",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": f"plan-cn-trip-{uuid4().hex}",
            "message": "请规划杭州两天轻松路线",
            "destination": "杭州",
            "budget": "中等预算",
            "companions": ["妈妈"],
            "preferences": ["夜景", "少走路"],
            "transportMode": "公共交通",
            "replanReason": "天气变化",
            "groupCoordination": {
                "coordinationId": "group-cn",
                "compromisePlan": {"pace": "慢节奏", "budget": "中等预算"},
            },
        },
    )

    assert response.status_code == 200
    text = "\n".join(response.json()["profileMatches"] + response.json()["risks"])
    assert "Budget preference considered" not in text
    assert "Transport mode considered" not in text
    assert "Companion needs considered" not in text
    assert "Current trip preferences considered" not in text
    assert "Replan reason applied" not in text
    assert "Group coordination" not in text
    assert "已参考预算偏好：中等预算。" in text


def test_trip_plan_risks_do_not_expose_route_tool_failures(monkeypatch):
    from app.api.routes import trip
    _user_id, headers = _guest_headers(f"plan-risk-user-{uuid4().hex}")

    class PlanOnlyGraph:
        def invoke_plan_only(self, state):
            return {
                **state,
                "trip_plan": {
                    "title": "广州一日路线",
                    "destination": "广州",
                    "summary": "按轻松节奏安排广州城市游。",
                    "profileMatches": [],
                    "risks": [
                        "路线规划工具因为缺少坐标信息无法生成详细步行路线，需手动规划点位间交通"
                    ],
                    "alternatives": [],
                },
                "model_call_logs": [],
            }

    monkeypatch.setattr(trip, "TravelMateGraph", PlanOnlyGraph)

    response = client.post(
        "/api/trip/plan",
        headers=headers,
        json={
            "userId": "guest",
            "tripId": f"plan-risk-trip-{uuid4().hex}",
            "message": "请规划广州一日路线",
            "destination": "广州",
        },
    )

    assert response.status_code == 200
    text = "\n".join(response.json()["risks"])
    assert "路线规划工具" not in text
    assert "缺少坐标" not in text
    assert "手动规划" not in text
    assert "虚手动" not in text
    assert "地图" in text
    assert "步行" in text or "换乘" in text
