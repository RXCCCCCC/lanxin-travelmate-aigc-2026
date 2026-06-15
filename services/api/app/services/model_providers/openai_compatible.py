from typing import Any

from app.services.model_providers.base import ModelProvider


class OpenAICompatibleProvider(ModelProvider):
    def generate_reply(self, prompt: str, context: dict[str, Any]) -> str:
        raise NotImplementedError("OpenAI 兼容模型适配器仅预留接口，当前默认使用 Mock。")

    def plan_trip(self, state: dict[str, Any]) -> dict[str, Any]:
        raise NotImplementedError("OpenAI 兼容模型适配器仅预留接口，当前默认使用 Mock。")
