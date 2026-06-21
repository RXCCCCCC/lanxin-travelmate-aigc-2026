"""模型 Provider 测试：工厂、图 fallback、JSON 解析、脱敏和错误路径。"""

import json
from unittest.mock import Mock, patch

import httpx
import pytest

from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.state import create_initial_state
from app.core.config import Settings
from app.services.model_providers.call_log import ModelCallLogger
from app.services.model_providers.factory import build_model_provider
from app.services.model_providers.mock import MockModelProvider
from app.services.model_providers.openai_compatible import OpenAICompatibleProvider


def test_model_provider_factory_defaults_to_mock():
    provider = build_model_provider(Settings())

    assert isinstance(provider, MockModelProvider)


def test_graph_records_model_provider_fallback_when_real_provider_unconfigured(monkeypatch):
    monkeypatch.setenv("LANXIN_MODEL_PROVIDER", "lanxin")
    from app.core.config import get_settings

    get_settings.cache_clear()
    state = create_initial_state(message="帮我规划一次轻松旅行")

    result = TravelMateGraph().invoke(state)

    get_settings.cache_clear()
    model_trace = [item for item in result["tool_trace"] if item["tool"] == "model_provider"]
    assert model_trace
    assert model_trace[-1]["provider"] == "lanxin"
    assert model_trace[-1]["fallback"] is True
    assert "缺少" in model_trace[-1]["error"]
    assert result["trip_plan"]["title"]


def test_openai_compatible_provider_parses_json_response(monkeypatch):
    def fake_post(self, url, headers, json):
        return httpx.Response(
            200,
            request=httpx.Request("POST", "https://example.test/v1/chat/completions"),
            json={
                "choices": [
                    {
                        "message": {
                            "content": "{\"replyText\": \"真实模型响应\", \"fallback\": false}"
                        }
                    }
                ]
            },
        )

    monkeypatch.setattr(httpx.Client, "post", fake_post)
    provider = OpenAICompatibleProvider(
        Settings(
            openai_base_url="https://example.test/v1",
            openai_api_key="test-key",
        )
    )

    payload = provider.generate_json(
        scenario="companion_chat",
        system_prompt="system",
        user_prompt="user",
        schema={},
    )

    assert payload["replyText"] == "真实模型响应"
    assert payload["provider"] == "openai_compatible"
    assert payload["scenario"] == "companion_chat"


def test_model_call_logger_redacts_secrets_and_private_text():
    message = "weekend trip to chongqing, no cilantro"
    prompt = "plan a slow trip with night views" * 40
    request_summary = {
        "Authorization": "Bearer real-token",
        "apiKey": "amap-secret",
        "password": "plain-password",
        "message": message,
        "userPrompt": prompt,
        "context": {
            "accessToken": "nested-token",
            "destination": "Chongqing",
            "notes": "a" * 240,
        },
    }

    logger = ModelCallLogger()
    timer = logger.track("lanxin", "trip_planning", request_summary)
    timer.finish(fallback=False)

    summary = logger.records[0].requestSummary
    assert summary["Authorization"] == "[REDACTED]"
    assert summary["apiKey"] == "[REDACTED]"
    assert summary["password"] == "[REDACTED]"
    assert summary["context"]["accessToken"] == "[REDACTED]"
    assert summary["message"] == {"redacted": True, "chars": len(message)}
    assert summary["userPrompt"] == {"redacted": True, "chars": len(prompt)}
    assert summary["context"]["destination"] == "Chongqing"
    assert len(summary["context"]["notes"]) <= 203
    assert summary["context"]["notes"].endswith("...")
    assert request_summary["Authorization"] == "Bearer real-token"


# ── 3.4 错误路径测试 ───────────────────────────────────────────────────────


def test_lanxin_provider_config_error_without_credentials():
    """缺少 API Key 时抛出 ModelProviderConfigError。"""
    from app.services.model_providers.base import ModelProviderConfigError
    from app.services.model_providers.lanxin import LanxinModelProvider

    settings = Settings(lanxin_base_url=None, lanxin_api_key=None)
    with pytest.raises(ModelProviderConfigError, match="缺少"):
        LanxinModelProvider(settings)


def test_openai_provider_config_error_without_credentials():
    """缺少 base URL 或 API Key 时抛出 ModelProviderConfigError。"""
    from app.services.model_providers.base import ModelProviderConfigError
    from app.services.model_providers.openai_compatible import OpenAICompatibleProvider

    settings = Settings(openai_base_url=None, openai_api_key=None)
    with pytest.raises(ModelProviderConfigError, match="缺少"):
        OpenAICompatibleProvider(settings)


