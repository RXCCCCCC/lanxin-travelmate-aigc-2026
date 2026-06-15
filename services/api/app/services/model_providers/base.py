from abc import ABC, abstractmethod
from typing import Any


class ModelProvider(ABC):
    @abstractmethod
    def generate_reply(self, prompt: str, context: dict[str, Any]) -> str:
        raise NotImplementedError

    @abstractmethod
    def plan_trip(self, state: dict[str, Any]) -> dict[str, Any]:
        raise NotImplementedError
