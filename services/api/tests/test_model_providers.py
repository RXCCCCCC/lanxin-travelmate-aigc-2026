import httpx

from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.nodes import mock_nodes
from app.agents.travelmate.state import create_initial_state
from app.core.config import Settings
from app.services.model_providers.call_log import ModelCallLogger
from app.services.model_providers.factory import build_model_provider
from app.services.model_providers.base import ModelProviderError
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
    model_trace = [item for item in result["tool_trace"] if item["tool"] == "model_provider" and item.get("scenario") == "trip_planning"]
    assert model_trace
    assert model_trace[-1]["provider"] == "lanxin"
    assert model_trace[-1]["fallback"] is True
    assert "缺少" in model_trace[-1]["error"]
    assert result["trip_plan"]["title"]


def test_graph_falls_back_when_model_trip_plan_schema_is_invalid(monkeypatch):
    class InvalidTripPlanProvider:
        def plan_trip(self, state):
            return {
                "tripPlanning": {
                    "title": "Missing destination and summary",
                    "profileMatches": [],
                    "risks": [],
                }
            }

    monkeypatch.setattr(mock_nodes, "build_model_provider", lambda settings: InvalidTripPlanProvider())
    state = create_initial_state(message="plan a slow trip")

    result = TravelMateGraph().invoke(state)

    model_trace = [item for item in result["tool_trace"] if item["tool"] == "model_provider" and item.get("scenario") == "trip_planning"]
    assert model_trace
    assert model_trace[-1]["fallback"] is True
    assert model_trace[-1]["errorType"] == "schema_validation"
    assert result["trip_plan"]["title"]


def test_graph_uses_valid_model_memory_extraction_output(monkeypatch):
    class MemoryProvider:
        name = "memory-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario == "memory_extraction":
                return {
                    "memoryExtraction": {
                        "candidates": [
                            {
                                "title": "Quiet gardens",
                                "content": "Traveler prefers calm garden stops.",
                                "category": "travel_preference",
                                "recommendedScope": "longTerm",
                                "confidence": 0.88,
                                "reason": "Repeated preference in the current request.",
                            }
                        ]
                    }
                }
            if scenario == "trip_review":
                raise ModelProviderError("review not configured")
            return {}

    monkeypatch.setattr(mock_nodes, "build_model_provider", lambda settings: MemoryProvider())
    state = create_initial_state(message="I prefer quiet gardens and slow walks")

    result = TravelMateGraph().invoke(state)

    candidate = result["memory_candidates"][0]
    assert candidate["title"] == "Quiet gardens"
    assert candidate["id"] == "model-memory-0"
    assert candidate["provider"] == "memory-provider"
    assert candidate["requiresExplicitConsent"] is True
    assert candidate["recommendedScope"] == "longTerm"


def test_graph_falls_back_when_model_memory_extraction_schema_is_invalid(monkeypatch):
    class InvalidMemoryProvider:
        name = "invalid-memory-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario == "memory_extraction":
                return {"memoryExtraction": {"candidates": [{"title": "Missing content"}]}}
            if scenario == "trip_review":
                raise ModelProviderError("review not configured")
            return {}

    monkeypatch.setattr(mock_nodes, "build_model_provider", lambda settings: InvalidMemoryProvider())
    state = create_initial_state(message="\u6211\u4e0d\u5403\u9999\u83dc\uff0c\u4e5f\u559c\u6b22\u591c\u666f")

    result = TravelMateGraph().invoke(state)

    model_trace = [item for item in result["tool_trace"] if item["tool"] == "model_provider" and item.get("scenario") == "memory_extraction"]
    assert any(item["id"] == "mem-cilantro" for item in result["memory_candidates"])
    assert model_trace
    assert model_trace[-1]["provider"] == "invalid-memory-provider"
    assert model_trace[-1]["fallback"] is True
    assert model_trace[-1]["errorType"] == "schema_validation"


