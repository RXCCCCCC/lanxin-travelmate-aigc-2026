import json
import re
from typing import Any

import httpx

from app.core.config import Settings
from app.services.model_providers.base import ModelProvider, ModelProviderConfigError, ModelProviderError


class OpenAICompatibleProvider(ModelProvider):
    name = "openai_compatible"

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        if not settings.openai_base_url or not settings.openai_api_key:
            raise ModelProviderConfigError("OpenAI 兼容模型缺少 LANXIN_OPENAI_BASE_URL 或 LANXIN_OPENAI_API_KEY。")

    def generate_reply(self, prompt: str, context: dict[str, Any]) -> str:
        payload = self.generate_json(
            scenario="companion_chat",
            system_prompt="你是蓝心同行的中文旅行搭子。",
            user_prompt=prompt,
            schema={},
        )
        return str(payload.get("replyText") or payload)

    def generate_json(self, *, scenario: str, system_prompt: str, user_prompt: str, schema: dict[str, Any]) -> dict[str, Any]:
        url = self._settings.openai_base_url.rstrip("/") + "/chat/completions"
        headers = {"Authorization": f"Bearer {self._settings.openai_api_key}"}
        schema_prompt = _schema_prompt(scenario, schema)
        body = {
            "model": self._settings.openai_model,
            "messages": [
                {"role": "system", "content": f"{system_prompt}\n{schema_prompt}"},
                {"role": "user", "content": user_prompt},
            ],
            "response_format": {"type": "json_object"},
            "temperature": 0.4,
        }
        try:
            with httpx.Client(timeout=self._settings.model_timeout_seconds) as client:
                response = client.post(url, headers=headers, json=body)
                response.raise_for_status()
            data = response.json()
            content = data["choices"][0]["message"]["content"]
            payload = _loads_json_object(content)
            if not isinstance(payload, dict):
                raise TypeError("模型 JSON 根节点必须是对象。")
            return payload | {"provider": self.name, "scenario": scenario}
        except (httpx.HTTPError, KeyError, IndexError, TypeError, json.JSONDecodeError) as exc:
            raise ModelProviderError(f"OpenAI 兼容模型调用失败：{exc}") from exc

    def plan_trip(self, state: dict[str, Any]) -> dict[str, Any]:
        return self.generate_json(
            scenario="trip_planning",
            system_prompt="你是蓝心同行的旅行规划 Agent，只返回 JSON。",
            user_prompt=json.dumps(_compact_trip_state(state), ensure_ascii=False),
            schema={"task": "tripPlanning"},
        )


def _schema_prompt(scenario: str, schema: dict[str, Any]) -> str:
    task = str(schema.get("task") or scenario)
    contracts = {
        "chat": (
            'Return {"chat":{"replyText":"...","voiceText":"...","avatarState":"planning",'
            '"emotion":"curious","cards":[],"memoryCandidates":[],"toolTrace":[],'
            '"nextActions":[],"syncSuggestions":[],"errors":[]}}.'
        ),
        "memoryExtraction": (
            'Return {"memoryExtraction":{"candidates":[{"title":"...","content":"...",'
            '"category":"travel_preference","recommendedScope":"longTerm","confidence":0.8,'
            '"reason":"..."}]}}.'
        ),
        "tripPlanning": (
            'Return {"tripPlanning":{"title":"...","destination":"...","summary":"...",'
            '"profileMatches":[],"risks":[],"alternatives":[]}}.'
        ),
        "photoCopywriting": (
            'Return {"photoCopywriting":{"photoIds":[],"persona":"...","style":"...",'
            '"moments":"...","xiaohongshu":"...","diary":"...","vlogNarration":"...",'
            '"reviewSuggestion":"..."}}.'
        ),
        "tripReview": (
            'Return {"tripReview":{"route":"...","highlightPhotos":[],"completedTasks":[],'
            '"reminderHighlights":[],"avatarStatusChanges":[],"newMemories":[],'
            '"nextTripSuggestions":[],"temporaryMemoryPromotions":[],"profileContext":{}}}.'
        ),
    }
    contract = contracts.get(task) or contracts.get(scenario)
    if not contract:
        return "Return one valid JSON object only. Do not include Markdown or explanatory text."
    return f"{contract} Return one valid JSON object only. Do not include Markdown or explanatory text."


def _loads_json_object(content: str) -> dict[str, Any]:
    text = content.strip()
    fenced = re.fullmatch(r"```(?:json)?\s*(.*?)\s*```", text, flags=re.DOTALL | re.IGNORECASE)
    if fenced:
        text = fenced.group(1).strip()
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        start = text.find("{")
        if start < 0:
            raise
        payload, _ = json.JSONDecoder().raw_decode(text[start:])
    if not isinstance(payload, dict):
        raise TypeError("模型 JSON 根节点必须是对象。")
    return payload


def _truncate_text(value: object, limit: int = 160) -> str | None:
    if not isinstance(value, str):
        return None
    text = value.strip()
    if not text:
        return None
    if len(text) <= limit:
        return text
    return text[:limit] + "..."


def _compact_trip_state(state: dict[str, Any]) -> dict[str, Any]:
    trip_context = state.get("trip_context") if isinstance(state.get("trip_context"), dict) else {}
    user_profile = state.get("user_profile") if isinstance(state.get("user_profile"), dict) else {}
    context = state.get("context") if isinstance(state.get("context"), dict) else {}
    planning_inputs = context.get("planningInputs") if isinstance(context.get("planningInputs"), dict) else {}
    memory_candidates = state.get("memory_candidates") if isinstance(state.get("memory_candidates"), list) else []
    compact_memories = []
    for item in memory_candidates[:4]:
        if not isinstance(item, dict):
            continue
        compact_memories.append(
            {
                "title": item.get("title"),
                "category": item.get("category"),
                "recommendedScope": item.get("recommendedScope"),
            }
        )
    return {
        "message": _truncate_text(state.get("message"), 240),
        "intent": state.get("intent"),
        "tripContext": {
            "destination": trip_context.get("destination"),
            "durationDays": trip_context.get("durationDays"),
            "pace": trip_context.get("pace"),
        },
        "userProfile": {
            "dietaryPreferences": user_profile.get("dietaryPreferences"),
            "travelPace": user_profile.get("travelPace"),
            "interestTags": user_profile.get("interestTags"),
        },
        "planningInputs": {
            "destination": planning_inputs.get("destination"),
            "dateRange": planning_inputs.get("dateRange"),
            "budget": planning_inputs.get("budget"),
            "companions": planning_inputs.get("companions"),
            "preferences": planning_inputs.get("preferences"),
            "transportMode": planning_inputs.get("transportMode"),
            "tripStyle": planning_inputs.get("tripStyle"),
            "replanReason": planning_inputs.get("replanReason"),
        },
        "memoryHints": compact_memories,
    }
