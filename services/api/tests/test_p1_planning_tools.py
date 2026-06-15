from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.state import create_initial_state
from app.tools.registry import build_mock_tool_registry


def test_graph_returns_memory_conflicts_and_alternative_plans():
    state = create_initial_state(
        message="我以前喜欢特种兵路线，但这次周末重庆两天想慢一点，也想看夜景",
        session_id="demo-session",
        context={
            "confirmedMemories": [
                {
                    "id": "mem-fast-travel",
                    "title": "喜欢特种兵路线",
                    "content": "用户过去喜欢一天打卡很多景点。",
                    "scope": "longTerm",
                }
            ]
        },
    )

    result = TravelMateGraph().invoke(state)

    assert result["memory_conflicts"]
    assert result["memory_conflicts"][0]["currentPreference"] == "本次旅行想轻松一点"
    assert any(item["type"] == "memoryConflict" for item in result["sync_suggestions"])
    assert result["trip_plan"]["alternatives"]
    assert result["trip_plan"]["navigationLinks"]


def test_travel_tools_return_provider_and_fallback_metadata():
    registry = build_mock_tool_registry()

    weather = registry.call("weather_tool", {"city": "重庆"})
    poi = registry.call("poi_tool", {"city": "重庆", "keyword": "夜景"})
    route = registry.call("route_tool", {"city": "重庆", "pace": "轻松"})

    assert weather["provider"] in {"mock", "amap"}
    assert weather["fallback"] is True
    assert poi["provider"] in {"mock", "amap"}
    assert route["navigationLinks"][0]["url"].startswith("androidamap://")
