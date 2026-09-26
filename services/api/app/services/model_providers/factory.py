from app.core.config import Settings
from app.services.model_providers.base import ModelProvider
from app.services.model_providers.lanxin import LanxinModelProvider
from app.services.model_providers.mock import MockModelProvider
from app.services.model_providers.openai_compatible import OpenAICompatibleProvider


def build_model_provider(settings: Settings) -> ModelProvider:
    provider = settings.model_provider.lower().strip()
    if provider == "lanxin":
        return LanxinModelProvider(settings=settings)
    if provider in {"openai", "openai_compatible", "openai-compatible"}:
        return OpenAICompatibleProvider(settings=settings)
    return MockModelProvider()