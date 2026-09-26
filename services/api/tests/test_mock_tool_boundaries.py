import json

from app.tools.registry import build_mock_tool_registry


FIXED_FIXTURE_MARKERS = ["重庆", "洪崖洞", "解放碑", "南山一棵树", "山城步道"]


def test_mock_tools_do_not_inject_fixed_city_fixtures_by_default():
    registry = build_mock_tool_registry()
    payloads = [
        registry.call("weather_tool", {}),
        registry.call("poi_tool", {}),
        registry.call("route_tool", {}),
        registry.call("navigation_link_tool", {}),
        registry.call("asr_tool", {}),
        registry.call("tts_tool", {}),
        registry.call("photo_analyze_tool", {}),
    ]
    text = json.dumps(payloads, ensure_ascii=False)

    for marker in FIXED_FIXTURE_MARKERS:
        assert marker not in text


def test_mock_route_and_navigation_tools_are_input_driven():
    registry = build_mock_tool_registry()
    route = registry.call(
        "route_tool",
        {"origin": "真实起点", "destination": "真实终点", "city": "真实城市"},
    )

    assert route["route"] == ["真实起点", "真实终点"]
    assert route["navigationLinks"][0]["url"].endswith("dname=真实终点&dev=0&t=0")