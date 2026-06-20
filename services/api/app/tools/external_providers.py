import hashlib
import json
from dataclasses import dataclass
from time import time
from typing import Any

import httpx
from sqlmodel import SQLModel, Session

from app.core.config import Settings
from app.db.models import ToolCacheEntry, utc_now
from app.db.session import engine
from app.tools.mock_tools import navigation_link_tool


_RATE_LIMIT_WINDOWS: dict[str, list[float]] = {}


@dataclass
class ToolRequestMeta:
    retry_count: int = 0
    cache_hit: bool = False
    circuit_open: bool = False
    error_type: str | None = None
    rate_limited: bool = False
    retry_after_seconds: int | None = None


class ToolCircuitOpenError(RuntimeError):
    pass


class ToolRateLimitError(RuntimeError):
    pass


class AmapToolProvider:
    name = "amap"
    failure_threshold = 2

    def __init__(self, settings: Settings) -> None:
        self._api_key = settings.amap_api_key
        self._base_url = (settings.amap_base_url or "https://restapi.amap.com").rstrip("/")
        self._timeout = settings.tool_timeout_seconds
        self._rate_limit_per_minute = max(0, int(settings.tool_rate_limit_per_minute or 0))
        self._cache: dict[tuple[str, tuple[tuple[str, str], ...]], dict[str, Any]] = {}
        self._failure_counts: dict[str, int] = {}

    @property
    def configured(self) -> bool:
        return bool(self._api_key)

    def weather(self, payload: dict[str, Any]) -> dict[str, Any]:
        if not self.configured:
            return _with_meta(_unconfigured_weather(payload), ToolRequestMeta())
        city = str(payload.get("adcode") or payload.get("city") or "")
        meta = ToolRequestMeta()
        try:
            response = self._get("/v3/weather/weatherInfo", {"city": city, "extensions": "base"}, meta)
            live = _first(response.get("lives"))
            if not live:
                return _with_meta(_failed_weather(payload, "天气接口未返回 lives 数据。"), meta)
            return _with_meta({
                "provider": self.name,
                "fallback": False,
                "city": live.get("city") or city,
                "condition": live.get("weather") or "未知",
                "temperatureC": _to_int(live.get("temperature")),
                "rainProbability": None,
                "warnings": [],
                "sourceTime": live.get("reporttime"),
                "confidence": 0.9,
                "travelHint": _weather_hint(str(live.get("weather") or "")),
                "rawSource": "amap.weatherInfo",
            }, meta)
        except ToolRateLimitError as exc:
            return _with_meta(_failed_weather(payload, str(exc)), meta)
        except ToolCircuitOpenError as exc:
            meta.circuit_open = True
            meta.error_type = "circuit_open"
            return _with_meta(_failed_weather(payload, str(exc)), meta)
        except (httpx.HTTPError, ValueError, KeyError) as exc:
            if meta.error_type is None:
                meta.error_type = exc.__class__.__name__
            return _with_meta(_failed_weather(payload, f"天气接口调用失败：{exc}"), meta)

    def poi(self, payload: dict[str, Any]) -> dict[str, Any]:
        if not self.configured:
            return _with_meta(_unconfigured_poi(payload), ToolRequestMeta())
        params = {
            "keywords": payload.get("keyword") or payload.get("keywords") or "景点",
            "region": payload.get("city") or "",
            "city_limit": "false",
            "show_fields": "business",
        }
        meta = ToolRequestMeta()
        try:
            response = self._get("/v5/place/text", params, meta)
            pois = response.get("pois") or []
            return _with_meta({
                "provider": self.name,
                "fallback": False,
                "city": payload.get("city"),
                "keyword": params["keywords"],
                "items": [_map_poi(item) for item in pois[:10]],
                "sourceTime": None,
                "confidence": 0.85 if pois else 0.45,
                "rawSource": "amap.place.text",
            }, meta)
        except ToolRateLimitError as exc:
            result = _unconfigured_poi(payload)
            result["provider"] = self.name
            result["fallbackReason"] = str(exc)
            return _with_meta(result, meta)
        except ToolCircuitOpenError as exc:
            meta.circuit_open = True
            meta.error_type = "circuit_open"
            result = _unconfigured_poi(payload)
            result["provider"] = self.name
            result["fallbackReason"] = str(exc)
            return _with_meta(result, meta)
        except (httpx.HTTPError, ValueError, KeyError) as exc:
            if meta.error_type is None:
                meta.error_type = exc.__class__.__name__
            result = _unconfigured_poi(payload)
            result["provider"] = self.name
            result["fallbackReason"] = f"POI 接口调用失败：{exc}"
            return _with_meta(result, meta)

    def route(self, payload: dict[str, Any]) -> dict[str, Any]:
        destination = str(payload.get("destination") or payload.get("destinationName") or "目的地")
        if not self.configured:
            return _with_meta(_unconfigured_route(payload, destination), ToolRequestMeta())
        origin = payload.get("originLocation") or payload.get("origin")
        destination_location = payload.get("destinationLocation") or payload.get("destination")
        if not origin or not destination_location:
            result = _unconfigured_route(payload, destination)
            result["provider"] = self.name
            result["fallbackReason"] = "路线接口需要 originLocation 与 destinationLocation 坐标。"
            return _with_meta(result, ToolRequestMeta(error_type="missing_coordinates"))
        meta = ToolRequestMeta()
        try:
            mode = str(payload.get("mode") or "walking").lower()
            if mode == "driving":
                return self._route_driving(payload, destination, origin, destination_location, meta)
            if mode == "transit":
                return self._route_transit(payload, destination, origin, destination_location, meta)
            if mode == "mixed":
                driving = self._route_driving(payload, destination, origin, destination_location, ToolRequestMeta())
                transit = self._route_transit(payload, destination, origin, destination_location, ToolRequestMeta())
                return _with_meta({
                    "provider": self.name,
                    "fallback": False,
                    "mode": "mixed",
                    "alternatives": [driving, transit],
                    "sourceTime": None,
                    "confidence": min(driving.get("confidence", 0), transit.get("confidence", 0)),
                    "navigationLinks": [navigation_link_tool({"destination": destination, "city": payload.get("city")})],
                    "rawSource": "amap.direction.mixed",
                }, meta)
            response = self._get("/v3/direction/walking", {"origin": origin, "destination": destination_location}, meta)
            path = _first((response.get("route") or {}).get("paths"))
            if not path:
                raise ValueError("路线接口未返回 paths 数据。")
            duration_seconds = _to_int(path.get("duration")) or 0
            distance_meters = _to_int(path.get("distance")) or 0
            steps = [str(step.get("instruction")) for step in path.get("steps") or [] if step.get("instruction")]
            return _with_meta({
                "provider": self.name,
                "fallback": False,
                "mode": "walking",
                "distanceMeters": distance_meters,
                "durationMinutes": max(1, round(duration_seconds / 60)) if duration_seconds else None,
                "steps": steps,
                "sourceTime": None,
                "confidence": 0.9,
                "navigationLinks": [navigation_link_tool({"destination": destination, "city": payload.get("city")})],
                "rawSource": "amap.direction.walking",
            }, meta)
        except ToolRateLimitError as exc:
            result = _unconfigured_route(payload, destination)
            result["provider"] = self.name
            result["fallbackReason"] = str(exc)
            return _with_meta(result, meta)
        except ToolCircuitOpenError as exc:
            meta.circuit_open = True
            meta.error_type = "circuit_open"
            result = _unconfigured_route(payload, destination)
            result["provider"] = self.name
            result["fallbackReason"] = str(exc)
            return _with_meta(result, meta)
        except (httpx.HTTPError, ValueError, KeyError) as exc:
            if meta.error_type is None:
                meta.error_type = exc.__class__.__name__
            result = _unconfigured_route(payload, destination)
            result["provider"] = self.name
            result["fallbackReason"] = f"路线接口调用失败：{exc}"
            return _with_meta(result, meta)

    def _route_driving(
        self,
        payload: dict[str, Any],
        destination: str,
        origin: Any,
        destination_location: Any,
        meta: ToolRequestMeta,
    ) -> dict[str, Any]:
        response = self._get("/v3/direction/driving", {"origin": origin, "destination": destination_location}, meta)
        path = _first((response.get("route") or {}).get("paths"))
        if not path:
            raise ValueError("驾车路线接口未返回 paths 数据。")
        duration_seconds = _to_int(path.get("duration")) or 0
        steps = [str(step.get("instruction")) for step in path.get("steps") or [] if step.get("instruction")]
        return _with_meta({
            "provider": self.name,
            "fallback": False,
            "mode": "driving",
            "distanceMeters": _to_int(path.get("distance")) or 0,
            "durationMinutes": max(1, round(duration_seconds / 60)) if duration_seconds else None,
            "steps": steps,
            "transfers": [],
            "walkingDistanceMeters": 0,
            "trafficLights": _to_int(path.get("traffic_lights")),
            "congestionSegments": _driving_congestion_segments(path.get("tmcs") or []),
            "costEstimate": {
                "taxiCny": _to_float((response.get("route") or {}).get("taxi_cost")),
                "tollCny": _to_float(path.get("tolls")),
            },
            "sourceTime": None,
            "confidence": 0.88,
            "navigationLinks": [navigation_link_tool({"destination": destination, "city": payload.get("city")})],
            "rawSource": "amap.direction.driving",
        }, meta)

    def _route_transit(
        self,
        payload: dict[str, Any],
        destination: str,
        origin: Any,
        destination_location: Any,
        meta: ToolRequestMeta,
    ) -> dict[str, Any]:
        params = {
            "origin": origin,
            "destination": destination_location,
            "city": payload.get("city") or payload.get("originCity") or "",
            "cityd": payload.get("destinationCity") or payload.get("city") or "",
        }
        response = self._get("/v3/direction/transit/integrated", params, meta)
        transit = _first((response.get("route") or {}).get("transits"))
        if not transit:
            raise ValueError("公交路线接口未返回 transits 数据。")
        duration_seconds = _to_int(transit.get("duration")) or 0
        transfers = _transit_transfers(transit.get("segments") or [])
        steps = [item.get("line") for item in transfers if item.get("line")]
        return _with_meta({
            "provider": self.name,
            "fallback": False,
            "mode": "transit",
            "distanceMeters": _to_int(transit.get("distance")) or 0,
            "durationMinutes": max(1, round(duration_seconds / 60)) if duration_seconds else None,
            "steps": steps,
            "transfers": transfers,
            "walkingDistanceMeters": _to_int(transit.get("walking_distance")) or 0,
            "costEstimate": {"transitCny": _to_float(transit.get("cost"))},
            "sourceTime": None,
            "confidence": 0.86,
            "navigationLinks": [navigation_link_tool({"destination": destination, "city": payload.get("city")})],
            "rawSource": "amap.direction.transit.integrated",
        }, meta)

    def _get(self, path: str, params: dict[str, Any], meta: ToolRequestMeta) -> dict[str, Any]:
        if self._failure_counts.get(path, 0) >= self.failure_threshold:
            meta.circuit_open = True
            meta.error_type = "circuit_open"
            raise ToolCircuitOpenError(f"{path} 熔断中：连续失败次数达到 {self.failure_threshold}。")

        request_params = {key: value for key, value in params.items() if value not in (None, "")}
        request_params["key"] = self._api_key
        cache_key = (path, tuple(sorted((key, str(value)) for key, value in request_params.items())))
        persistent_cache_key = _persistent_cache_key(path, request_params)
        if cache_key in self._cache:
            meta.cache_hit = True
            return dict(self._cache[cache_key])
        cached = self._read_persistent_cache(persistent_cache_key)
        if cached is not None:
            meta.cache_hit = True
            self._cache[cache_key] = dict(cached)
            return cached

        self._check_rate_limit(path, meta)

        last_error: httpx.HTTPError | None = None
        for _ in range(2):
            try:
                with httpx.Client(timeout=self._timeout) as client:
                    response = client.get(f"{self._base_url}{path}", params=request_params)
                response.raise_for_status()
                data = response.json()
                if str(data.get("status")) != "1":
                    self._record_failure(path)
                    meta.error_type = "provider_status_error"
                    raise ValueError(data.get("info") or "Amap API returned non-success status")
                self._failure_counts[path] = 0
                self._cache[cache_key] = dict(data)
                self._write_persistent_cache(persistent_cache_key, path, data)
                return data
            except httpx.HTTPError as exc:
                meta.retry_count += 1
                meta.error_type = exc.__class__.__name__
                last_error = exc
        self._record_failure(path)
        if self._failure_counts.get(path, 0) >= self.failure_threshold:
            meta.circuit_open = True
        if last_error is not None:
            raise last_error
        raise ValueError("Amap API request failed")

    def _check_rate_limit(self, path: str, meta: ToolRequestMeta) -> None:
        if self._rate_limit_per_minute <= 0:
            return
        now = time()
        window_start = now - 60
        bucket = [item for item in _RATE_LIMIT_WINDOWS.get(path, []) if item > window_start]
        if len(bucket) >= self._rate_limit_per_minute:
            oldest = min(bucket)
            retry_after = max(1, int(60 - (now - oldest)))
            _RATE_LIMIT_WINDOWS[path] = bucket
            meta.rate_limited = True
            meta.retry_after_seconds = retry_after
            meta.error_type = "rate_limited"
            raise ToolRateLimitError(f"{path} 触发本地限流，请 {retry_after} 秒后重试。")
        bucket.append(now)
        _RATE_LIMIT_WINDOWS[path] = bucket

    def _record_failure(self, path: str) -> None:
        self._failure_counts[path] = self._failure_counts.get(path, 0) + 1

    def _read_persistent_cache(self, cache_key: str) -> dict[str, Any] | None:
        SQLModel.metadata.create_all(engine)
        with Session(engine) as session:
            item = session.get(ToolCacheEntry, cache_key)
            if not item:
                return None
            data = json.loads(item.response_json)
            return data if isinstance(data, dict) else None

    def _write_persistent_cache(self, cache_key: str, path: str, data: dict[str, Any]) -> None:
        now = utc_now()
        SQLModel.metadata.create_all(engine)
        with Session(engine) as session:
            item = session.get(ToolCacheEntry, cache_key)
            if item:
                item.response_json = json.dumps(data, ensure_ascii=False)
                item.updated_at = now
            else:
                item = ToolCacheEntry(
                    cache_key=cache_key,
                    provider=self.name,
                    path=path,
                    response_json=json.dumps(data, ensure_ascii=False),
                    created_at=now,
                    updated_at=now,
                )
            session.add(item)
            session.commit()


