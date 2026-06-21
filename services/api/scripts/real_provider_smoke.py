from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

API_ROOT = Path(__file__).resolve().parents[1]
if str(API_ROOT) not in sys.path:
    sys.path.insert(0, str(API_ROOT))

from app.core.config import Settings, get_settings
from app.services.model_providers import ModelProviderError, build_model_provider
from app.tools.registry import build_tool_registry


REDACTED = "[REDACTED]"


def _log(message: str, fields: dict[str, Any] | None = None) -> None:
    suffix = ""
    if fields:
        safe_fields = " ".join(f"{key}={value}" for key, value in fields.items())
        suffix = f" {safe_fields}"
    print(f"[real-smoke] {message}{suffix}")


def _run_amap_smoke(settings: Settings) -> bool:
    amap_key = settings.amap_api_key
    if not amap_key:
        _log("skip amap smoke", {"reason": "missing_key", "key": REDACTED})
        return True

    registry = build_tool_registry()
    checks = [
        (
            "weather",
            "weather_tool",
            {"city": "330100"},
        ),
        (
            "walking_route",
            "route_tool",
            {
                "city": "Hangzhou",
                "originLocation": "120.1551,30.2741",
                "destinationLocation": "120.1301,30.2590",
                "destination": "Lingyin Temple",
                "mode": "walking",
            },
        ),
    ]

    ok = True
    for scenario, tool_name, payload in checks:
        result = registry.call(tool_name, payload)
        fallback = bool(result.get("fallback"))
        _log(
            "amap check",
            {
                "scenario": scenario,
                "provider": result.get("provider"),
                "fallback": fallback,
                "errorType": result.get("errorType"),
            },
        )
        if fallback or result.get("provider") != "amap":
            ok = False
    return ok


def _model_configured(settings: Settings) -> bool:
    provider = settings.model_provider.lower().strip()
    lanxin_key = settings.lanxin_api_key
    openai_key = settings.openai_api_key
    lanxin_ready = bool(settings.lanxin_base_url and lanxin_key)
    openai_ready = bool(settings.openai_base_url and openai_key)
    if provider == "lanxin":
        return lanxin_ready
    if provider in {"openai", "openai_compatible", "openai-compatible"}:
        return openai_ready
    return False


def _run_model_smoke(settings: Settings) -> bool:
    provider_name = settings.model_provider.lower().strip()
    if provider_name in {"", "mock"}:
        _log("skip model smoke", {"reason": "mock_provider"})
        return True
    if not _model_configured(settings):
        _log("model smoke misconfigured", {"provider": provider_name, "key": REDACTED})
        return False

    try:
        provider = build_model_provider(settings)
        payload = provider.generate_json(
            scenario="ci_real_provider_smoke",
            system_prompt="Return only JSON for the Lanxin TravelMate connectivity check.",
            user_prompt='Return {"ok": true, "scenario": "ci_real_provider_smoke"}.',
            schema={},
        )
    except ModelProviderError as exc:
        _log("model smoke failed", {"provider": provider_name, "errorType": exc.__class__.__name__})
        return False

    ok = bool(payload.get("ok")) or bool(payload)
    _log(
        "model check",
        {
            "provider": payload.get("provider", provider_name),
            "scenario": payload.get("scenario", "ci_real_provider_smoke"),
            "ok": ok,
        },
    )
    return ok


def main() -> int:
    settings = get_settings()
    amap_key = settings.amap_api_key
    amap_ready = bool(amap_key)
    has_target = amap_ready or settings.model_provider.lower().strip() not in {"", "mock"}
    if not has_target:
        _log("no real provider smoke target configured", {"key": REDACTED})
        return 0

    amap_ok = _run_amap_smoke(settings)
    model_ok = _run_model_smoke(settings)
    return 0 if amap_ok and model_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())