def test_lanxin_provider_wraps_connect_timeout(monkeypatch):
    """httpx.ConnectTimeout 被包装为 ModelProviderError。"""
    from app.services.model_providers.base import ModelProviderError
    from app.services.model_providers.lanxin import LanxinModelProvider

    monkeypatch.setattr(httpx.Client, "post", lambda *a, **kw: (_ for _ in ()).throw(httpx.ConnectTimeout("timeout")))
    provider = LanxinModelProvider(
        Settings(lanxin_base_url="http://mock", lanxin_api_key="sk-test")
    )
    with pytest.raises(ModelProviderError, match="蓝心模型调用失败"):
        provider.generate_json(scenario="test", system_prompt="S", user_prompt="U", schema={})


def test_lanxin_provider_wraps_connect_error(monkeypatch):
    """httpx.ConnectError 被包装为 ModelProviderError。"""
    from app.services.model_providers.base import ModelProviderError
    from app.services.model_providers.lanxin import LanxinModelProvider

    def raise_connect_error(self, url, headers, json):
        raise httpx.ConnectError("DNS failure")

    monkeypatch.setattr(httpx.Client, "post", raise_connect_error)
    provider = LanxinModelProvider(
        Settings(lanxin_base_url="http://mock", lanxin_api_key="sk-test")
    )
    with pytest.raises(ModelProviderError, match="蓝心模型调用失败"):
        provider.generate_json(scenario="test", system_prompt="S", user_prompt="U", schema={})


def test_lanxin_provider_wraps_read_timeout(monkeypatch):
    """httpx.ReadTimeout 被包装为 ModelProviderError。"""
    from app.services.model_providers.base import ModelProviderError
    from app.services.model_providers.lanxin import LanxinModelProvider

    def raise_read_timeout(self, url, headers, json):
        raise httpx.ReadTimeout("read timeout")

    monkeypatch.setattr(httpx.Client, "post", raise_read_timeout)
    provider = LanxinModelProvider(
        Settings(lanxin_base_url="http://mock", lanxin_api_key="sk-test")
    )
    with pytest.raises(ModelProviderError, match="蓝心模型调用失败"):
        provider.generate_json(scenario="test", system_prompt="S", user_prompt="U", schema={})


def test_lanxin_provider_wraps_malformed_json(monkeypatch):
    """模型返回非 JSON 时抛出 ModelProviderError。"""
    from app.services.model_providers.base import ModelProviderError
    from app.services.model_providers.lanxin import LanxinModelProvider

    def return_bad_json(self, url, headers, json):
        return httpx.Response(
            200,
            request=httpx.Request("POST", "http://mock"),
            json={"choices": [{"message": {"content": "这不是合法的 JSON"}}]},
        )

    monkeypatch.setattr(httpx.Client, "post", return_bad_json)
    provider = LanxinModelProvider(
        Settings(lanxin_base_url="http://mock", lanxin_api_key="sk-test")
    )
    with pytest.raises(ModelProviderError, match="蓝心模型调用失败"):
        provider.generate_json(scenario="test", system_prompt="S", user_prompt="U", schema={})


def test_lanxin_provider_wraps_http_500(monkeypatch):
    """HTTP 5xx 被包装为 ModelProviderError。"""
    from app.services.model_providers.base import ModelProviderError
    from app.services.model_providers.lanxin import LanxinModelProvider

    mock_resp = Mock()
    mock_resp.status_code = 500
    mock_resp.raise_for_status.side_effect = httpx.HTTPStatusError(
        "Internal Server Error", request=Mock(), response=mock_resp
    )

    def return_500(self, url, headers, json):
        return mock_resp

    monkeypatch.setattr(httpx.Client, "post", return_500)
    provider = LanxinModelProvider(
        Settings(lanxin_base_url="http://mock", lanxin_api_key="sk-test")
    )
    with pytest.raises(ModelProviderError, match="蓝心模型调用失败"):
        provider.generate_json(scenario="test", system_prompt="S", user_prompt="U", schema={})


