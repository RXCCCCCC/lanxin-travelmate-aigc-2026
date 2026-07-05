import httpx

from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.nodes import real_nodes
from app.agents.travelmate.state import create_initial_state
from app.core.config import Settings
from app.services.model_providers.call_log import ModelCallLogger
from app.services.model_providers.factory import build_model_provider
from app.services.model_providers.base import ModelProviderError
from app.services.model_providers.mock import MockModelProvider
from app.services.model_providers.openai_compatible import OpenAICompatibleProvider


def test_model_provider_factory_defaults_to_mock():
    provider = build_model_provider(Settings(model_provider="mock"))

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

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: InvalidTripPlanProvider())
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

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: MemoryProvider())
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

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: InvalidMemoryProvider())
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

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: ReviewProvider())
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

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: InvalidReviewProvider())
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

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: ChatProvider())
    state = create_initial_state(message="Plan a calm weekend")

    result = TravelMateGraph().invoke(state)

    assert result["response"]["replyText"] == "Model chat reply"
    assert result["response"]["nextActions"] == [{"type": "modelAction"}]
    model_trace = [item for item in result["response"]["toolTrace"] if item.get("scenario") == "companion_chat"]
    assert model_trace[-1]["provider"] == "chat-provider"
    assert model_trace[-1]["fallback"] is False


def test_model_chat_response_preserves_extracted_memory_candidates(monkeypatch):
    class ChatMemoryProvider:
        name = "chat-memory-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario == "memory_extraction":
                return {
                    "memoryExtraction": {
                        "candidates": [
                            {
                                "title": "模型抽取偏好",
                                "content": "用户希望周末行程轻松，并优先安排夜景。",
                                "category": "travel_preference",
                                "recommendedScope": "currentTrip",
                                "confidence": 0.9,
                                "reason": "用户明确说明节奏和兴趣。",
                            }
                        ]
                    }
                }
            if scenario == "trip_review":
                raise ModelProviderError("review not configured")
            assert scenario == "companion_chat"
            return {
                "chat": {
                    "replyText": "Model chat reply",
                    "voiceText": "Model chat reply",
                    "avatarState": "planning",
                    "emotion": "curious",
                    "cards": [],
                    "memoryCandidates": [
                        {
                            "id": "chat-memory",
                            "title": "聊天追加偏好",
                            "content": "聊天模型建议本次保留夜景备选。",
                            "recommendedScope": "currentTrip",
                        }
                    ],
                    "toolTrace": [],
                    "nextActions": [],
                    "syncSuggestions": [],
                    "errors": [],
                }
            }

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: ChatMemoryProvider())
    state = create_initial_state(message="周末想去杭州两天，不想太累，喜欢夜景，我不吃香菜")

    result = TravelMateGraph().invoke(state)

    titles = [item["title"] for item in result["response"]["memoryCandidates"]]
    assert "聊天追加偏好" in titles
    assert "模型抽取偏好" in titles
    assert "喜欢夜景" in titles
    assert "不吃香菜" in titles


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

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: InvalidChatProvider())
    state = create_initial_state(message="Plan a calm weekend")

    result = TravelMateGraph().invoke(state)

    assert result["response"]["avatarState"] == "planning"
    model_trace = [item for item in result["response"]["toolTrace"] if item.get("scenario") == "companion_chat"]
    assert model_trace[-1]["provider"] == "invalid-chat-provider"
    assert model_trace[-1]["fallback"] is True
    assert model_trace[-1]["errorType"] == "schema_validation"


