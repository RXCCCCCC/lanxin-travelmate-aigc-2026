from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "蓝心同行 API"
    app_version: str = "0.1.0"
    api_prefix: str = "/api"
    log_level: str = "INFO"
    model_provider: str = "mock"
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