def test_lanxin_provider_wraps_http_401(monkeypatch):
    """HTTP 401 被包装为 ModelProviderError。"""
    from app.services.model_providers.base import ModelProviderError
    from app.services.model_providers.lanxin import LanxinModelProvider

    mock_resp = Mock()
    mock_resp.status_code = 401
    mock_resp.raise_for_status.side_effect = httpx.HTTPStatusError(
        "Unauthorized", request=Mock(), response=mock_resp
    )

    def return_401(self, url, headers, json):
        return mock_resp

    monkeypatch.setattr(httpx.Client, "post", return_401)
    provider = LanxinModelProvider(
        Settings(lanxin_base_url="http://mock", lanxin_api_key="sk-test")
    )
    with pytest.raises(ModelProviderError, match="蓝心模型调用失败"):
        provider.generate_json(scenario="test", system_prompt="S", user_prompt="U", schema={})


def test_lanxin_provider_wraps_non_object_json_root(monkeypatch):
    """模型返回数组而非对象时抛出 ModelProviderError。"""
    from app.services.model_providers.base import ModelProviderError
    from app.services.model_providers.lanxin import LanxinModelProvider

    def return_array(self, url, headers, json_body):
        return httpx.Response(
            200,
            request=httpx.Request("POST", "http://mock"),
            json={"choices": [{"message": {"content": json.dumps([1, 2, 3])}}]},
        )

    monkeypatch.setattr(httpx.Client, "post", return_array)
    provider = LanxinModelProvider(
        Settings(lanxin_base_url="http://mock", lanxin_api_key="sk-test")
    )
    with pytest.raises(ModelProviderError, match="蓝心模型调用失败"):
        provider.generate_json(scenario="test", system_prompt="S", user_prompt="U", schema={})


def test_lanxin_provider_wraps_empty_choices(monkeypatch):
    """模型返回空的 choices 数组时抛出 ModelProviderError。"""
    from app.services.model_providers.base import ModelProviderError
    from app.services.model_providers.lanxin import LanxinModelProvider

    def return_empty_choices(self, url, headers, json):
        return httpx.Response(
            200,
            request=httpx.Request("POST", "http://mock"),
            json={"choices": []},
        )

    monkeypatch.setattr(httpx.Client, "post", return_empty_choices)
    provider = LanxinModelProvider(
        Settings(lanxin_base_url="http://mock", lanxin_api_key="sk-test")
    )
    with pytest.raises(ModelProviderError, match="蓝心模型调用失败"):
        provider.generate_json(scenario="test", system_prompt="S", user_prompt="U", schema={})


# ── Mock Provider 单元测试 ──────────────────────────────────────────────────


def test_mock_provider_generate_json_always_returns_fallback():
    """MockModelProvider.generate_json 始终返回 fallback=True。"""
    provider = MockModelProvider()
    result = provider.generate_json(scenario="test", system_prompt="S", user_prompt="U", schema={})
    assert result["fallback"] is True
    assert "fallbackReason" in result


def test_mock_provider_plan_trip_assembles_context():
    """MockModelProvider.plan_trip 基于 tool_trace 组装完整规划。"""
    provider = MockModelProvider()
    state = {
        "tool_trace": [
            {
                "tool": "weather_tool",
                "output": {
                    "city": "重庆", "condition": "晴", "temperatureC": 28,
                    "warnings": [], "travelHint": "适合出行",
                    "sourceTime": "2026-06-20 10:00:00",
                },
            },
            {
                "tool": "poi_tool",
                "output": {
                    "items": [{"name": "洪崖洞", "location": "106.588,29.563",
                               "openingHours": "10:00-23:00", "rating": 4.8}],
                },
            },
            {
                "tool": "route_tool",
                "output": {
                    "mode": "transit", "durationMinutes": 35, "distanceMeters": 7600,
                    "transfers": [{"line": "Metro Line 2"}],
                    "costEstimate": {"transitCny": 4.0},
                    "congestionSegments": [], "trafficLights": None,
                },
            },
        ],
    }
    result = provider.plan_trip(state)
    assert result["title"]
    assert result["destination"] == "重庆"
    assert result["externalContext"]["weather"]["condition"] == "晴"
    assert result["externalContext"]["route"]["durationMinutes"] == 35
    assert len(result["days"]) == 2
    assert len(result["risks"]) >= 2
    assert len(result["alternatives"]) == 2


def test_mock_provider_plan_trip_handles_empty_tool_trace():
    """空 tool_trace 也应生成合法规划。"""
    provider = MockModelProvider()
    result = provider.plan_trip({"tool_trace": []})
    assert result["title"]
    assert result["days"]
    assert result["externalContext"]["weather"] is None
