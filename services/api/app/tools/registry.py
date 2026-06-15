from collections.abc import Callable
from typing import Any

from app.tools import mock_tools


ToolHandler = Callable[[dict[str, Any]], dict[str, Any]]


class ToolRegistry:
    def __init__(self, tools: dict[str, ToolHandler]) -> None:
        self._tools = tools

    def tool_names(self) -> list[str]:
        return list(self._tools.keys())

    def call(self, name: str, payload: dict[str, Any]) -> dict[str, Any]:
        if name not in self._tools:
            raise KeyError(f"Tool not registered: {name}")
        return self._tools[name](payload)


def build_mock_tool_registry() -> ToolRegistry:
    return ToolRegistry({
        "weather_tool": mock_tools.weather_tool,
        "poi_tool": mock_tools.poi_tool,
        "route_tool": mock_tools.route_tool,
        "navigation_link_tool": mock_tools.navigation_link_tool,
        "asr_tool": mock_tools.asr_tool,
        "tts_tool": mock_tools.tts_tool,
        "photo_analyze_tool": mock_tools.photo_analyze_tool,
    })
