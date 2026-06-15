from copy import deepcopy
from typing import Any

from app.agents.travelmate.state import TravelMateState
from app.services.model_providers import MockModelProvider
from app.tools.registry import build_mock_tool_registry


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


def input_normalizer(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "input_normalizer")
    next_state["normalized_input"] = state["message"].strip()
    return next_state


def context_loader(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "context_loader")
    next_state["user_profile"] = {
        "dietaryPreferences": ["不吃香菜"],
        "travelPace": "慢节奏",
        "interestTags": ["夜景", "山城步道", "轻量美食"],
    }
    return next_state


def intent_router(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "intent_router")
    text = next_state["normalized_input"]
    if _contains_any(text, ["规划", "周末", "两天", "路线", "行程"]):
        next_state["intent"] = "trip_planning"
    elif _contains_any(text, ["复盘", "总结"]):
        next_state["intent"] = "trip_review"
    else:
        next_state["intent"] = "companion_chat"
    return next_state


def memory_extractor(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "memory_extractor")
    text = next_state["normalized_input"]
    candidates: list[dict[str, Any]] = []
    if "不吃香菜" in text or "香菜" in text:
        candidates.append({
            "id": "mem-cilantro",
            "title": "不吃香菜",
            "content": "用户明确表示不吃香菜，后续餐厅和菜品推荐需要避开。",
            "scopeOptions": ["longTerm", "currentTrip", "temporary", "ignore"],
            "recommendedScope": "longTerm",
            "reason": "这是稳定饮食偏好，会长期影响餐饮推荐。",
        })
    if "夜景" in text:
        candidates.append({
            "id": "mem-night-view",
            "title": "喜欢夜景",
            "content": "用户偏好夜景路线，规划时优先保留傍晚和夜间观景点。",
            "scopeOptions": ["longTerm", "currentTrip", "temporary", "ignore"],
            "recommendedScope": "longTerm",
            "reason": "这是可复用的旅行兴趣偏好。",
        })
    if _contains_any(text, ["不想太累", "慢一点", "轻松"]):
        candidates.append({
            "id": "mem-slow-pace",
            "title": "本次旅行想轻松一点",
            "content": "用户本次行程希望低强度，减少跨区移动和密集景点。",
            "scopeOptions": ["currentTrip", "temporary", "ignore"],
            "recommendedScope": "currentTrip",
            "reason": "这更像本次旅行约束，先按本次行程保存。",
        })
    next_state["memory_candidates"] = candidates
    return next_state


def memory_confirm_interrupt(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "memory_confirm_interrupt")
    if next_state["memory_candidates"]:
        next_state["sync_suggestions"].append({
            "type": "memoryConfirmation",
            "title": "发现新的旅行偏好",
            "description": "保存前需要用户确认记忆范围。",
        })
    return next_state


