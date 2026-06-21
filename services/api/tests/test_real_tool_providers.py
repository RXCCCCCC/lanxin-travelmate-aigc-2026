from uuid import uuid4

from app.core.config import get_settings
from app.tools.registry import build_tool_registry


def test_tool_registry_returns_explicit_fallback_without_api_key(monkeypatch):
    monkeypatch.delenv("LANXIN_AMAP_API_KEY", raising=False)
    get_settings.cache_clear()

    registry = build_tool_registry()
    weather = registry.call("weather_tool", {"city": "杭州"})
    poi = registry.call("poi_tool", {"city": "杭州", "keyword": "夜景"})
    route = registry.call("route_tool", {"origin": "西湖", "destination": "灵隐寺"})

    assert weather["provider"] == "unconfigured"
    assert weather["fallback"] is True
    assert weather["sourceTime"] is None
    assert "真实天气 API 尚未配置" in weather["fallbackReason"]
    assert poi["items"] == []
    assert route["navigationLinks"][0]["url"].startswith("androidamap://")

    get_settings.cache_clear()


def test_amap_provider_parses_weather_poi_and_route_http_responses(monkeypatch):
    monkeypatch.setenv("LANXIN_AMAP_API_KEY", "test-key")
    monkeypatch.setenv("LANXIN_AMAP_BASE_URL", "https://restapi.amap.com")
    get_settings.cache_clear()

    class FakeResponse:
        def __init__(self, payload):
            self._payload = payload

        def raise_for_status(self):
            return None

        def json(self):
            return self._payload

    def fake_get(self, url, params=None):
        if url.endswith("/v3/weather/weatherInfo"):
            return FakeResponse({
                "status": "1",
                "lives": [{
                    "province": "浙江",
                    "city": "杭州市",
                    "weather": "小雨",
                    "temperature": "18",
                    "reporttime": "2026-06-19 10:00:00",
                }],
            })
        if url.endswith("/v5/place/text"):
            return FakeResponse({
                "status": "1",
                "pois": [{
                    "name": "西湖风景名胜区",
                    "type": "风景名胜",
                    "address": "杭州市西湖区",
                    "location": "120.143,30.235",
                    "business": {"rating": "4.8", "opentime_today": "全天开放"},
                }],
            })
        if url.endswith("/v3/direction/walking"):
            return FakeResponse({
                "status": "1",
                "route": {
                    "paths": [{
                        "distance": "1800",
                        "duration": "1500",
                        "steps": [{"instruction": "沿北山街向西步行"}],
                    }]
                },
            })
        raise AssertionError(f"unexpected url: {url}")

    import httpx

    monkeypatch.setattr(httpx.Client, "get", fake_get)

    registry = build_tool_registry()

    weather = registry.call("weather_tool", {"city": "杭州"})
    poi = registry.call("poi_tool", {"city": "杭州", "keyword": "西湖"})
    route = registry.call("route_tool", {
        "originLocation": "120.143,30.235",
        "destinationLocation": "120.100,30.240",
        "destination": "灵隐寺",
    })

    assert weather["provider"] == "amap"
    assert weather["fallback"] is False
    assert weather["condition"] == "小雨"
    assert weather["temperatureC"] == 18
    assert weather["sourceTime"] == "2026-06-19 10:00:00"

    assert poi["items"][0]["name"] == "西湖风景名胜区"
    assert poi["items"][0]["rating"] == 4.8
    assert route["distanceMeters"] == 1800
    assert route["durationMinutes"] == 25
    assert route["steps"] == ["沿北山街向西步行"]

    get_settings.cache_clear()

def test_graph_tool_trace_uses_real_registry_fallback_metadata(monkeypatch):
    monkeypatch.delenv("LANXIN_AMAP_API_KEY", raising=False)
    get_settings.cache_clear()

    from app.agents.travelmate.graph import TravelMateGraph
    from app.agents.travelmate.state import create_initial_state

    state = create_initial_state(
        message="周末想去杭州两天，喜欢夜景，不想太累",
        session_id="tool-fallback-session",
    )

    result = TravelMateGraph().invoke(state)
    weather_trace = next(item for item in result["tool_trace"] if item["tool"] == "weather_tool")

    assert weather_trace["mock"] is False
    assert weather_trace["provider"] == "unconfigured"
    assert weather_trace["fallback"] is True

    get_settings.cache_clear()

