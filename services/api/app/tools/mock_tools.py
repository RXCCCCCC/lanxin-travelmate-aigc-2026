from typing import Any


def weather_tool(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "provider": "mock",
        "fallback": True,
        "city": payload.get("city", "重庆"),
        "condition": "多云",
        "temperatureC": 24,
        "rainProbability": 20,
        "travelHint": "适合夜景拍摄，晚间注意江边风。",
    }


def poi_tool(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "provider": "mock",
        "fallback": True,
        "city": payload.get("city", "重庆"),
        "keyword": payload.get("keyword", "夜景"),
        "items": ["洪崖洞", "南山一棵树", "山城步道"],
    }


def route_tool(payload: dict[str, Any]) -> dict[str, Any]:
    city = payload.get("city", "重庆")
    route = ["解放碑", "山城步道", "洪崖洞"]
    return {
        "provider": "mock",
        "fallback": True,
        "city": city,
        "pace": payload.get("pace", "轻松"),
        "route": route,
        "estimatedWalkingMinutes": 55,
        "navigationLinks": [
            navigation_link_tool({"destination": route[-1], "city": city}),
        ],
    }


def navigation_link_tool(payload: dict[str, Any]) -> dict[str, Any]:
    destination = payload.get("destination", "洪崖洞")
    return {
        "provider": "amap",
        "fallback": False,
        "label": f"导航到{destination}",
        "url": f"androidamap://route?sourceApplication=lanxin-travelmate&dname={destination}&dev=0&t=0",
    }


def asr_tool(payload: dict[str, Any]) -> dict[str, Any]:
    return {"text": payload.get("mockText", "周末想去重庆两天")}


def tts_tool(payload: dict[str, Any]) -> dict[str, Any]:
    return {"voiceText": payload.get("text", "蓝小心正在规划"), "format": "mock"}


def photo_analyze_tool(payload: dict[str, Any]) -> dict[str, Any]:
    return {"provider": "mock", "fallback": True, "tags": ["夜景", "洪崖洞", "高光照片"], "score": 9.3}
