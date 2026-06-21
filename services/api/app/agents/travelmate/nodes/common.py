"""共享工具函数和纯机械节点（不依赖 LLM）。"""

from copy import deepcopy
from typing import Any

from app.agents.travelmate.state import TravelMateState
from app.tools.registry import build_tool_registry

NODE_SEQUENCE = [
    "input_normalizer",
    "context_loader",
    "intent_router",
    "memory_extractor",
    "memory_confirm_interrupt",
    "memory_writer",
    "profile_updater",
    "trip_context_builder",
    "tool_planner",
    "tool_executor",
    "trip_planner",
    "trip_adjuster",
    "reminder_checker",
    "photo_analyzer",
    "copywriter",
    "review_generator",
    "avatar_state_mapper",
    "response_composer",
    "error_fallback",
]


def _next_state(state: TravelMateState, node_name: str) -> TravelMateState:
    next_state = deepcopy(state)
    next_state.setdefault("visited_nodes", []).append(node_name)
    return next_state


def _contains_any(text: str, words: list[str]) -> bool:
    return any(word in text for word in words)


# ── 纯机械节点（不依赖 LLM，real/fallback 共用）─────────────────────────


def input_normalizer(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "input_normalizer")
    next_state["normalized_input"] = state["message"].strip()
    return next_state


def tool_executor(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "tool_executor")
    registry = build_tool_registry()
    trace = []
    for item in next_state["tool_plan"]:
        output = registry.call(item["tool"], item["input"])
        trace.append({
            "tool": item["tool"],
            "input": item["input"],
            "output": output,
            "provider": output.get("provider"),
            "fallback": bool(output.get("fallback")),
            "fallbackReason": output.get("fallbackReason"),
            "sourceTime": output.get("sourceTime"),
            "errorType": output.get("errorType"),
            "retryCount": int(output.get("retryCount") or 0),
            "cacheHit": bool(output.get("cacheHit")),
            "circuitOpen": bool(output.get("circuitOpen")),
            "mock": output.get("provider") == "mock",
        })
    next_state["tool_trace"] = trace
    return next_state


def memory_confirm_interrupt(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "memory_confirm_interrupt")
    if next_state["memory_candidates"]:
        next_state["sync_suggestions"].append({
            "type": "memoryConfirmation",
            "title": "发现新的旅行偏好",
            "description": "保存前需要用户确认记忆范围。",
        })
    sensitive_count = sum(
        1 for item in next_state["memory_candidates"] if item.get("sensitivity") == "sensitive"
    )
    if sensitive_count:
        next_state["sync_suggestions"].append({
            "type": "sensitiveMemoryConfirmation",
            "title": "发现敏感旅行信息",
            "description": "身体状态、位置和同行人信息只会在你明确确认后使用，默认不进入长期记忆。",
            "count": sensitive_count,
        })
    return next_state


def profile_updater(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "profile_updater")
    profile = next_state["user_profile"]
    for candidate in next_state["memory_candidates"]:
        if candidate["title"] == "喜欢夜景":
            profile.setdefault("interestTags", []).append("夜景优先")
        if candidate["title"] == "不吃香菜":
            profile.setdefault("dietaryPreferences", []).append("避开香菜")
    next_state["user_profile"] = profile
    return next_state


def avatar_state_mapper(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "avatar_state_mapper")
    status = next_state["avatar_status"]
    status["rapport"] += 1
    status["affection"] += 2
    status["energy"] = max(0, status["energy"] - 5)
    next_state["avatar_status"] = status
    next_state["avatar_state"] = "planning"
    next_state["emotion"] = "curious"
    return next_state


def response_composer(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "response_composer")
    trip_plan = next_state["trip_plan"]
    reply = (
        "收到，我会按轻松节奏规划重庆两天。因为你喜欢夜景，"
        "我把洪崖洞和南山观景放在傍晚后；因为你不吃香菜，"
        "餐厅建议会标注避开香菜；今天也会减少跨区移动。"
    )
    next_state["cards"] = [
        {"type": "tripPlan", "payload": trip_plan},
        {"type": "reminders", "payload": next_state["reminders"]},
        {"type": "tripReview", "payload": next_state["review"]},
    ]
    next_state["response"] = {
        "replyText": reply,
        "voiceText": reply,
        "avatarState": next_state["avatar_state"],
        "emotion": next_state["emotion"],
        "cards": next_state["cards"],
        "memoryCandidates": next_state["memory_candidates"],
        "toolTrace": next_state["tool_trace"],
        "nextActions": next_state["next_actions"],
        "syncSuggestions": next_state["sync_suggestions"],
        "errors": next_state["errors"],
    }
    return next_state


def error_fallback(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "error_fallback")
    if "response" not in next_state:
        next_state["response"] = {
            "replyText": "我先用离线模式陪你规划，稍后再同步更完整的路线。",
            "voiceText": "我先用离线模式陪你规划，稍后再同步更完整的路线。",
            "avatarState": "thinking",
            "emotion": "fallback",
            "cards": [],
            "memoryCandidates": [],
            "toolTrace": next_state.get("tool_trace", []),
            "nextActions": [],
            "syncSuggestions": [],
            "errors": [{"code": "GRAPH_EMPTY_RESPONSE", "message": "未生成正式响应"}],
        }
    return next_state


MECHANICAL_NODE_TABLE = {
    "input_normalizer": input_normalizer,
    "tool_executor": tool_executor,
    "memory_confirm_interrupt": memory_confirm_interrupt,
    "profile_updater": profile_updater,
    "avatar_state_mapper": avatar_state_mapper,
    "response_composer": response_composer,
    "error_fallback": error_fallback,
}
