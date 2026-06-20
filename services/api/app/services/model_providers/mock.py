from typing import Any

from app.services.model_providers.base import ModelProvider


def _tool_context(tool_trace: list[dict[str, Any]]) -> dict[str, Any]:
    context: dict[str, Any] = {"weather": None, "pois": [], "route": None}
    for trace_item in tool_trace:
        output = trace_item.get("output") if isinstance(trace_item, dict) else None
        if not isinstance(output, dict):
            continue
        tool_name = trace_item.get("tool")
        if tool_name == "weather_tool":
            context["weather"] = {
                "city": output.get("city"),
                "condition": output.get("condition"),
                "temperatureC": output.get("temperatureC"),
                "warnings": output.get("warnings") or [],
                "travelHint": output.get("travelHint"),
                "sourceTime": output.get("sourceTime"),
            }
        elif tool_name == "poi_tool":
            raw_items = output.get("items") or []
            context["pois"] = [item for item in raw_items if isinstance(item, dict)]
        elif tool_name == "route_tool":
            context["route"] = {
                "mode": output.get("mode"),
                "durationMinutes": output.get("durationMinutes"),
                "distanceMeters": output.get("distanceMeters"),
                "transfers": output.get("transfers") or [],
                "costEstimate": output.get("costEstimate") or {},
                "congestionSegments": output.get("congestionSegments") or [],
                "trafficLights": output.get("trafficLights"),
            }
    return context

class MockModelProvider(ModelProvider):
    name = "mock"

    def generate_reply(self, prompt: str, context: dict[str, Any]) -> str:
        return f"蓝小心已收到：{prompt}"

    def generate_json(self, *, scenario: str, system_prompt: str, user_prompt: str, schema: dict[str, Any]) -> dict[str, Any]:
        return {
            "replyText": "蓝小心已用离线降级模式生成结构化结果。",
            "fallback": True,
            "fallbackReason": "当前使用 MockModelProvider，仅用于离线降级和测试。",
        }

    def plan_trip(self, state: dict[str, Any]) -> dict[str, Any]:
        tool_context = _tool_context(state.get("tool_trace") or [])
        profile_matches = [
            "保留洪崖洞夜景，因为你喜欢夜景。",
            "减少跨区移动，因为你这次不想太累。",
            "餐饮推荐默认标注避开香菜。",
        ]
        risks = [
            "洪崖洞周末晚间人流高峰明显，建议错峰到达。",
            "重庆坡道较多，建议穿舒适鞋。",
            "餐厅点单前提醒服务员不要香菜。",
        ]
        weather = tool_context.get("weather") or {}
        pois = tool_context.get("pois") or []
        route = tool_context.get("route") or {}
        if weather.get("travelHint"):
            risks.append(f"天气提示：{weather['travelHint']}")
        if pois and pois[0].get("openingHours"):
            profile_matches.append(f"已参考 {pois[0].get('name', 'POI')} 营业时间 {pois[0]['openingHours']}。")
        if route.get("durationMinutes"):
            risks.append(f"当前路线预计 {route['durationMinutes']} 分钟，出行中可按体力切换备选方案。")
        return {
            "title": "重庆两日轻松夜景线",
            "destination": "重庆",
            "dateRange": "周末两天",
            "profileMatches": profile_matches,
            "days": [
                {
                    "dayLabel": "第一天 - 山城慢逛",
                    "items": [
                        {
                            "time": "10:30",
                            "location": "解放碑",
                            "activity": "轻量城市漫步和午餐",
                            "reason": "到达后先适应节奏，不安排高强度爬坡。",
                        },
                        {
                            "time": "15:30",
                            "location": "山城步道",
                            "activity": "慢走拍照，体验重庆层次感",
                            "reason": "路线短、画面强，适合轻松体验山城特色。",
                        },
                        {
                            "time": "19:00",
                            "location": "洪崖洞",
                            "activity": "看夜景并拍摄高光照片",
                            "reason": "匹配你喜欢夜景的长期偏好。",
                        },
                    ],
                },
                {
                    "dayLabel": "第二天 - 观景与收尾",
                    "items": [
                        {
                            "time": "10:00",
                            "location": "鹅岭二厂",
                            "activity": "文创街区轻松闲逛",
                            "reason": "不赶早，适合慢节奏拍照。",
                        },
                        {
                            "time": "17:30",
                            "location": "南山一棵树",
                            "activity": "傍晚观景",
                            "reason": "补一个视野更开阔的夜景点。",
                        },
                    ],
                },
            ],
            "risks": risks,
            "alternatives": [
                {
                    "id": "alt-rainy-day",
                    "title": "雨天室内轻松版",
                    "summary": "减少山城步道停留，改去三峡博物馆和来福士室内观景。",
                    "bestFor": "下雨或体力下降时",
                },
                {
                    "id": "alt-crowd-avoidance",
                    "title": "避开洪崖洞高峰版",
                    "summary": "先去南山一棵树看远景，再晚一点回到洪崖洞周边散步。",
                    "bestFor": "周末晚间人流过高时",
                },
            ],
            "externalContext": tool_context,
            "navigationLinks": [
                {
                    "provider": "amap",
                    "label": "打开高德导航到洪崖洞",
                    "url": "androidamap://route?sourceApplication=lanxin-travelmate&dname=洪崖洞&dev=0&t=0",
                }
            ],
        }