def test_graph_uses_valid_model_trip_review_output(monkeypatch):
    class ReviewProvider:
        name = "review-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario in {"memory_extraction", "companion_chat"}:
                raise ModelProviderError(f"{scenario} not configured")
            assert scenario == "trip_review"
            return {
                "tripReview": {
                    "route": "Model start -> Model finish",
                    "highlightPhotos": ["model-photo"],
                    "completedTasks": [{"id": "task-model", "title": "Model task"}],
                    "reminderHighlights": [{"triggerType": "model"}],
                    "avatarStatusChanges": ["rapport +2"],
                    "newMemories": ["model memory"],
                    "nextTripSuggestions": ["model next trip"],
                    "temporaryMemoryPromotions": [
                        {"id": "mem-model", "suggestedScope": "longTerm", "reason": "model reason"}
                    ],
                    "profileContext": {"pace": "slow"},
                }
            }

    monkeypatch.setattr(mock_nodes, "build_model_provider", lambda settings: ReviewProvider())
    state = create_initial_state(message="Create a review")

    result = TravelMateGraph().invoke(state)

    assert result["review"]["route"] == "Model start -> Model finish"
    assert result["review"]["provider"] == "review-provider"
    assert result["review"]["fallback"] is False


def test_graph_falls_back_when_model_trip_review_schema_is_invalid(monkeypatch):
    class InvalidReviewProvider:
        name = "invalid-review-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario in {"memory_extraction", "companion_chat"}:
                raise ModelProviderError(f"{scenario} not configured")
            return {"tripReview": {"completedTasks": "not-a-list"}}

    monkeypatch.setattr(mock_nodes, "build_model_provider", lambda settings: InvalidReviewProvider())
    state = create_initial_state(message="Create a review")

    result = TravelMateGraph().invoke(state)

    model_trace = [item for item in result["tool_trace"] if item["tool"] == "model_provider" and item.get("scenario") == "trip_review"]
    assert result["review"]["provider"] == "invalid-review-provider"
    assert result["review"]["fallback"] is True
    assert result["review"]["errorType"] == "schema_validation"
    assert model_trace[-1]["fallback"] is True
    assert model_trace[-1]["errorType"] == "schema_validation"


def test_graph_uses_valid_model_chat_output(monkeypatch):
    class ChatProvider:
        name = "chat-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario in {"memory_extraction", "trip_review"}:
                raise ModelProviderError(f"{scenario} not configured")
            assert scenario == "companion_chat"
            return {
                "chat": {
                    "replyText": "Model chat reply",
                    "voiceText": "Model chat reply",
                    "avatarState": "planning",
                    "emotion": "curious",
                    "cards": [],
                    "memoryCandidates": [],
                    "toolTrace": [],
                    "nextActions": [{"type": "modelAction"}],
                    "syncSuggestions": [],
                    "errors": [],
                }
            }

    monkeypatch.setattr(mock_nodes, "build_model_provider", lambda settings: ChatProvider())
    state = create_initial_state(message="Plan a calm weekend")

    result = TravelMateGraph().invoke(state)

    assert result["response"]["replyText"] == "Model chat reply"
    assert result["response"]["nextActions"] == [{"type": "modelAction"}]
    model_trace = [item for item in result["response"]["toolTrace"] if item.get("scenario") == "companion_chat"]
    assert model_trace[-1]["provider"] == "chat-provider"
    assert model_trace[-1]["fallback"] is False


def test_graph_falls_back_when_model_chat_schema_is_invalid(monkeypatch):
    class InvalidChatProvider:
        name = "invalid-chat-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario in {"memory_extraction", "trip_review"}:
                raise ModelProviderError(f"{scenario} not configured")
            assert scenario == "companion_chat"
            return {"chat": {"replyText": "missing required fields"}}

    monkeypatch.setattr(mock_nodes, "build_model_provider", lambda settings: InvalidChatProvider())
    state = create_initial_state(message="Plan a calm weekend")

    result = TravelMateGraph().invoke(state)

    assert result["response"]["avatarState"] == "planning"
    model_trace = [item for item in result["response"]["toolTrace"] if item.get("scenario") == "companion_chat"]
    assert model_trace[-1]["provider"] == "invalid-chat-provider"
    assert model_trace[-1]["fallback"] is True
    assert model_trace[-1]["errorType"] == "schema_validation"


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