def test_amap_provider_retries_once_and_caches_successful_response(monkeypatch):
    monkeypatch.setenv("LANXIN_AMAP_API_KEY", "test-key")
    get_settings.cache_clear()

    class FakeResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {
                "status": "1",
                "lives": [{
                    "city": "杭州市",
                    "weather": "晴",
                    "temperature": "26",
                    "reporttime": "2026-06-19 11:00:00",
                }],
            }

    import httpx

    calls = {"count": 0}

    def flaky_get(self, url, params=None):
        calls["count"] += 1
        if calls["count"] == 1:
            raise httpx.ConnectTimeout("temporary timeout")
        return FakeResponse()

    monkeypatch.setattr(httpx.Client, "get", flaky_get)

    city = f"RetryCity-{uuid4().hex}"
    registry = build_tool_registry()
    first = registry.call("weather_tool", {"city": city})
    second = registry.call("weather_tool", {"city": city})

    assert first["provider"] == "amap"
    assert first["fallback"] is False
    assert first["retryCount"] == 1
    assert first["cacheHit"] is False
    assert second["city"] == first["city"]
    assert second["condition"] == first["condition"]
    assert second["cacheHit"] is True
    assert second["retryCount"] == 0
    assert calls["count"] == 2

    get_settings.cache_clear()

def test_amap_provider_opens_circuit_after_repeated_failures(monkeypatch):
    monkeypatch.setenv("LANXIN_AMAP_API_KEY", "test-key")
    get_settings.cache_clear()

    import httpx

    calls = {"count": 0}

    def failing_get(self, url, params=None):
        calls["count"] += 1
        raise httpx.ConnectTimeout("network down")

    monkeypatch.setattr(httpx.Client, "get", failing_get)

    registry = build_tool_registry()
    first = registry.call("weather_tool", {"city": "Hangzhou"})
    second = registry.call("weather_tool", {"city": "Hangzhou"})
    third = registry.call("weather_tool", {"city": "Hangzhou"})

    assert first["fallback"] is True
    assert first["retryCount"] == 2
    assert first["circuitOpen"] is False
    assert second["fallback"] is True
    assert second["circuitOpen"] is True
    assert third["fallback"] is True
    assert third["retryCount"] == 0
    assert third["circuitOpen"] is True
    assert third["errorType"] == "circuit_open"
    assert calls["count"] == 4

    get_settings.cache_clear()


def test_graph_tool_trace_exposes_error_metadata(monkeypatch):
    monkeypatch.delenv("LANXIN_AMAP_API_KEY", raising=False)
    get_settings.cache_clear()

    from app.agents.travelmate.graph import TravelMateGraph
    from app.agents.travelmate.state import create_initial_state

    state = create_initial_state(
        message="plan a slow weekend trip with night views",
        session_id="tool-trace-metadata-session",
    )

    result = TravelMateGraph().invoke(state)
    weather_trace = next(item for item in result["tool_trace"] if item["tool"] == "weather_tool")

    assert weather_trace["fallback"] is True
    assert weather_trace["fallbackReason"]
    assert weather_trace["sourceTime"] is None
    assert weather_trace["circuitOpen"] is False
    assert weather_trace["cacheHit"] is False
    assert weather_trace["retryCount"] == 0

    get_settings.cache_clear()

