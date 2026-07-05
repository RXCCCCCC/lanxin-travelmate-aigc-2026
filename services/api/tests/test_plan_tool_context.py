from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.nodes import real_nodes
from app.agents.travelmate.state import create_initial_state


class FakeRegistry:
    def __init__(self):
        self.calls = []

    def call(self, name, payload):
        self.calls.append((name, payload))
        if name == "weather_tool":
            return {
                "provider": "amap",
                "fallback": False,
                "city": "Chongqing",
                "condition": "Rain",
                "temperatureC": 19,
                "warnings": ["heavy rain"],
                "travelHint": "Prefer indoor stops.",
                "sourceTime": "2026-06-20 10:00:00",
            }
        if name == "poi_tool":
            return {
                "provider": "amap",
                "fallback": False,
                "items": [
                    {
                        "name": "Hongyadong",
                        "location": "106.588,29.563",
                        "openingHours": "10:00-23:00",
                        "rating": 4.8,
                    }
                ],
            }
        if name == "route_tool":
            return {
                "provider": "amap",
                "fallback": False,
                "mode": "transit",
                "durationMinutes": 35,
                "distanceMeters": 7600,
                "transfers": [{"line": "Metro Line 2"}],
                "costEstimate": {"transitCny": 4.0},
                "navigationLinks": [],
            }
        raise KeyError(name)


def test_trip_plan_includes_real_tool_context(monkeypatch):
    registry = FakeRegistry()
    monkeypatch.setattr(real_nodes, "build_tool_registry", lambda: registry)
    state = create_initial_state(
        message="plan a relaxed Chongqing weekend with night views",
        session_id="tool-context-session",
        context={
            "planningInputs": {
                "destination": "Chongqing",
                "originCoordinate": {"latitude": 29.557, "longitude": 106.575},
                "destinationCoordinate": {"latitude": 29.563, "longitude": 106.588},
                "transportMode": "transit",
            }
        },
    )

    result = TravelMateGraph().invoke(state)
    plan = result["trip_plan"]

    assert plan["externalContext"]["weather"]["condition"] == "Rain"
    assert plan["externalContext"]["pois"][0]["location"] == "106.588,29.563"
    assert plan["externalContext"]["route"]["durationMinutes"] == 35
    route_payload = next(payload for name, payload in registry.calls if name == "route_tool")
    assert route_payload["originLocation"] == "106.575,29.557"
    assert route_payload["destinationLocation"] == "106.588,29.563"
    assert route_payload["mode"] == "transit"
    assert any("10:00-23:00" in item for item in plan["profileMatches"])
    assert any("35" in item for item in plan["risks"])


def test_trip_plan_tools_keep_city_when_message_contains_date_range(monkeypatch):
    registry = FakeRegistry()
    monkeypatch.setattr(real_nodes, "build_tool_registry", lambda: registry)
    state = create_initial_state(
        message="广州行程，七月四号到八号，轻松游",
        session_id="tool-date-city-session",
    )

    TravelMateGraph().invoke(state)

    weather_payload = next(payload for name, payload in registry.calls if name == "weather_tool")
    poi_payload = next(payload for name, payload in registry.calls if name == "poi_tool")
    assert weather_payload["city"] == "广州"
    assert poi_payload["city"] == "广州"