def _persistent_cache_key(path: str, request_params: dict[str, Any]) -> str:
    cacheable_params = {key: str(value) for key, value in request_params.items() if key != "key"}
    raw = json.dumps({"path": path, "params": cacheable_params}, ensure_ascii=False, sort_keys=True)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _with_meta(result: dict[str, Any], meta: ToolRequestMeta) -> dict[str, Any]:
    result = dict(result)
    result.setdefault("sourceTime", None)
    result["retryCount"] = meta.retry_count
    result["cacheHit"] = meta.cache_hit
    result["circuitOpen"] = meta.circuit_open
    result["errorType"] = meta.error_type
    result["rateLimited"] = meta.rate_limited
    result["retryAfterSeconds"] = meta.retry_after_seconds
    return result


def _first(value: Any) -> dict[str, Any] | None:
    if isinstance(value, list) and value:
        first = value[0]
        if isinstance(first, dict):
            return first
    return None


def _to_int(value: Any) -> int | None:
    try:
        return int(float(str(value)))
    except (TypeError, ValueError):
        return None


def _to_float(value: Any) -> float | None:
    try:
        return float(str(value))
    except (TypeError, ValueError):
        return None


def _weather_hint(condition: str) -> str:
    if "雨" in condition:
        return "当前可能降雨，建议准备雨具并优先安排室内或近距离路线。"
    if "雪" in condition:
        return "当前天气偏冷且可能影响通行，建议降低步行强度。"
    if "晴" in condition:
        return "天气较适合户外游览，注意防晒和补水。"
    return "天气信息已更新，建议结合体力和交通情况安排行程。"


