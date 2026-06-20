from app.core.config import get_settings
from app.tools.external_providers import AmapToolProvider
from app.tools.registry import build_tool_registry


def test_amap_provider_supports_driving_transit_and_mixed_routes(monkeypatch):
    monkeypatch.setenv('LANXIN_AMAP_API_KEY', 'test-key')
    get_settings.cache_clear()

    requested_paths = []

    def fake_get(self, path, params, meta):
        requested_paths.append(path)
        if path == '/v3/direction/driving':
            return {
                'status': '1',
                'route': {
                    'taxi_cost': '28',
                    'paths': [{
                        'distance': '8400',
                        'duration': '1320',
                        'steps': [{'instruction': 'drive east'}, {'instruction': 'turn right'}],
                        'traffic_lights': '3',
                        'tmcs': [{'status': 'slow', 'distance': '1200'}],
                    }],
                },
            }
        if path == '/v3/direction/transit/integrated':
            return {
                'status': '1',
                'route': {'transits': [{
                    'distance': '7600',
                    'duration': '2100',
                    'cost': '4',
                    'walking_distance': '900',
                    'segments': [{'bus': {'buslines': [{'name': 'Metro Line 2'}]}}],
                }]},
            }
        raise AssertionError(f'unexpected path: {path}')

    monkeypatch.setattr(AmapToolProvider, '_get', fake_get)
    registry = build_tool_registry()
    payload = {
        'originLocation': '106.575,29.557',
        'destinationLocation': '106.588,29.563',
        'destination': 'Hongyadong',
        'city': 'Chongqing',
    }

    driving = registry.call('route_tool', {**payload, 'mode': 'driving'})
    transit = registry.call('route_tool', {**payload, 'mode': 'transit'})
    mixed = registry.call('route_tool', {**payload, 'mode': 'mixed'})

    assert driving['mode'] == 'driving'
    assert driving['distanceMeters'] == 8400
    assert driving['durationMinutes'] == 22
    assert driving['costEstimate']['taxiCny'] == 28.0
    assert driving['steps'] == ['drive east', 'turn right']
    assert driving['trafficLights'] == 3
    assert driving['congestionSegments'][0]['status'] == 'slow'
    assert driving['congestionSegments'][0]['distanceMeters'] == 1200
    assert transit['mode'] == 'transit'
    assert transit['durationMinutes'] == 35
    assert transit['costEstimate']['transitCny'] == 4.0
    assert transit['transfers'][0]['line'] == 'Metro Line 2'
    assert transit['walkingDistanceMeters'] == 900
    assert mixed['mode'] == 'mixed'
    assert [item['mode'] for item in mixed['alternatives']] == ['driving', 'transit']
    assert '/v3/direction/driving' in requested_paths
    assert '/v3/direction/transit/integrated' in requested_paths

    get_settings.cache_clear()
