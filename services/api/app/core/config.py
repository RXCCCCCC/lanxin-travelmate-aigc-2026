from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "蓝心同行 API"
    app_version: str = "0.1.0"
    api_prefix: str = "/api"
    database_url: str = "sqlite:///./lanxin_travelmate.db"
    log_level: str = "INFO"
    model_provider: str = "mock"
    model_timeout_seconds: float = 20.0
    openai_base_url: str | None = None
    openai_api_key: str | None = None
    openai_model: str = "gpt-4o-mini"
    lanxin_base_url: str | None = None
    lanxin_api_key: str | None = None
    lanxin_model: str = "lanxin"
    amap_base_url: str = "https://restapi.amap.com"
    amap_api_key: str | None = None
    tool_timeout_seconds: float = 8.0
    tool_rate_limit_per_minute: int = 0
    auth_token_secret: str = "lanxin-local-dev-secret"
    auth_token_ttl_seconds: int = 60 * 60 * 24 * 30
    cors_origins: list[str] = [
        "http://localhost",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="LANXIN_",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
