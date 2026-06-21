from copy import deepcopy
from typing import Any

from pydantic import ValidationError

from app.agents.travelmate.nodes.fallback_nodes import (
    build_fallback_review_payload,
    build_rule_memory_candidates,
    default_completed_tasks,
    default_temporary_memories,
)
from app.agents.travelmate.schemas import ChatOutput, MemoryExtractionOutput, TripPlanningOutput, TripReviewOutput
from app.agents.travelmate.state import TravelMateState
from app.core.config import get_settings
from app.services.model_providers import MockModelProvider, ModelProviderError, build_model_provider
from app.services.model_providers.call_log import ModelCallLogger
from app.tools.registry import build_tool_registry


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


def _model_memory_candidates(next_state: TravelMateState) -> list[dict[str, Any]]:
    provider = build_model_provider(get_settings())
    payload = provider.generate_json(
        scenario="memory_extraction",
        system_prompt="Return structured travel memory candidates JSON only.",
        user_prompt=str({
            "message": next_state.get("normalized_input") or next_state.get("message"),
            "userId": next_state.get("user_id"),
            "tripId": next_state.get("trip_id"),
            "context": next_state.get("context", {}),
        }),
        schema={"task": "memoryExtraction"},
    )
    if "memoryExtraction" not in payload:
        raise ModelProviderError("model output missing memoryExtraction")
    output = MemoryExtractionOutput.model_validate(payload["memoryExtraction"])
    candidates: list[dict[str, Any]] = []
    for index, item in enumerate(output.candidates):
        candidate = item.model_dump()
        candidate.setdefault("id", f"model-memory-{index}")
        candidate.setdefault("scopeOptions", ["longTerm", "currentTrip", "temporary", "ignore"])
        candidate.setdefault("sensitivity", "personal" if candidate.get("category") == "dietary_preference" else "normal")
        candidate.setdefault("requiresExplicitConsent", True)
        candidate["provider"] = provider.name
        candidate["fallback"] = False
        candidates.append(candidate)
    return candidates


def _model_memory_trace(next_state: TravelMateState, *, provider: str, error_type: str, error: str) -> None:
    next_state.setdefault("tool_trace", []).append({
        "tool": "model_provider",
        "provider": provider,
        "scenario": "memory_extraction",
        "fallback": True,
        "errorType": error_type,
        "error": error,
    })


def memory_extractor(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "memory_extractor")
    text = next_state["normalized_input"]
    try:
        model_candidates = _model_memory_candidates(next_state)
        if model_candidates:
            next_state["memory_candidates"] = model_candidates
            next_state.setdefault("tool_trace", []).append({
                "tool": "model_provider",
                "provider": model_candidates[0].get("provider"),
                "scenario": "memory_extraction",
                "fallback": False,
            })
            return next_state
    except (AttributeError, ModelProviderError) as exc:
        _model_memory_trace(next_state, provider=get_settings().model_provider, error_type="provider_error", error=str(exc))
    except ValidationError as exc:
        provider_name = get_settings().model_provider
        try:
            provider_name = build_model_provider(get_settings()).name
        except ModelProviderError:
            pass
        _model_memory_trace(next_state, provider=provider_name, error_type="schema_validation", error=str(exc))
    next_state["memory_candidates"] = build_rule_memory_candidates(text)
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


def _coordinate_to_location(value: object) -> str | None:
    if not isinstance(value, dict):
        return None
    latitude = value.get("latitude")
    longitude = value.get("longitude")
    if latitude is None or longitude is None:
        return None
    return f"{longitude},{latitude}"


def tool_planner(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "tool_planner")
    planning_inputs = next_state.get("context", {}).get("planningInputs") or {}
    destination = str(
        planning_inputs.get("destination")
        or next_state.get("trip_context", {}).get("destination")
        or "重庆"
    )
    transport_mode = str(planning_inputs.get("transportMode") or "walking")
    origin_location = _coordinate_to_location(planning_inputs.get("originCoordinate"))
    destination_location = _coordinate_to_location(planning_inputs.get("destinationCoordinate"))
    route_input = {
        "city": destination,
        "destination": destination,
        "pace": next_state.get("trip_context", {}).get("pace") or "轻松",
        "mode": transport_mode,
    }
    if origin_location and destination_location:
        route_input["originLocation"] = origin_location
        route_input["destinationLocation"] = destination_location

    next_state["tool_plan"] = [
        {"tool": "weather_tool", "input": {"city": destination}},
        {"tool": "poi_tool", "input": {"city": destination, "keyword": "夜景"}},
        {"tool": "route_tool", "input": route_input},
    ]
    return next_state

def tool_executor(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "tool_executor")
    registry = build_tool_registry()
    trace = list(next_state.get("tool_trace", []))
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