def _map_poi(item: dict[str, Any]) -> dict[str, Any]:
    business = item.get("business") if isinstance(item.get("business"), dict) else {}
    return {
        "name": item.get("name") or "未命名地点",
        "type": item.get("type"),
        "address": item.get("address"),
        "location": item.get("location"),
        "rating": _to_float(business.get("rating")),
        "openingHours": business.get("opentime_today") or business.get("opentime_week"),
    }


def _driving_congestion_segments(items: list[Any]) -> list[dict[str, Any]]:
    segments: list[dict[str, Any]] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        segments.append({
            "status": item.get("status"),
            "distanceMeters": _to_int(item.get("distance")) or 0,
            "polyline": item.get("polyline"),
        })
    return segments

def _transit_transfers(segments: list[Any]) -> list[dict[str, Any]]:
    transfers: list[dict[str, Any]] = []
    for segment in segments:
        if not isinstance(segment, dict):
            continue
        bus = segment.get("bus") if isinstance(segment.get("bus"), dict) else {}
        for line in bus.get("buslines") or []:
            if not isinstance(line, dict):
                continue
            departure = line.get("departure_stop") if isinstance(line.get("departure_stop"), dict) else {}
            arrival = line.get("arrival_stop") if isinstance(line.get("arrival_stop"), dict) else {}
            transfers.append({
                "line": line.get("name"),
                "departureStop": departure.get("name"),
                "arrivalStop": arrival.get("name"),
            })
    return transfers

