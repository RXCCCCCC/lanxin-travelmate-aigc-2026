from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.state import create_initial_state
from app.agents.travelmate.nodes import common


class FakeRegistry:
    def call(self, name, payload):
        if name == 'weather_tool':
            return {
                'provider': 'amap',
                'fallback': False,
                'city': 'Chongqing',
                'condition': 'Rain',
                'temperatureC': 19,
                'warnings': ['heavy rain'],
                'travelHint': 'Prefer indoor stops.',
                'sourceTime': '2026-06-20 10:00:00',
            }
        if name == 'poi_tool':
            return {
                'provider': 'amap',
                'fallback': False,
                'items': [{
                    'name': 'Hongyadong',
                    'location': '106.588,29.563',
                    'openingHours': '10:00-23:00',
                    'rating': 4.8,
                }],
            }
        if name == 'route_tool':
            return {
                'provider': 'amap',
                'fallback': False,
                'mode': 'transit',
                'durationMinutes': 35,
                'distanceMeters': 7600,
                'transfers': [{'line': 'Metro Line 2'}],
                'costEstimate': {'transitCny': 4.0},
                'navigationLinks': [],
            }
        raise KeyError(name)


def test_trip_plan_includes_real_tool_context(monkeypatch):
    monkeypatch.setattr(common, 'build_tool_registry', lambda: FakeRegistry())
    state = create_initial_state(
        message='plan a relaxed Chongqing weekend with night views',
        session_id='tool-context-session',
    )

    result = TravelMateGraph().invoke(state)
    plan = result['trip_plan']

    assert plan['externalContext']['weather']['condition'] == 'Rain'
    assert plan['externalContext']['pois'][0]['location'] == '106.588,29.563'
    assert plan['externalContext']['route']['durationMinutes'] == 35
    assert any('10:00-23:00' in item for item in plan['profileMatches'])
    assert any('35' in item for item in plan['risks'])
