from typing import Any

from app.services.model_providers.base import ModelProvider


class LanxinModelProvider(ModelProvider):
    def generate_reply(self, prompt: str, context: dict[str, Any]) -> str:
        raise NotImplementedError("蓝心模型适配器仅预留接口，当前默认使用 Mock。")

    def plan_trip(self, state: dict[str, Any]) -> dict[str, Any]:
        raise NotImplementedError("蓝心模型适配器仅预留接口，当前默认使用 Mock。")
