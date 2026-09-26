from abc import ABC, abstractmethod
from typing import Any


class ModelProviderError(RuntimeError):
    pass


class ModelProviderConfigError(ModelProviderError):
    pass


class ModelProvider(ABC):
    name: str = "base"

    @abstractmethod
    def generate_reply(self, prompt: str, context: dict[str, Any]) -> str:
        raise NotImplementedError

    @abstractmethod
    def generate_json(self, *, scenario: str, system_prompt: str, user_prompt: str, schema: dict[str, Any]) -> dict[str, Any]:
        raise NotImplementedError

    @abstractmethod
    def plan_trip(self, state: dict[str, Any]) -> dict[str, Any]:
        raise NotImplementedError