def _unconfigured_weather(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "provider": "unconfigured",
        "fallback": True,
        "fallbackReason": "真实天气 API 尚未配置；请设置 LANXIN_AMAP_API_KEY 或接入其他天气服务商。",
        "city": payload.get("city"),
        "condition": None,
        "temperatureC": None,
        "rainProbability": None,
        "warnings": [],
        "sourceTime": None,
        "confidence": 0.0,
        "travelHint": "暂无真实天气数据，规划时请人工确认天气与预警。",
    }


def _failed_weather(payload: dict[str, Any], reason: str) -> dict[str, Any]:
    result = _unconfigured_weather(payload)
    result["provider"] = "amap"
    result["fallbackReason"] = reason
    return result


def _unconfigured_poi(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "provider": "unconfigured",
        "fallback": True,
        "fallbackReason": "真实 POI API 尚未配置；请设置 LANXIN_AMAP_API_KEY 或接入其他地图服务商。",
        "city": payload.get("city"),
        "keyword": payload.get("keyword") or payload.get("keywords"),
        "items": [],
        "sourceTime": None,
        "confidence": 0.0,
    }


def _unconfigured_route(payload: dict[str, Any], destination: str) -> dict[str, Any]:
    return {
        "provider": "unconfigured",
        "fallback": True,
        "fallbackReason": "真实路线 API 尚未配置；请设置 LANXIN_AMAP_API_KEY 并传入起终点坐标。",
        "mode": payload.get("mode") or "walking",
        "distanceMeters": None,
        "durationMinutes": None,
        "steps": [],
        "sourceTime": None,
        "confidence": 0.0,
        "navigationLinks": [navigation_link_tool({"destination": destination, "city": payload.get("city")})],
    }