def test_amap_provider_uses_persistent_cache_across_registry_instances(monkeypatch):
    monkeypatch.setenv("LANXIN_AMAP_API_KEY", "test-key")
    get_settings.cache_clear()

    class FakeResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {
                "status": "1",
                "lives": [{
                    "city": "Hangzhou",
                    "weather": "Sunny",
                    "temperature": "27",
                    "reporttime": "2026-06-19 12:00:00",
                }],
            }

    import httpx

    calls = {"count": 0}

    def fake_get(self, url, params=None):
        calls["count"] += 1
        return FakeResponse()

    monkeypatch.setattr(httpx.Client, "get", fake_get)

    city = f"CacheCity-{uuid4().hex}"
    first_registry = build_tool_registry()
    first = first_registry.call("weather_tool", {"city": city})
    second_registry = build_tool_registry()
    second = second_registry.call("weather_tool", {"city": city})

    assert first["fallback"] is False
    assert first["cacheHit"] is False
    assert second["fallback"] is False
    assert second["cacheHit"] is True
    assert second["city"] == "Hangzhou"
    assert calls["count"] == 1

    get_settings.cache_clear()


def test_amap_provider_rate_limits_before_http(monkeypatch):
    monkeypatch.setenv("LANXIN_AMAP_API_KEY", "test-key")
    monkeypatch.setenv("LANXIN_TOOL_RATE_LIMIT_PER_MINUTE", "1")
    get_settings.cache_clear()

    class FakeResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {
                "status": "1",
                "pois": [],
            }

    import httpx

    calls = {"count": 0}

    def fake_get(self, url, params=None):
        calls["count"] += 1
        return FakeResponse()

    monkeypatch.setattr(httpx.Client, "get", fake_get)

    keyword_prefix = uuid4().hex
    registry = build_tool_registry()
    first = registry.call("poi_tool", {"city": "Hangzhou", "keyword": f"museum-{keyword_prefix}"})
    second = registry.call("poi_tool", {"city": "Hangzhou", "keyword": f"park-{keyword_prefix}"})

    assert first["fallback"] is False
    assert second["fallback"] is True
    assert second["errorType"] == "rate_limited"
    assert second["rateLimited"] is True
    assert second["retryAfterSeconds"] > 0
    assert calls["count"] == 1

    monkeypatch.delenv("LANXIN_TOOL_RATE_LIMIT_PER_MINUTE", raising=False)
    get_settings.cache_clear()


# ── 3.5 工具 Provider 边界场景 ──────────────────────────────────────────────


def test_amap_cached_result_skips_http(monkeypatch):
    """缓存命中时不再发起 HTTP 请求。"""
    monkeypatch.setenv("LANXIN_AMAP_API_KEY", "test-key")
    get_settings.cache_clear()

    class FakeResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {
                "status": "1",
                "pois": [{"name": "西湖", "type": "风景", "address": "杭州", "location": "120.14,30.23"}],
            }

    import httpx
    calls = {"count": 0}

    def counting_get(self, url, params=None):
        calls["count"] += 1
        return FakeResponse()

    monkeypatch.setattr(httpx.Client, "get", counting_get)

    keyword = f"CacheSkip-{uuid4().hex}"
    registry = build_tool_registry()
    registry.call("poi_tool", {"city": "Hangzhou", "keyword": keyword})
    registry.call("poi_tool", {"city": "Hangzhou", "keyword": keyword})
    assert calls["count"] == 1
    get_settings.cache_clear()


def test_amap_provider_mixed_partial_results(monkeypatch):
    """天气成功但 POI 失败时各自返回独立结果。"""
    monkeypatch.setenv("LANXIN_AMAP_API_KEY", "test-key")
    get_settings.cache_clear()

    class WeatherResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {
                "status": "1",
                "lives": [{"city": "杭州市", "weather": "多云", "temperature": "22",
                           "reporttime": "2026-06-19 10:00:00"}],
            }

    import httpx as _httpx

    def mixed_get(self, url, params=None):
        if "weather" in url:
            return WeatherResponse()
        raise _httpx.ConnectTimeout("poi timeout")

    monkeypatch.setattr(_httpx.Client, "get", mixed_get)
    registry = build_tool_registry()

    weather = registry.call("weather_tool", {"city": "Hangzhou"})
    poi = registry.call("poi_tool", {"city": "Hangzhou", "keyword": "西湖"})

    assert weather["fallback"] is False
    assert weather["condition"] == "多云"
    assert poi["fallback"] is True
    get_settings.cache_clear()