def memory_writer(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "memory_writer")
    next_state["context"]["pendingMemoryCount"] = len(next_state["memory_candidates"])
    confirmed_memories = next_state["context"].get("confirmedMemories") or []
    wants_slow_pace = any(item["id"] == "mem-slow-pace" for item in next_state["memory_candidates"])
    had_fast_pace = any(
        "特种兵" in item.get("title", "") or "特种兵" in item.get("content", "")
        for item in confirmed_memories
    )
    if wants_slow_pace and had_fast_pace:
        conflict = {
            "id": "conflict-pace",
            "previousPreference": "喜欢特种兵路线",
            "currentPreference": "本次旅行想轻松一点",
            "resolution": "本次行程优先按低强度规划，长期画像不直接覆盖，复盘时再询问是否调整长期偏好。",
        }
        next_state["memory_conflicts"] = [conflict]
        next_state["sync_suggestions"].append({
            "type": "memoryConflict",
            "title": "发现节奏偏好变化",
            "description": conflict["resolution"],
            "conflictId": conflict["id"],
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


def trip_context_builder(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "trip_context_builder")
    next_state["trip_context"] = {
        "destination": "重庆",
        "durationDays": 2,
        "pace": "轻松",
        "mustKeep": ["洪崖洞夜景", "山城步道"],
    }
    return next_state


def tool_planner(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "tool_planner")
    next_state["tool_plan"] = [
        {"tool": "weather_tool", "input": {"city": "重庆"}},
        {"tool": "poi_tool", "input": {"city": "重庆", "keyword": "夜景"}},
        {"tool": "route_tool", "input": {"city": "重庆", "pace": "轻松"}},
    ]
    return next_state


def tool_executor(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "tool_executor")
    registry = build_mock_tool_registry()
    trace = []
    for item in next_state["tool_plan"]:
        trace.append({
            "tool": item["tool"],
            "input": item["input"],
            "output": registry.call(item["tool"], item["input"]),
            "mock": True,
        })
    next_state["tool_trace"] = trace
    return next_state


def trip_planner(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "trip_planner")
    provider = MockModelProvider()
    next_state["trip_plan"] = provider.plan_trip(next_state)
    return next_state


def trip_adjuster(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "trip_adjuster")
    next_state["trip_plan"]["dynamicAdjustment"] = {
        "trigger": "洪崖洞排队较长",
        "suggestion": "先去附近轻量景点，再回到洪崖洞看夜景。",
    }
    return next_state


def reminder_checker(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "reminder_checker")
    reminders = [
        {
            "id": "reminder-dinner",
            "title": "先吃饭再看夜景",
            "triggerType": "time",
            "description": "18:00 后洪崖洞周边人流上升，建议先在解放碑附近吃饭。",
            "cooldownMinutes": 90,
        },
        {
            "id": "reminder-location",
            "title": "已接近洪崖洞",
            "triggerType": "location",
            "description": "当前位置适合步行到观景点，蓝小心已帮你避开最挤路线。",
            "cooldownMinutes": 60,
        },
    ]
    trigger_type = next_state["context"].get("triggerType")
    event_payload = next_state["context"].get("eventPayload") or {}
    if trigger_type == "behavior":
        reminders.append({
            "id": "reminder-new-photo",
            "title": "这张照片适合加入旅拍候选",
            "triggerType": "behavior",
            "description": "蓝小心发现你刚拍了夜景照片，可以先存入候选集，复盘时生成配文。",
            "cooldownMinutes": 45,
            "event": event_payload.get("event", "newPhoto"),
        })
    if trigger_type == "status":
        reminders.append({
            "id": "reminder-low-energy",
            "title": "蓝小心建议放慢一点",
            "triggerType": "status",
            "description": "当前精力偏低，建议把下一个景点改为附近轻量休息点。",
            "cooldownMinutes": 60,
            "energy": event_payload.get("energy", 35),
        })
    if trigger_type == "external":
        reminders.append({
            "id": "reminder-weather-change",
            "title": "天气变化，路线需要备选",
            "triggerType": "external",
            "description": "天气或排队情况发生变化，蓝小心已准备雨天室内轻松版备选方案。",
            "cooldownMinutes": 90,
            "event": event_payload.get("event", "weatherChanged"),
        })
    next_state["reminders"] = reminders
    return next_state


def photo_analyzer(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "photo_analyzer")
    next_state["photo_candidates"] = [
        {
            "id": "photo-night",
            "location": "洪崖洞",
            "score": 9.3,
            "description": "夜景灯光层次明显，适合做今日高光。",
        }
    ]
    return next_state


def copywriter(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "copywriter")
    next_state["next_actions"] = [
        {"type": "confirmMemory", "label": "确认记忆胶囊"},
        {"type": "openTripPlan", "label": "查看两日路线"},
        {"type": "simulateReminder", "label": "模拟主动提醒"},
        {"type": "openReview", "label": "生成旅行复盘"},
    ]
    return next_state


def review_generator(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "review_generator")
    completed_tasks = next_state["context"].get("completedTasks") or [
        {
            "id": "task-night-photo",
            "title": "拍一张不是游客照的重庆夜景",
            "status": "completed",
            "reward": "好感度 +2",
            "impact": "进入今日高光照片与复盘故事线。",
        },
        {
            "id": "task-local-snack",
            "title": "找一家不用香菜也好吃的小店",
            "status": "completed",
            "reward": "默契值 +1",
            "impact": "强化了餐饮避雷偏好。",
        },
    ]
    temporary_memories = next_state["context"].get("temporaryMemories") or [
        {
            "id": "mem-slow-pace",
            "title": "本次旅行想轻松一点",
            "content": "用户本次行程希望低强度，减少跨区移动和密集景点。",
        }
    ]
    promotions = [
        {
            "id": item.get("id", "temp-memory"),
            "title": item.get("title", "本次旅行偏好"),
            "content": item.get("content", "这条临时记忆在本次旅行中反复出现，可考虑长期保存。"),
            "suggestedScope": "longTerm",
            "reason": "这条临时记忆已经影响规划、提醒和复盘，建议询问用户是否转为长期记忆。",
        }
        for item in temporary_memories
    ]
    next_state["completed_tasks"] = completed_tasks
    next_state["temporary_memory_promotions"] = promotions
    next_state["review"] = {
        "route": "解放碑 → 山城步道 → 洪崖洞 → 南山一棵树",
        "highlightPhotos": ["洪崖洞夜景"],
        "newMemories": [item["title"] for item in next_state["memory_candidates"]],
        "completedTasks": completed_tasks,
        "avatarStatusChanges": ["默契值 +1", "好感度 +2", "精力 -5"],
        "nextTripSuggestions": ["成都慢节奏美食线", "长沙夜景与小吃线"],
        "temporaryMemoryPromotions": promotions,
    }
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


NODE_TABLE = {
    "input_normalizer": input_normalizer,
    "context_loader": context_loader,
    "intent_router": intent_router,
    "memory_extractor": memory_extractor,
    "memory_confirm_interrupt": memory_confirm_interrupt,
    "memory_writer": memory_writer,
    "profile_updater": profile_updater,
    "trip_context_builder": trip_context_builder,
    "tool_planner": tool_planner,
    "tool_executor": tool_executor,
    "trip_planner": trip_planner,
    "trip_adjuster": trip_adjuster,
    "reminder_checker": reminder_checker,
    "photo_analyzer": photo_analyzer,
    "copywriter": copywriter,
    "review_generator": review_generator,
    "avatar_state_mapper": avatar_state_mapper,
    "response_composer": response_composer,
    "error_fallback": error_fallback,
}