def test_graph_runs_structured_provider_across_core_agent_loop(monkeypatch):
    class StructuredProvider:
        name = "structured-provider"

        def plan_trip(self, state):
            return {
                "tripPlanning": {
                    "title": "Structured weekend",
                    "destination": "Chengdu",
                    "summary": "A validated provider-created plan.",
                    "profileMatches": ["quiet gardens"],
                    "risks": ["rain backup needed"],
                },
                "days": [],
            }

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario == "memory_extraction":
                return {
                    "memoryExtraction": {
                        "candidates": [
                            {
                                "title": "Quiet gardens",
                                "content": "Traveler prefers quiet gardens.",
                                "category": "travel_preference",
                                "recommendedScope": "longTerm",
                                "confidence": 0.9,
                                "reason": "The request mentions quiet gardens.",
                            }
                        ]
                    }
                }
            if scenario == "trip_review":
                return {
                    "tripReview": {
                        "route": "Garden gate -> Tea house",
                        "highlightPhotos": ["garden gate"],
                        "completedTasks": [{"id": "task-garden", "title": "Quiet garden photo"}],
                        "reminderHighlights": [],
                        "avatarStatusChanges": ["rapport +1"],
                        "newMemories": ["Quiet gardens"],
                        "nextTripSuggestions": ["Try another garden route"],
                        "temporaryMemoryPromotions": [],
                        "profileContext": {"pace": "slow"},
                    }
                }
            if scenario == "companion_chat":
                return {
                    "chat": {
                        "replyText": "Structured provider reply",
                        "voiceText": "Structured provider reply",
                        "avatarState": "planning",
                        "emotion": "curious",
                        "cards": [],
                        "memoryCandidates": [],
                        "toolTrace": [],
                        "nextActions": [],
                        "syncSuggestions": [],
                        "errors": [],
                    }
                }
            raise AssertionError(f"unexpected scenario {scenario}")

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: StructuredProvider())
    state = create_initial_state(message="Plan a slow weekend around quiet gardens")

    result = TravelMateGraph().invoke(state)

    assert result["memory_candidates"][0]["provider"] == "structured-provider"
    assert result["trip_plan"]["destination"] == "Chengdu"
    assert result["review"]["route"] == "Garden gate -> Tea house"
    assert result["response"]["replyText"] == "Structured provider reply"
    scenarios = {
        item.get("scenario"): item
        for item in result["response"]["toolTrace"]
        if item.get("tool") == "model_provider"
    }
    assert scenarios["memory_extraction"]["fallback"] is False
    assert scenarios["trip_planning"]["fallback"] is False
    assert scenarios["trip_review"]["fallback"] is False
    assert scenarios["companion_chat"]["fallback"] is False


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


