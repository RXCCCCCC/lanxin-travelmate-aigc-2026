import httpx

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
