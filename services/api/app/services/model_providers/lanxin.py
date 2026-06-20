import json
from typing import Any

import httpx

from app.core.config import Settings
from app.services.model_providers.base import ModelProvider, ModelProviderConfigError, ModelProviderError


class LanxinModelProvider(ModelProvider):
    name = "lanxin"

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        if not settings.lanxin_base_url or not settings.lanxin_api_key:
            raise ModelProviderConfigError("蓝心模型缺少 LANXIN_LANXIN_BASE_URL 或 LANXIN_LANXIN_API_KEY。")

    def generate_reply(self, prompt: str, context: dict[str, Any]) -> str:
        payload = self.generate_json(
            scenario="companion_chat",
            system_prompt="你是蓝心同行的中文旅行搭子。",
            user_prompt=prompt,
            schema={},
        )
        return str(payload.get("replyText") or payload)

    def generate_json(self, *, scenario: str, system_prompt: str, user_prompt: str, schema: dict[str, Any]) -> dict[str, Any]:
        url = self._settings.lanxin_base_url.rstrip("/") + "/chat/completions"
        headers = {"Authorization": f"Bearer {self._settings.lanxin_api_key}"}
        body = {
            "model": self._settings.lanxin_model,
            "messages": [
                {"role": "system", "content": system_prompt},
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
            payload = json.loads(content)
            if not isinstance(payload, dict):
                raise TypeError("模型 JSON 根节点必须是对象。")
            return payload | {"provider": self.name, "scenario": scenario}
        except (httpx.HTTPError, KeyError, IndexError, TypeError, json.JSONDecodeError) as exc:
            raise ModelProviderError(f"蓝心模型调用失败：{exc}") from exc

    def plan_trip(self, state: dict[str, Any]) -> dict[str, Any]:
        return self.generate_json(
            scenario="trip_planning",
            system_prompt="你是蓝心同行的旅行规划 Agent，只返回 JSON。",
            user_prompt=str(state),
            schema={},
        )