def test_openai_compatible_provider_extracts_fenced_json_response(monkeypatch):
    def fake_post(self, url, headers, json):
        return httpx.Response(
            200,
            request=httpx.Request("POST", "https://example.test/v1/chat/completions"),
            json={
                "choices": [
                    {
                        "message": {
                            "content": '```json\n{"replyText": "围栏 JSON", "fallback": false}\n```'
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

    assert payload["replyText"] == "围栏 JSON"
    assert payload["provider"] == "openai_compatible"


def test_graph_accepts_unwrapped_model_memory_and_chat_outputs(monkeypatch):
    class UnwrappedProvider:
        name = "unwrapped-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario == "memory_extraction":
                return {
                    "candidates": [
                        {
                            "title": "夜景偏好",
                            "content": "用户喜欢夜景。",
                            "category": "travel_preference",
                            "recommendedScope": "longTerm",
                            "confidence": 0.91,
                            "reason": "用户明确提到喜欢夜景。",
                        }
                    ],
                    "provider": self.name,
                }
            if scenario == "trip_review":
                raise ModelProviderError("review not configured")
            if scenario == "companion_chat":
                return {
                    "replyText": "顶层聊天回复",
                    "voiceText": "顶层聊天回复",
                    "avatarState": "planning",
                    "emotion": "curious",
                    "provider": self.name,
                }
            raise AssertionError(f"unexpected scenario {scenario}")

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: UnwrappedProvider())
    state = create_initial_state(message="我喜欢夜景，周末想轻松走走")

    result = TravelMateGraph().invoke(state)

    assert result["memory_candidates"][0]["title"] == "夜景偏好"
    assert result["response"]["replyText"] == "顶层聊天回复"
    scenarios = {
        item.get("scenario"): item
        for item in result["response"]["toolTrace"]
        if item.get("tool") == "model_provider"
    }
    assert scenarios["memory_extraction"]["fallback"] is False
    assert scenarios["companion_chat"]["fallback"] is False


def test_chat_only_uses_model_reply_without_local_acknowledgement(monkeypatch):
    class ChatOnlyProvider:
        name = "chat-only-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            assert scenario == "companion_chat"
            assert "不吃香菜" in user_prompt
            return {
                "chat": {
                    "replyText": "广州可以从早茶、糖水和老城区小吃开始，我会按你的忌口避开香菜。",
                    "voiceText": "广州可以从早茶、糖水和老城区小吃开始，我会按你的忌口避开香菜。",
                    "avatarState": "planning",
                    "emotion": "curious",
                    "cards": [],
                    "memoryCandidates": [],
                    "toolTrace": [],
                    "nextActions": [{"type": "suggestFoodRoute"}],
                    "syncSuggestions": [],
                    "errors": [],
                }
            }

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: ChatOnlyProvider())
    state = create_initial_state(message="广州有什么好吃的，我不吃香菜")

    result = TravelMateGraph().invoke_chat_only(state)

    reply = result["response"]["replyText"]
    assert reply == "广州可以从早茶、糖水和老城区小吃开始，我会按你的忌口避开香菜。"
    assert "收到" not in reply
    assert "确认记忆胶囊" not in reply
    assert any(item["title"] == "不吃香菜" for item in result["response"]["memoryCandidates"])
    model_trace = [
        item
        for item in result["response"]["toolTrace"]
        if item.get("scenario") == "companion_chat"
    ]
    assert model_trace[-1]["provider"] == "chat-only-provider"
    assert model_trace[-1]["fallback"] is False


def test_graph_normalizes_real_memory_candidate_shape(monkeypatch):
    class RealishMemoryProvider:
        name = "realish-memory-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario == "memory_extraction":
                return {
                    "candidates": [
                        {
                            "id": "candidate_1",
                            "title": "Trying Street Food for the First Time",
                            "description": "A memory about sampling local street food.",
                            "type": "food",
                            "timestamp": "2023-10-07T18:45:00Z",
                            "location": "Dotonbori",
                            "people": [],
                            "tags": ["street food", "local cuisine"],
                        }
                    ],
                    "provider": self.name,
                }
            if scenario == "trip_review":
                raise ModelProviderError("review not configured")
            return {}

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: RealishMemoryProvider())
    state = create_initial_state(message="周末想去杭州，想尝试本地小吃")

    result = TravelMateGraph().invoke(state)

    candidate = result["memory_candidates"][0]
    assert candidate["title"] == "Trying Street Food for the First Time"
    assert candidate["content"] == "A memory about sampling local street food."
    assert candidate["category"] == "food"
    assert candidate["recommendedScope"] in {"temporary", "currentTrip", "longTerm"}
    assert candidate["confidence"] > 0
    assert candidate["provider"] == "realish-memory-provider"


def test_graph_normalizes_real_chat_response_shape(monkeypatch):
    class RealishChatProvider:
        name = "realish-chat-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario in {"memory_extraction", "trip_review"}:
                raise ModelProviderError(f"{scenario} not configured")
            if scenario == "companion_chat":
                return {
                    "response": "我会先按轻松节奏规划杭州两天，并优先安排夜景。",
                    "intent": "trip_planning",
                    "status": "ready",
                    "provider": self.name,
                }
            raise AssertionError(f"unexpected scenario {scenario}")

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: RealishChatProvider())
    state = create_initial_state(message="周末想去杭州两天，不想太累，喜欢夜景")

    result = TravelMateGraph().invoke(state)

    assert result["response"]["replyText"] == "我会先按轻松节奏规划杭州两天，并优先安排夜景。"
    model_trace = [item for item in result["response"]["toolTrace"] if item.get("scenario") == "companion_chat"]
    assert model_trace[-1]["provider"] == "realish-chat-provider"
    assert model_trace[-1]["fallback"] is False


def test_graph_normalizes_nested_real_trip_plan_shape(monkeypatch):
    class RealishTripProvider:
        name = "realish-trip-provider"

        def plan_trip(self, state):
            return {
                "response": {
                    "content": {
                        "title": "杭州两日夜景慢游",
                        "destination": "杭州",
                        "summary": "按轻松节奏安排西湖和夜景。",
                        "profileMatches": ["喜欢夜景", "不想太累"],
                        "risks": ["周末热门区域人流较多"],
                    }
                }
            }

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario == "memory_extraction":
                return {"memoryExtraction": {"candidates": []}}
            if scenario == "trip_review":
                raise ModelProviderError("review not configured")
            if scenario == "companion_chat":
                raise ModelProviderError("chat not configured")
            raise AssertionError(f"unexpected scenario {scenario}")

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: RealishTripProvider())
    state = create_initial_state(message="周末想去杭州两天，不想太累，喜欢夜景")

    result = TravelMateGraph().invoke(state)

    assert result["trip_plan"]["destination"] == "杭州"
    assert result["trip_plan"]["summary"] == "按轻松节奏安排西湖和夜景。"
    model_trace = [item for item in result["tool_trace"] if item.get("scenario") == "trip_planning"]
    assert model_trace[-1]["fallback"] is False


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


