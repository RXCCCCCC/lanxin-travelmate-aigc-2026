from app.tools.registry import build_mock_tool_registry


def test_mock_tool_registry_exposes_p0_tools():
    registry = build_mock_tool_registry()

    assert set(registry.tool_names()) == {
        "weather_tool",
        "poi_tool",
        "route_tool",
        "navigation_link_tool",
        "asr_tool",
        "tts_tool",
        "photo_analyze_tool",
    }
    assert registry.call("weather_tool", {"city": "重庆"})["condition"] == "多云"
