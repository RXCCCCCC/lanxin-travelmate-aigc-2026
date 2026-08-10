from app.agents.travelmate.nodes import real_nodes
from app.agents.travelmate.state import create_initial_state
from app.agents.travelmate.tool_planning import build_constrained_tool_plan


def _tools(result: dict[str, object]) -> list[str]:
    return [str(item["tool"]) for item in result["steps"]]


def test_weather_question_only_plans_weather():
    state = create_initial_state(message="杭州明天天气怎么样")

    result = build_constrained_tool_plan(state)

    assert _tools(result) == ["weather_tool"]
    assert result["fallback"] is True
    assert result["steps"][0]["input"]["city"] == "杭州"


def test_poi_recommendation_plans_weather_and_poi_without_route():
    state = create_initial_state(message="推荐广州夜景和附近景点")

    result = build_constrained_tool_plan(state)

    assert _tools(result) == ["weather_tool", "poi_tool"]
    assert "route_tool" not in _tools(result)


def test_route_is_planned_only_when_coordinates_are_available():
    state = create_initial_state(
        message="从当前位置规划到西湖",
        context={
            "planningInputs": {
                "destination": "杭州",
                "originCoordinate": {"latitude": 30.25, "longitude": 120.16},
                "destinationCoordinate": {"latitude": 30.24, "longitude": 120.15},
                "transportMode": "walking",
            }
        },
    )

    result = build_constrained_tool_plan(state)

    assert _tools(result) == ["weather_tool", "poi_tool", "route_tool"]
    route = result["steps"][2]
    assert route["input"]["originLocation"] == "120.16,30.25"
    assert route["input"]["destinationLocation"] == "120.15,30.24"


def test_invalid_model_plan_falls_back_to_allowlisted_plan(monkeypatch):
    class InvalidProvider:
        name = "invalid-provider"

        def generate_json(self, **_: object) -> dict[str, object]:
            return {
                "toolPlan": {
                    "goal": "bad",
                    "steps": [{"stepId": "bad", "tool": "shell", "reason": "bad", "input": {}}],
                    "maxSteps": 4,
                    "plannerProvider": "invalid-provider",
                    "fallback": False,
                }
            }

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: InvalidProvider())
    state = create_initial_state(message="推荐广州夜景")

    result = build_constrained_tool_plan(state)

    assert result["fallback"] is True
    assert all(item["tool"] in {"weather_tool", "poi_tool", "route_tool"} for item in result["steps"])