def _validated_trip_plan(plan: dict[str, Any]) -> dict[str, Any]:
    payload = plan.get("tripPlanning") if isinstance(plan.get("tripPlanning"), dict) else plan
    validated = TripPlanningOutput.model_validate(payload)
    result = validated.model_dump()
    passthrough_keys = [
        "days",
        "dynamicAdjustment",
        "externalContext",
        "navigationLinks",
        "planningInputs",
    ]
    for key in passthrough_keys:
        if key in plan and key not in result:
            result[key] = plan[key]
    return result


def trip_planner(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "trip_planner")
    settings = get_settings()
    logger = ModelCallLogger()
    provider_name = settings.model_provider
    timer = logger.track(
        provider=provider_name,
        scenario="trip_planning",
        request_summary={
            "userId": next_state.get("user_id"),
            "tripId": next_state.get("trip_id"),
            "intent": next_state.get("intent"),
            "destination": next_state.get("trip_context", {}).get("destination"),
            "userSettings": next_state.get("context", {}).get("userSettings") or {},
        },
    )
    try:
        provider = build_model_provider(settings)
        plan = provider.plan_trip(next_state)
        if not isinstance(plan, dict):
            raise ModelProviderError("model returned non-dict trip plan")
        if "text" in plan:
            next_state.setdefault("errors", []).append({
                "code": "MODEL_JSON_PENDING",
                "message": "真实模型已返回内容，但结构化规划解析仍待接入，当前使用降级规划。",
            })
            raise ModelProviderError("模型返回结构暂未映射为 TripPlan。")
        next_state["trip_plan"] = _validated_trip_plan(plan)
        timer.finish(fallback=False)
    except ValidationError as exc:
        fallback_provider = MockModelProvider()
        next_state["trip_plan"] = fallback_provider.plan_trip(next_state)
        timer.finish(fallback=True, error=str(exc))
        next_state.setdefault("model_call_logs", []).extend(record.__dict__ for record in logger.records)
        next_state.setdefault("tool_trace", []).append({
            "tool": "model_provider",
            "provider": provider_name,
            "fallback": True,
            "scenario": "trip_planning",
            "errorType": "schema_validation",
            "error": str(exc),
        })
        return next_state
    except ModelProviderError as exc:
        fallback_provider = MockModelProvider()
        next_state["trip_plan"] = fallback_provider.plan_trip(next_state)
        timer.finish(fallback=True, error=str(exc))
        next_state.setdefault("model_call_logs", []).extend(record.__dict__ for record in logger.records)
        next_state.setdefault("tool_trace", []).append({
            "tool": "model_provider",
            "provider": provider_name,
            "fallback": True,
            "scenario": "trip_planning",
            "error": str(exc),
        })
        return next_state
    next_state.setdefault("model_call_logs", []).extend(record.__dict__ for record in logger.records)
    next_state.setdefault("tool_trace", []).append({
        "tool": "model_provider",
        "provider": provider_name,
        "fallback": False,
        "scenario": "trip_planning",
    })
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
    completed_tasks = next_state["context"].get("completedTasks") or default_completed_tasks()
    temporary_memories = next_state["context"].get("temporaryMemories") or default_temporary_memories()
    promotions = [
        {
            "id": item.get("id", "temp-memory"),
            "title": item.get("title", "\u672c\u6b21\u65c5\u884c\u504f\u597d"),
            "content": item.get("content", "\u8fd9\u6761\u4e34\u65f6\u8bb0\u5fc6\u5728\u672c\u6b21\u65c5\u884c\u4e2d\u53cd\u590d\u51fa\u73b0\uff0c\u53ef\u8003\u8651\u957f\u671f\u4fdd\u5b58\u3002"),
            "suggestedScope": "longTerm",
            "reason": "\u8fd9\u6761\u4e34\u65f6\u8bb0\u5fc6\u5df2\u7ecf\u5f71\u54cd\u89c4\u5212\u3001\u63d0\u9192\u548c\u590d\u76d8\uff0c\u5efa\u8bae\u8be2\u95ee\u7528\u6237\u662f\u5426\u8f6c\u4e3a\u957f\u671f\u8bb0\u5fc6\u3002",
        }
        for item in temporary_memories
    ]
    reminder_highlights = next_state["context"].get("reminderHighlights") or []
    status_changes = next_state["context"].get("avatarStatusChanges") or ["\u9ed8\u5951\u503c +1", "\u597d\u611f\u5ea6 +2", "\u7cbe\u529b -5"]
    if next_state["context"].get("completedTasks"):
        status_changes.append("\u76f2\u76d2\u4efb\u52a1\u5b8c\u6210\u5956\u52b1\u5df2\u8fdb\u5165\u590d\u76d8")
    if reminder_highlights:
        status_changes.append("\u63d0\u9192\u54cd\u5e94\u8bb0\u5f55\u5df2\u8fdb\u5165\u590d\u76d8")

    next_state["completed_tasks"] = completed_tasks
    next_state["temporary_memory_promotions"] = promotions
    next_state["context"]["reminderHighlights"] = reminder_highlights
    next_state["context"]["avatarStatusChanges"] = status_changes
    next_state["review"] = _review_with_model_or_fallback(next_state)
    return next_state



