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


def _planning_inputs(state: dict[str, Any]) -> dict[str, Any]:
    context = state.get("context") if isinstance(state.get("context"), dict) else {}
    planning_inputs = context.get("planningInputs")
    return planning_inputs if isinstance(planning_inputs, dict) else {}


def _trip_context(state: dict[str, Any]) -> dict[str, Any]:
    trip_context = state.get("trip_context")
    return trip_context if isinstance(trip_context, dict) else {}


class MockModelProvider(ModelProvider):
    name = "mock"

    def generate_reply(self, prompt: str, context: dict[str, Any]) -> str:
        return f"\u84dd\u5c0f\u5fc3\u5df2\u6536\u5230\uff1a{prompt}"

    def generate_json(self, *, scenario: str, system_prompt: str, user_prompt: str, schema: dict[str, Any]) -> dict[str, Any]:
        return {
            "replyText": "\u84dd\u5c0f\u5fc3\u5df2\u7528\u79bb\u7ebf\u964d\u7ea7\u6a21\u5f0f\u751f\u6210\u7ed3\u6784\u5316\u7ed3\u679c\u3002",
            "fallback": True,
            "fallbackReason": "\u5f53\u524d\u4f7f\u7528 MockModelProvider\uff0c\u4ec5\u7528\u4e8e\u5f02\u5e38\u964d\u7ea7\u548c\u6d4b\u8bd5\u3002",
        }

    def plan_trip(self, state: dict[str, Any]) -> dict[str, Any]:
        tool_context = _tool_context(state.get("tool_trace") or [])
        trip_context = _trip_context(state)
        planning_inputs = _planning_inputs(state)
        destination = str(
            planning_inputs.get("destination")
            or trip_context.get("destination")
            or "\u5f85\u786e\u8ba4\u76ee\u7684\u5730"
        )
        duration_days = int(trip_context.get("durationDays") or 2)
        pace = str(trip_context.get("pace") or "\u9002\u4e2d")
        weather = tool_context.get("weather") or {}
        pois = tool_context.get("pois") or []
        route = tool_context.get("route") or {}

        profile_matches = [
            f"\u5df2\u6309{pace}\u8282\u594f\u7ec4\u7ec7{destination}\u884c\u7a0b\u3002",
            "\u4f18\u5148\u4fdd\u7559\u591c\u666f\u3001\u8f7b\u91cf\u6b65\u884c\u548c\u53ef\u4e34\u65f6\u8c03\u6574\u7684\u5b89\u6392\u3002",
            "\u9910\u996e\u63a8\u8350\u4f1a\u63d0\u9192\u5546\u5bb6\u907f\u5f00\u5df2\u786e\u8ba4\u5fcc\u53e3\u3002",
        ]
        risks = [
            f"{destination}\u70ed\u95e8\u533a\u57df\u5468\u672b\u53ef\u80fd\u62e5\u6324\uff0c\u5efa\u8bae\u4fdd\u7559\u9519\u5cf0\u548c\u5907\u9009\u70b9\u3002",
            "\u8def\u7ebf\u5f3a\u5ea6\u9700\u8981\u7ed3\u5408\u5f53\u5929\u4f53\u529b\u548c\u5929\u6c14\u518d\u786e\u8ba4\u3002",
            "\u771f\u5b9e\u6a21\u578b\u6216\u5916\u90e8\u670d\u52a1\u5f02\u5e38\u65f6\uff0c\u5f53\u524d\u65b9\u6848\u4e3a\u8f93\u5165\u9a71\u52a8\u7684\u964d\u7ea7\u89c4\u5212\u3002",
        ]
        if weather.get("travelHint"):
            risks.append(f"\u5929\u6c14\u63d0\u793a\uff1a{weather['travelHint']}")
        if pois and pois[0].get("openingHours"):
            profile_matches.append(f"\u5df2\u53c2\u8003 {pois[0].get('name', 'POI')} \u8425\u4e1a\u65f6\u95f4 {pois[0]['openingHours']}\u3002")
        if route.get("durationMinutes"):
            risks.append(f"\u5f53\u524d\u8def\u7ebf\u9884\u8ba1 {route['durationMinutes']} \u5206\u949f\uff0c\u51fa\u884c\u4e2d\u53ef\u6309\u4f53\u529b\u5207\u6362\u5907\u9009\u65b9\u6848\u3002")

        return {
            "title": f"{destination}{duration_days}\u65e5{pace}\u884c\u7a0b\u5efa\u8bae",
            "destination": destination,
            "summary": f"\u56f4\u7ed5{destination}\u751f\u6210\u7684{pace}\u964d\u7ea7\u884c\u7a0b\uff0c\u4f18\u5148\u51cf\u5c11\u6298\u8fd4\u5e76\u4fdd\u7559\u591c\u666f\u65f6\u95f4\u3002",
            "dateRange": f"{duration_days}\u5929",
            "profileMatches": profile_matches,
            "days": [
                {
                    "dayLabel": f"\u7b2c1\u5929 - {destination}\u8f7b\u91cf\u63a2\u7d22",
                    "items": [
                        {
                            "time": "10:30",
                            "location": destination,
                            "activity": "\u62b5\u8fbe\u540e\u8fdb\u884c\u8f7b\u91cf\u57ce\u5e02\u6f2b\u6b65\u548c\u5348\u9910",
                            "reason": "\u5148\u9002\u5e94\u8282\u594f\uff0c\u4e0d\u5b89\u6392\u9ad8\u5f3a\u5ea6\u79fb\u52a8\u3002",
                        },
                        {
                            "time": "15:30",
                            "location": "\u5c31\u8fd1\u666f\u70b9",
                            "activity": "\u9009\u62e9\u9644\u8fd1\u53ef\u6b65\u884c\u6216\u77ed\u4ea4\u901a\u62b5\u8fbe\u7684\u666f\u70b9",
                            "reason": "\u51cf\u5c11\u8de8\u533a\u79fb\u52a8\uff0c\u65b9\u4fbf\u6839\u636e\u4f53\u529b\u8c03\u6574\u3002",
                        },
                        {
                            "time": "19:00",
                            "location": f"{destination}\u591c\u666f\u533a\u57df",
                            "activity": "\u5b89\u6392\u591c\u666f\u6563\u6b65\u548c\u9ad8\u5149\u7167\u7247\u65f6\u95f4",
                            "reason": "\u5339\u914d\u591c\u666f\u504f\u597d\uff0c\u5e76\u4fdd\u7559\u8f7b\u677e\u8282\u594f\u3002",
                        },
                    ],
                },
                {
                    "dayLabel": f"\u7b2c{min(duration_days, 2)}\u5929 - \u5907\u9009\u4e0e\u6536\u5c3e",
                    "items": [
                        {
                            "time": "10:00",
                            "location": f"{destination}\u5ba4\u5185/\u6587\u521b\u5907\u9009\u70b9",
                            "activity": "\u6839\u636e\u5929\u6c14\u9009\u62e9\u5ba4\u5185\u6216\u4f4e\u5f3a\u5ea6\u4f53\u9a8c",
                            "reason": "\u4fdd\u7559\u96e8\u5929\u548c\u4f4e\u4f53\u529b\u72b6\u6001\u4e0b\u7684\u53ef\u6f14\u793a\u5907\u9009\u3002",
                        },
                        {
                            "time": "17:30",
                            "location": f"{destination}\u8fd4\u7a0b\u4fbf\u5229\u533a\u57df",
                            "activity": "\u5b89\u6392\u8f7b\u91cf\u6536\u5c3e\u548c\u8fd4\u7a0b\u7f13\u51b2",
                            "reason": "\u907f\u514d\u6700\u540e\u4e00\u5929\u8fc7\u5ea6\u8d76\u8def\u3002",
                        },
                    ],
                },
            ],
            "risks": risks,
            "alternatives": [
                {
                    "id": "alt-rainy-day",
                    "title": "\u96e8\u5929\u5ba4\u5185\u8f7b\u677e\u7248",
                    "summary": f"\u51cf\u5c11{destination}\u6237\u5916\u505c\u7559\uff0c\u6539\u4e3a\u5ba4\u5185\u5c55\u9986\u3001\u5546\u4e1a\u8857\u6216\u5496\u5561\u4f11\u606f\u70b9\u3002",
                    "bestFor": "\u4e0b\u96e8\u6216\u4f53\u529b\u4e0b\u964d\u65f6",
                },
                {
                    "id": "alt-crowd-avoidance",
                    "title": "\u907f\u5f00\u9ad8\u5cf0\u7248",
                    "summary": f"\u628a{destination}\u70ed\u95e8\u70b9\u8c03\u6574\u5230\u975e\u9ad8\u5cf0\u65f6\u6bb5\uff0c\u4f18\u5148\u8d70\u9644\u8fd1\u66ff\u4ee3\u70b9\u3002",
                    "bestFor": "\u5468\u672b\u665a\u95f4\u4eba\u6d41\u8fc7\u9ad8\u65f6",
                },
            ],
            "externalContext": tool_context,
            "navigationLinks": [
                {
                    "provider": "amap",
                    "label": f"\u6253\u5f00\u9ad8\u5fb7\u5bfc\u822a\u5230{destination}",
                    "url": f"androidamap://route?sourceApplication=lanxin-travelmate&dname={destination}&dev=0&t=0",
                }
            ],
        }
