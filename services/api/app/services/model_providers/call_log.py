from dataclasses import dataclass, field
from time import perf_counter
from typing import Any


SECRET_KEYS = {
    "authorization",
    "api_key",
    "apikey",
    "api-key",
    "access_token",
    "accesstoken",
    "access-token",
    "token",
    "password",
    "secret",
    "key",
}
PRIVATE_TEXT_KEYS = {
    "message",
    "prompt",
    "user_prompt",
    "userprompt",
    "system_prompt",
    "systemprompt",
    "text",
    "content",
}
MAX_LOG_STRING_CHARS = 200
MAX_LOG_LIST_ITEMS = 20


@dataclass
class ModelCallRecord:
    provider: str
    scenario: str
    elapsedMs: int
    fallback: bool
    error: str | None = None
    requestSummary: dict[str, Any] = field(default_factory=dict)


class ModelCallLogger:
    def __init__(self) -> None:
        self.records: list[ModelCallRecord] = []

    def track(self, provider: str, scenario: str, request_summary: dict[str, Any]) -> "ModelCallTimer":
        return ModelCallTimer(self, provider, scenario, request_summary)


class ModelCallTimer:
    def __init__(self, logger: ModelCallLogger, provider: str, scenario: str, request_summary: dict[str, Any]) -> None:
        self._logger = logger
        self._provider = provider
        self._scenario = scenario
        self._request_summary = request_summary
        self._started = perf_counter()

    def finish(self, *, fallback: bool, error: str | None = None) -> None:
        elapsed_ms = int((perf_counter() - self._started) * 1000)
        self._logger.records.append(
            ModelCallRecord(
                provider=self._provider,
                scenario=self._scenario,
                elapsedMs=elapsed_ms,
                fallback=fallback,
                error=error,
                requestSummary=redact_request_summary(self._request_summary),
            )
        )


def redact_request_summary(value: dict[str, Any]) -> dict[str, Any]:
    return _redact_value(value)


def _redact_value(value: Any, key: str | None = None) -> Any:
    normalized_key = _normalize_key(key)
    if normalized_key in SECRET_KEYS:
        return "[REDACTED]"
    if normalized_key in PRIVATE_TEXT_KEYS and isinstance(value, str):
        return {"redacted": True, "chars": len(value)}
    if isinstance(value, dict):
        return {str(item_key): _redact_value(item_value, str(item_key)) for item_key, item_value in value.items()}
    if isinstance(value, list):
        limited_items = [_redact_value(item, key) for item in value[:MAX_LOG_LIST_ITEMS]]
        if len(value) > MAX_LOG_LIST_ITEMS:
            limited_items.append({"truncated": True, "remaining": len(value) - MAX_LOG_LIST_ITEMS})
        return limited_items
    if isinstance(value, str) and len(value) > MAX_LOG_STRING_CHARS:
        return value[:MAX_LOG_STRING_CHARS] + "..."
    return value


def _normalize_key(key: str | None) -> str:
    if not key:
        return ""
    return key.replace("-", "_").lower()