def test_openai_compatible_provider_compacts_trip_prompt(monkeypatch):
    captured: dict[str, object] = {}

    def fake_post(self, url, headers, json):
        captured["body"] = json
        return httpx.Response(
            200,
            request=httpx.Request("POST", "https://example.test/v1/chat/completions"),
            json={
                "choices": [
                    {
                        "message": {
                            "content": "{\"title\": \"Hangzhou\", \"destination\": \"Hangzhou\", \"summary\": \"Compact prompt works.\"}"
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

    payload = provider.plan_trip(
        {
            "message": "Plan Hangzhou",
            "intent": "trip_planning",
            "trip_context": {"destination": "Hangzhou", "pace": "slow", "durationDays": 2},
            "user_profile": {"interestTags": ["night view"]},
            "tool_trace": [{"tool": "poi_tool", "output": {"items": list(range(100))}}],
            "memory_candidates": [{"title": "night view", "content": "..." * 200}],
            "context": {"planningInputs": {"destination": "Hangzhou", "preferences": ["night view"]}},
        }
    )

    body = captured["body"]
    assert isinstance(body, dict)
    user_prompt = body["messages"][1]["content"]
    assert "tool_trace" not in user_prompt
    assert "memory_candidates" not in user_prompt
    assert "tripContext" in user_prompt
    assert len(user_prompt) < 2000
    assert payload["destination"] == "Hangzhou"


def test_openai_compatible_provider_includes_schema_contract(monkeypatch):
    captured: dict[str, object] = {}

    def fake_post(self, url, headers, json):
        captured["body"] = json
        return httpx.Response(
            200,
            request=httpx.Request("POST", "https://example.test/v1/chat/completions"),
            json={
                "choices": [
                    {
                        "message": {
                            "content": "{\"photoCopywriting\":{\"photoIds\":[],\"persona\":\"p\",\"style\":\"s\",\"moments\":\"m\",\"xiaohongshu\":\"x\",\"diary\":\"d\",\"vlogNarration\":\"v\",\"reviewSuggestion\":\"r\"}}"
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
        scenario="photo_copywriting",
        system_prompt="system",
        user_prompt="user",
        schema={"task": "photoCopywriting"},
    )

    system_prompt = captured["body"]["messages"][0]["content"]
    assert "photoCopywriting" in system_prompt
    assert "vlogNarration" in system_prompt
    assert "Markdown" in system_prompt
    assert "photoCopywriting" in payload


def test_model_chat_prompt_is_compact_for_real_provider(monkeypatch):
    class InspectingChatProvider:
        name = "inspect-chat-provider"

        def plan_trip(self, state):
            return MockModelProvider().plan_trip(state)

        def generate_json(self, *, scenario, system_prompt, user_prompt, schema):
            if scenario in {"memory_extraction", "trip_review"}:
                raise ModelProviderError(f"{scenario} not configured")
            assert scenario == "companion_chat"
            assert "toolTrace" not in user_prompt
            assert len(user_prompt) < 2500
            return {"response": "Compact chat prompt accepted."}

    monkeypatch.setattr(real_nodes, "build_model_provider", lambda settings: InspectingChatProvider())
    state = create_initial_state(message="Plan Hangzhou")
    state["intent"] = "trip_planning"
    state["user_profile"] = {"interestTags": ["night view"]}
    state["trip_plan"] = {
        "title": "Large plan",
        "destination": "Hangzhou",
        "summary": "A" * 1200,
        "days": [{"items": [{"note": "B" * 1200}]}],
    }
    state["memory_candidates"] = [{"title": "night", "content": "C" * 800}]
    state["avatar_status"] = {"energy": 80, "mood": "curious"}
    state["avatar_state"] = "planning"
    state["emotion"] = "curious"
    state["cards"] = []
    state["next_actions"] = []
    state["sync_suggestions"] = []
    state["errors"] = []
    state["tool_trace"] = [{"tool": "poi_tool", "output": {"items": list(range(100))}}]

    response = real_nodes._model_chat_response(state)

    assert response["replyText"] == "Compact chat prompt accepted."