def _model_review_payload(next_state: TravelMateState) -> dict[str, Any]:
    provider = build_model_provider(get_settings())
    payload = provider.generate_json(
        scenario="trip_review",
        system_prompt="Return structured trip review JSON only.",
        user_prompt=str({
            "message": next_state.get("message"),
            "context": next_state.get("context", {}),
            "completedTasks": next_state.get("completed_tasks", []),
            "temporaryMemoryPromotions": next_state.get("temporary_memory_promotions", []),
        }),
        schema={"task": "tripReview"},
    )
    if "tripReview" not in payload:
        raise ModelProviderError("model output missing tripReview")
    output = TripReviewOutput.model_validate(payload["tripReview"])
    result = output.model_dump()
    result["provider"] = provider.name
    result["fallback"] = False
    result["errorType"] = None
    next_state.setdefault("tool_trace", []).append({
        "tool": "model_provider",
        "provider": provider.name,
        "scenario": "trip_review",
        "fallback": False,
    })
    return result


def _review_with_model_or_fallback(next_state: TravelMateState) -> dict[str, Any]:
    try:
        return _model_review_payload(next_state)
    except (AttributeError, ModelProviderError) as exc:
        review = build_fallback_review_payload(next_state)
        review.update({
            "provider": get_settings().model_provider,
            "fallback": True,
            "errorType": "provider_error",
            "fallbackReason": str(exc),
        })
        return review
    except ValidationError as exc:
        provider_name = get_settings().model_provider
        try:
            provider_name = build_model_provider(get_settings()).name
        except ModelProviderError:
            pass
        next_state.setdefault("tool_trace", []).append({
            "tool": "model_provider",
            "provider": provider_name,
            "scenario": "trip_review",
            "fallback": True,
            "errorType": "schema_validation",
            "error": str(exc),
        })
        review = build_fallback_review_payload(next_state)
        review.update({
            "provider": provider_name,
            "fallback": True,
            "errorType": "schema_validation",
            "fallbackReason": str(exc),
        })
        return review

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


def _append_chat_model_trace(next_state: TravelMateState, trace: dict[str, Any]) -> None:
    next_state.setdefault("tool_trace", []).append(trace)
    if "response" in next_state:
        next_state["response"]["toolTrace"] = next_state["tool_trace"]


def _model_chat_response(next_state: TravelMateState) -> dict[str, Any]:
    provider = build_model_provider(get_settings())
    payload = provider.generate_json(
        scenario="companion_chat",
        system_prompt="Return structured TravelMate chat response JSON only.",
        user_prompt=str({
            "message": next_state.get("message"),
            "intent": next_state.get("intent"),
            "profile": next_state.get("user_profile", {}),
            "tripPlan": next_state.get("trip_plan", {}),
            "memoryCandidates": next_state.get("memory_candidates", []),
            "avatarStatus": next_state.get("avatar_status", {}),
        }),
        schema={"task": "chat"},
    )
    if "chat" not in payload:
        raise ModelProviderError("model output missing chat")
    output = ChatOutput.model_validate(payload["chat"])
    result = output.model_dump()
    result["cards"] = result["cards"] or next_state.get("cards", [])
    result["memoryCandidates"] = result["memoryCandidates"] or next_state.get("memory_candidates", [])
    result["nextActions"] = result["nextActions"] or next_state.get("next_actions", [])
    result["syncSuggestions"] = result["syncSuggestions"] or next_state.get("sync_suggestions", [])
    result["errors"] = result["errors"] or next_state.get("errors", [])
    trace = list(next_state.get("tool_trace", [])) + list(result.get("toolTrace") or [])
    trace.append({
        "tool": "model_provider",
        "provider": provider.name,
        "scenario": "companion_chat",
        "fallback": False,
    })
    result["toolTrace"] = trace
    next_state["tool_trace"] = trace
    return result


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
    try:
        next_state["response"] = _model_chat_response(next_state)
    except (AttributeError, ModelProviderError) as exc:
        _append_chat_model_trace(next_state, {
            "tool": "model_provider",
            "provider": get_settings().model_provider,
            "scenario": "companion_chat",
            "fallback": True,
            "errorType": "provider_error",
            "error": str(exc),
        })
    except ValidationError as exc:
        provider_name = get_settings().model_provider
        try:
            provider_name = build_model_provider(get_settings()).name
        except ModelProviderError:
            pass
        _append_chat_model_trace(next_state, {
            "tool": "model_provider",
            "provider": provider_name,
            "scenario": "companion_chat",
            "fallback": True,
            "errorType": "schema_validation",
            "error": str(exc),
        })
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

