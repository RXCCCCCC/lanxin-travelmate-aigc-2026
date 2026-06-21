from typing import Any


def weather_tool(payload: dict[str, Any]) -> dict[str, Any]:
    city = str(payload.get("city") or "")
    return {
        "provider": "mock",
        "fallback": True,
        "city": city,
        "condition": "多云" if city else "未配置",
        "temperatureC": payload.get("temperatureC"),
        "rainProbability": payload.get("rainProbability"),
        "travelHint": "真实天气 API 未配置；请提供城市或坐标并接入真实天气服务。",
    }


def poi_tool(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "provider": "mock",
        "fallback": True,
        "city": str(payload.get("city") or ""),
        "keyword": str(payload.get("keyword") or ""),
        "items": _string_list(payload.get("items")),
    }


def route_tool(payload: dict[str, Any]) -> dict[str, Any]:
    city = str(payload.get("city") or "")
    route = _route_from_payload(payload)
    return {
        "provider": "mock",
        "fallback": True,
        "city": city,
        "pace": payload.get("pace", ""),
        "route": route,
        "estimatedWalkingMinutes": payload.get("estimatedWalkingMinutes"),
        "navigationLinks": [
            navigation_link_tool({"destination": route[-1], "city": city}),
        ] if route else [],
    }


def navigation_link_tool(payload: dict[str, Any]) -> dict[str, Any]:
    destination = str(
        payload.get("destination")
        or payload.get("destinationLocation")
        or payload.get("dname")
        or ""
    )
    return {
        "provider": "amap",
        "fallback": False,
        "label": f"导航到{destination}" if destination else "打开地图导航",
        "url": (
            "androidamap://route?sourceApplication=lanxin-travelmate"
            f"&dname={destination}&dev=0&t=0"
        ) if destination else "",
    }


def asr_tool(payload: dict[str, Any]) -> dict[str, Any]:
    return {"text": str(payload.get("mockText") or "")}


def tts_tool(payload: dict[str, Any]) -> dict[str, Any]:
    return {"voiceText": str(payload.get("text") or ""), "format": "mock"}


def photo_analyze_tool(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "provider": "mock",
        "fallback": True,
        "tags": _string_list(payload.get("tags")),
        "score": payload.get("score", 0),
    }


def _route_from_payload(payload: dict[str, Any]) -> list[str]:
    explicit_route = _string_list(payload.get("route"))
    if explicit_route:
        return explicit_route
    origin = payload.get("origin") or payload.get("originLocation")
    destination = payload.get("destination") or payload.get("destinationLocation")
    return [str(item) for item in (origin, destination) if item]


def _string_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item)]