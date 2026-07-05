from copy import deepcopy
import json
import re
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


def _planning_inputs(state: TravelMateState) -> dict[str, Any]:
    context = state.get("context", {})
    planning_inputs = context.get("planningInputs")
    return planning_inputs if isinstance(planning_inputs, dict) else {}


def _looks_like_date_fragment(text: str) -> bool:
    candidate = text.strip()
    if not candidate:
        return False
    if re.fullmatch(r"[0-9]{1,2}号", candidate):
        return True
    if re.fullmatch(r"[一二三四五六七八九十两]{1,3}号", candidate):
        return True
    if re.fullmatch(r"(?:[一二三四五六七八九十]|十[一二三四五六七八九]?|[0-9]{1,2})月", candidate):
        return True
    return False


def _strip_planning_instruction_noise(text: str) -> str:
    cleaned = text.strip()
    cleaned = re.sub(r"^(?:帮我|请|麻烦你|给我|能不能|可以)?(?:规划|安排|定制|做|生成)", "", cleaned)
    cleaned = re.sub(r"(?:行程|路线|旅游|旅行|游玩|攻略)$", "", cleaned)
    cleaned = re.sub(r"(?:一|两|二|三|四|五|六|七|八|九|十|[0-9]{1,2})天.*$", "", cleaned)
    cleaned = re.sub(r"(?:[一二三四五六七八九十两0-9]{1,3})号.*$", "", cleaned)
    return cleaned.strip(" ，。,.!！？?：:")



def _extract_destination_from_message(message: str) -> str | None:
    text = message.strip()
    if not text:
        return None

    explicit_patterns = [
        "^([\\u4e00-\\u9fffA-Za-z]{2,20})(?:行程|路线|旅行|旅游|攻略|周末游|轻松游|慢游|citywalk)",
        "\u76ee\u7684\u5730(?:\u662f|\u4e3a|:|\uff1a)?\\s*([\u4e00-\u9fffA-Za-z]{2,20})",
        "(?:\u89c4\u5212|\u5b89\u6392|\u5b9a\u5236)\\s*([\u4e00-\u9fffA-Za-z]{2,20}?)(?:\u884c\u7a0b|\u8def\u7ebf|\u65c5\u6e38|\u65c5\u884c|\u6e38\u73a9|\u653b\u7565|\u4e00\u5929|\u4e24\u5929|\u4e09\u5929|\u56db\u5929|\u4e94\u5929|\u5468\u672b|\uff0c|\u3002|,|\\.|!|\uff01|\\?|\uff1f|\\s|$)",
        "\u4e3a\\s*([\u4e00-\u9fffA-Za-z]{2,20}?)(?:\u89c4\u5212|\u5b89\u6392|\u5b9a\u5236)",
        "(?:\u53bb|\u5230)\\s*([\u4e00-\u9fffA-Za-z]{2,20}?)(?:\u4e24\u5929|\u4e09\u5929|\u56db\u5929|\u4e94\u5929|\u4e00\u5929|\u4e00\u5468|\u5468\u672b|\u65c5\u6e38|\u65c5\u884c|\u73a9|\u901b|\u51fa\u5dee|\uff0c|\u3002|,|\\.|!|\uff01|\\?|\uff1f|\\s|$)",
    ]
    for pattern in explicit_patterns:
        match = re.search(pattern, text)
        if match:
            destination = _strip_planning_instruction_noise(match.group(1))
            if len(destination) >= 2 and not _looks_like_date_fragment(destination):
                return destination

    stop_tokens = [
        "\u4e24\u5929",
        "\u4e09\u5929",
        "\u56db\u5929",
        "\u4e94\u5929",
        "\u4e00\u5929",
        "\u4e00\u5468",
        "\u5468\u672b",
        "\u65c5\u6e38",
        "\u65c5\u884c",
        "\u73a9",
        "\u901b",
        "\u51fa\u5dee",
        "\uff0c",
        "\u3002",
        ",",
        ".",
        " ",
    ]
    for marker in ("\u53bb", "\u5230"):
        index = text.find(marker)
        if index < 0:
            continue
        candidate = text[index + len(marker) :]
        end = len(candidate)
        for token in stop_tokens:
            token_index = candidate.find(token)
            if token_index >= 0:
                end = min(end, token_index)
        destination = _strip_planning_instruction_noise(candidate[:end])
        if len(destination) >= 2 and not _looks_like_date_fragment(destination):
            return destination
    return None


def _extract_trip_destination(state: TravelMateState) -> str:
    planning_inputs = _planning_inputs(state)
    destination = planning_inputs.get("destination")
    if isinstance(destination, str) and destination.strip():
        return destination.strip()
    from_message = _extract_destination_from_message(state.get("normalized_input") or state.get("message") or "")
    if from_message:
        return from_message
    return "\u5f85\u786e\u8ba4\u76ee\u7684\u5730"


def _extract_trip_pace(state: TravelMateState) -> str:
    text = state.get("normalized_input") or state.get("message") or ""
    planning_inputs = _planning_inputs(state)
    if planning_inputs.get("tripStyle") == "family_relaxed":
        return "\u8f7b\u677e"
    if _contains_any(text, ["\u4e0d\u60f3\u592a\u7d2f", "\u8f7b\u677e", "\u6162\u4e00\u70b9", "\u6162\u8282\u594f", "\u5c11\u8d70\u8def"]):
        return "\u8f7b\u677e"
    return "\u9002\u4e2d"


def _extract_trip_days(state: TravelMateState) -> int:
    text = state.get("normalized_input") or state.get("message") or ""
    for label, days in [("\u4e00\u5929", 1), ("\u4e24\u5929", 2), ("\u4e09\u5929", 3), ("\u56db\u5929", 4), ("\u4e94\u5929", 5)]:
        if label in text:
            return days
    return 2

def _parse_nested_json_object(value: object) -> dict[str, Any] | None:
    if isinstance(value, dict):
        return value
    if not isinstance(value, str):
        return None
    text = value.strip()
    if not text:
        return None
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        start = text.find("{")
        if start < 0:
            return None
        try:
            parsed, _ = json.JSONDecoder().raw_decode(text[start:])
        except json.JSONDecodeError:
            return None
    return parsed if isinstance(parsed, dict) else None


def _unwrap_provider_payload(payload: dict[str, Any]) -> dict[str, Any]:
    response = payload.get("response")
    if isinstance(response, dict):
        nested = _parse_nested_json_object(response.get("content"))
        if nested:
            return nested
    nested = _parse_nested_json_object(response)
    if nested:
        return nested
    return payload


def _normalize_memory_candidate(item: dict[str, Any], index: int) -> dict[str, Any]:
    title = str(item.get("title") or item.get("type") or f"Memory {index + 1}")
    content = str(item.get("content") or item.get("description") or title)
    category = str(item.get("category") or item.get("type") or "travel_preference")
    reason = item.get("reason")
    if not reason:
        location = item.get("location")
        tags = item.get("tags") if isinstance(item.get("tags"), list) else []
        tag_text = "、".join(str(tag) for tag in tags[:3]) if tags else "旅行偏好"
        location_text = f"，地点 {location}" if location else ""
        reason = f"模型识别到与 {tag_text} 相关的旅行记忆{location_text}。"
    recommended_scope = item.get("recommendedScope")
    if recommended_scope not in {"longTerm", "currentTrip", "temporary", "ignore"}:
        recommended_scope = "currentTrip"
    confidence = item.get("confidence")
    try:
        confidence_value = float(confidence)
    except (TypeError, ValueError):
        confidence_value = 0.62
    confidence_value = max(0.0, min(1.0, confidence_value))
    return {
        "title": title,
        "content": content,
        "category": category,
        "recommendedScope": recommended_scope,
        "confidence": confidence_value,
        "reason": str(reason),
    }


def _normalize_memory_payload(payload: dict[str, Any]) -> dict[str, Any]:
    unwrapped = _unwrap_provider_payload(payload)
    if "memoryExtraction" in unwrapped and isinstance(unwrapped.get("memoryExtraction"), dict):
        return unwrapped
    candidates = unwrapped.get("candidates")
    if isinstance(candidates, list):
        return {
            "memoryExtraction": {
                "candidates": [
                    _normalize_memory_candidate(item, index)
                    for index, item in enumerate(candidates)
                    if isinstance(item, dict)
                ]
            }
        }
    return unwrapped


def _normalize_trip_plan_payload(plan: dict[str, Any], state: TravelMateState) -> dict[str, Any]:
    unwrapped = _unwrap_provider_payload(plan)
    has_explicit_trip_planning = isinstance(unwrapped.get("tripPlanning"), dict)
    payload = unwrapped.get("tripPlanning") if has_explicit_trip_planning else unwrapped
    if not isinstance(payload, dict):
        raise ModelProviderError("model returned invalid trip plan payload")
    normalized = dict(payload)
    if not has_explicit_trip_planning:
        destination = str(normalized.get("destination") or _extract_trip_destination(state))
        normalized["destination"] = destination
        if not normalized.get("title"):
            normalized["title"] = f"{destination}行程建议"
        if not normalized.get("summary"):
            response_text = plan.get("response") if isinstance(plan.get("response"), str) else None
            normalized["summary"] = response_text or f"围绕{destination}生成的旅行建议。"
    return normalized


def _normalize_chat_payload(payload: dict[str, Any], next_state: TravelMateState) -> dict[str, Any]:
    unwrapped = _unwrap_provider_payload(payload)
    if "chat" in unwrapped and isinstance(unwrapped.get("chat"), dict):
        return unwrapped
    reply_text = unwrapped.get("replyText")
    if not isinstance(reply_text, str) or not reply_text.strip():
        reply = unwrapped.get("reply")
        if isinstance(reply, str):
            reply_text = reply
    if not isinstance(reply_text, str) or not reply_text.strip():
        text_value = unwrapped.get("text")
        if isinstance(text_value, str):
            reply_text = text_value
    if not isinstance(reply_text, str) or not reply_text.strip():
        response_text = unwrapped.get("response")
        if isinstance(response_text, str):
            reply_text = response_text
    if isinstance(reply_text, str) and reply_text.strip():
        suggested_questions = unwrapped.get("suggestedQuestions") or unwrapped.get("suggestedUserInput")
        next_actions = unwrapped.get("nextActions") or next_state.get("next_actions", [])
        if isinstance(suggested_questions, list):
            next_actions = list(next_actions) + [
                {"type": "suggestedQuestion", "label": str(item)}
                for item in suggested_questions
                if str(item).strip()
            ]
        return {
            "chat": {
                "replyText": reply_text,
                "voiceText": str(unwrapped.get("voiceText") or reply_text),
                "avatarState": str(unwrapped.get("avatarState") or next_state.get("avatar_state") or "planning"),
                "emotion": str(unwrapped.get("emotion") or next_state.get("emotion") or "curious"),
                "cards": unwrapped.get("cards") or next_state.get("cards", []),
                "memoryCandidates": unwrapped.get("memoryCandidates") or next_state.get("memory_candidates", []),
                "toolTrace": unwrapped.get("toolTrace") or [],
                "nextActions": next_actions,
                "syncSuggestions": unwrapped.get("syncSuggestions") or next_state.get("sync_suggestions", []),
                "errors": unwrapped.get("errors") or next_state.get("errors", []),
            }
        }
    return unwrapped


def input_normalizer(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "input_normalizer")
    next_state["normalized_input"] = state["message"].strip()
    return next_state


def context_loader(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "context_loader")
    next_state["user_profile"] = {
        "dietaryPreferences": ["不吃香菜"],
        "travelPace": "慢节奏",
        "interestTags": ["夜景", "轻量美食"],
    }
    return next_state


def intent_router(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "intent_router")
    text = next_state["normalized_input"]
    if _contains_any(
        text,
        [
            "规划",
            "周末",
            "两天",
            "路线",
            "行程",
            "攻略",
            "怎么玩",
            "怎么逛",
            "好玩",
            "景点",
            "去哪玩",
            "哪里玩",
            "推荐",
        ],
    ):
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
    payload = _normalize_memory_payload(payload)
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


def _merge_memory_candidates(
    model_candidates: list[dict[str, Any]],
    rule_candidates: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    merged = list(model_candidates)
    seen_titles = {str(item.get("title", "")).strip() for item in model_candidates}
    for candidate in rule_candidates:
        title = str(candidate.get("title", "")).strip()
        if title and title not in seen_titles:
            merged.append(candidate)
            seen_titles.add(title)
    return merged


def memory_extractor(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "memory_extractor")
    text = next_state["normalized_input"]
    try:
        model_candidates = _model_memory_candidates(next_state)
        if model_candidates:
            next_state["memory_candidates"] = _merge_memory_candidates(
                model_candidates,
                build_rule_memory_candidates(text),
            )
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
    destination = _extract_trip_destination(next_state)
    must_keep = []
    text = next_state.get("normalized_input") or next_state.get("message") or ""
    if "\u591c\u666f" in text:
        must_keep.append("\u591c\u666f")
    if "\u4e0d\u60f3\u592a\u7d2f" in text or "\u5c11\u8d70\u8def" in text:
        must_keep.append("\u4f4e\u5f3a\u5ea6\u8def\u7ebf")
    next_state["trip_context"] = {
        "destination": destination,
        "durationDays": _extract_trip_days(next_state),
        "pace": _extract_trip_pace(next_state),
        "mustKeep": must_keep,
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
        or _extract_trip_destination(next_state)
    )
    transport_mode = str(planning_inputs.get("transportMode") or "walking")
    origin_location = _coordinate_to_location(planning_inputs.get("originCoordinate"))
    destination_location = _coordinate_to_location(planning_inputs.get("destinationCoordinate"))
    route_input = {
        "city": destination,
        "destination": destination,
        "pace": next_state.get("trip_context", {}).get("pace") or "\u8f7b\u677e",
        "mode": transport_mode,
    }
    if origin_location and destination_location:
        route_input["originLocation"] = origin_location
        route_input["destinationLocation"] = destination_location

    next_state["tool_plan"] = [
        {"tool": "weather_tool", "input": {"city": destination}},
        {"tool": "poi_tool", "input": {"city": destination, "keyword": "\u591c\u666f"}},
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


def _tool_context_from_trace(tool_trace: list[dict[str, Any]]) -> dict[str, Any]:
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
            context["pois"] = [item for item in (output.get("items") or []) if isinstance(item, dict)]
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


def _merge_trip_plan_tool_context(plan: dict[str, Any], state: TravelMateState) -> dict[str, Any]:
    merged = dict(plan)
    tool_context = _tool_context_from_trace(state.get("tool_trace", []))
    merged["externalContext"] = tool_context

    profile_matches = list(merged.get("profileMatches") or [])
    pois = tool_context.get("pois") or []
    if pois:
        poi = pois[0]
        opening_hours = poi.get("openingHours")
        name = poi.get("name") or "POI"
        if opening_hours and not any(str(opening_hours) in str(item) for item in profile_matches):
            profile_matches.append(f"已参考 {name} 营业时间 {opening_hours}。")
    merged["profileMatches"] = profile_matches

    risks = list(merged.get("risks") or [])
    weather = tool_context.get("weather") or {}
    travel_hint = weather.get("travelHint")
    if travel_hint and not any(str(travel_hint) in str(item) for item in risks):
        risks.append(f"天气提示：{travel_hint}")
    route = tool_context.get("route") or {}
    duration_minutes = route.get("durationMinutes")
    if duration_minutes and not any(str(duration_minutes) in str(item) for item in risks):
        risks.append(f"当前路线预计 {duration_minutes} 分钟，出行中可按体力切换备选方案。")
    merged["risks"] = risks

    return merged


def _enforce_requested_destination(plan: dict[str, Any], state: TravelMateState) -> dict[str, Any]:
    requested = str(state.get("trip_context", {}).get("destination") or _extract_trip_destination(state)).strip()
    if not requested or requested == "\u5f85\u786e\u8ba4\u76ee\u7684\u5730":
        return plan
    corrected = dict(plan)
    model_destination = str(corrected.get("destination") or "").strip()
    corrected["destination"] = requested
    if model_destination and model_destination != requested:
        for key in ("title", "summary"):
            value = corrected.get(key)
            if isinstance(value, str):
                corrected[key] = value.replace(model_destination, requested)
    planning_inputs = corrected.get("planningInputs")
    if isinstance(planning_inputs, dict):
        corrected["planningInputs"] = {**planning_inputs, "destination": requested}
    return corrected


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
        next_state["trip_plan"] = _enforce_requested_destination(
            _merge_trip_plan_tool_context(
                _validated_trip_plan(_normalize_trip_plan_payload(plan, next_state)),
                next_state,
            ),
            next_state,
        )
        timer.finish(fallback=False)
    except ValidationError as exc:
        fallback_provider = MockModelProvider()
        next_state["trip_plan"] = _enforce_requested_destination(
            fallback_provider.plan_trip(next_state),
            next_state,
        )
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
        next_state["trip_plan"] = _enforce_requested_destination(
            fallback_provider.plan_trip(next_state),
            next_state,
        )
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
    destination = str(next_state.get("trip_context", {}).get("destination") or _extract_trip_destination(next_state))
    next_state["trip_plan"]["dynamicAdjustment"] = {
        "trigger": f"{destination}\u5b9e\u65f6\u62e5\u6324\u6216\u5929\u6c14\u53d8\u5316",
        "suggestion": "\u4f18\u5148\u4fdd\u7559\u4f4e\u5f3a\u5ea6\u4f53\u9a8c\uff0c\u628a\u6392\u961f\u957f\u6216\u53d7\u5929\u6c14\u5f71\u54cd\u7684\u70b9\u4f4d\u8c03\u6574\u5230\u5907\u9009\u65f6\u6bb5\u3002",
    }
    return next_state

def reminder_checker(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "reminder_checker")
    destination = str(next_state.get("trip_context", {}).get("destination") or _extract_trip_destination(next_state))
    reminders = [
        {
            "id": "reminder-dinner",
            "title": "\u5148\u5b89\u6392\u8f7b\u91cf\u8865\u7ed9",
            "triggerType": "time",
            "description": f"\u5230\u996d\u70b9\u524d\u5148\u5728{destination}\u9644\u8fd1\u5b89\u6392\u4f4e\u8d1f\u62c5\u7528\u9910\uff0c\u907f\u514d\u540e\u7eed\u591c\u666f\u65f6\u6bb5\u4f53\u529b\u4e0b\u964d\u3002",
            "cooldownMinutes": 90,
        },
        {
            "id": "reminder-location",
            "title": "\u5df2\u63a5\u8fd1\u884c\u7a0b\u70b9\u4f4d",
            "triggerType": "location",
            "description": f"\u5f53\u524d\u4f4d\u7f6e\u9002\u5408\u8fdb\u5165{destination}\u7684\u4e0b\u4e00\u6bb5\u8def\u7ebf\uff0c\u84dd\u5c0f\u5fc3\u4f1a\u4f18\u5148\u907f\u5f00\u62e5\u6324\u548c\u8fc7\u957f\u6b65\u884c\u3002",
            "cooldownMinutes": 60,
        },
    ]
    trigger_type = next_state["context"].get("triggerType")
    event_payload = next_state["context"].get("eventPayload") or {}
    if trigger_type == "behavior":
        reminders.append({
            "id": "reminder-new-photo",
            "title": "\u8fd9\u5f20\u7167\u7247\u9002\u5408\u52a0\u5165\u65c5\u62cd\u5019\u9009",
            "triggerType": "behavior",
            "description": "\u84dd\u5c0f\u5fc3\u53d1\u73b0\u4f60\u521a\u62cd\u4e86\u53ef\u590d\u76d8\u7167\u7247\uff0c\u53ef\u4ee5\u5148\u5b58\u5165\u5019\u9009\u96c6\uff0c\u590d\u76d8\u65f6\u751f\u6210\u914d\u6587\u3002",
            "cooldownMinutes": 45,
            "event": event_payload.get("event", "newPhoto"),
        })
    if trigger_type == "status":
        reminders.append({
            "id": "reminder-low-energy",
            "title": "\u84dd\u5c0f\u5fc3\u5efa\u8bae\u653e\u6162\u4e00\u70b9",
            "triggerType": "status",
            "description": "\u5f53\u524d\u7cbe\u529b\u504f\u4f4e\uff0c\u5efa\u8bae\u628a\u4e0b\u4e00\u6bb5\u6539\u4e3a\u9644\u8fd1\u8f7b\u91cf\u4f11\u606f\u70b9\u6216\u4f4e\u5f3a\u5ea6\u8def\u7ebf\u3002",
            "cooldownMinutes": 60,
            "energy": event_payload.get("energy", 35),
        })
    if trigger_type == "external":
        reminders.append({
            "id": "reminder-weather-change",
            "title": "\u5916\u90e8\u60c5\u51b5\u53d8\u5316\uff0c\u8def\u7ebf\u9700\u8981\u5907\u9009",
            "triggerType": "external",
            "description": "\u5929\u6c14\u3001\u6392\u961f\u6216\u4ea4\u901a\u60c5\u51b5\u53d1\u751f\u53d8\u5316\uff0c\u84dd\u5c0f\u5fc3\u5df2\u51c6\u5907\u66f4\u7a33\u59a5\u7684\u5907\u9009\u65b9\u6848\u3002",
            "cooldownMinutes": 90,
            "event": event_payload.get("event", "weatherChanged"),
        })
    next_state["reminders"] = reminders
    return next_state

def photo_analyzer(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "photo_analyzer")
    destination = str(next_state.get("trip_context", {}).get("destination") or _extract_trip_destination(next_state))
    next_state["photo_candidates"] = [
        {
            "id": "photo-candidate-current-trip",
            "location": destination,
            "score": 8.0,
            "description": "\u57fa\u4e8e\u5f53\u524d\u884c\u7a0b\u7684\u65c5\u62cd\u5019\u9009\uff0c\u7b49\u5f85\u771f\u5b9e\u7167\u7247\u5206\u6790\u7ed3\u679c\u8865\u5145\u3002",
        }
    ]
    return next_state

def copywriter(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "copywriter")
    next_state["next_actions"] = [
        {"type": "confirmMemory", "label": "\u786e\u8ba4\u8bb0\u5fc6\u80f6\u56ca"},
        {"type": "openTripPlan", "label": "\u67e5\u770b\u884c\u7a0b\u8def\u7ebf"},
        {"type": "simulateReminder", "label": "\u6a21\u62df\u4e3b\u52a8\u63d0\u9192"},
        {"type": "openReview", "label": "\u751f\u6210\u65c5\u884c\u590d\u76d8"},
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
    status_changes = next_state["context"].get("avatarStatusChanges") or []
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


def _truncate_text(value: object, limit: int = 240) -> str | None:
    if value is None:
        return None
    text = str(value)
    if len(text) <= limit:
        return text
    return text[:limit] + "..."


def _compact_chat_state(next_state: TravelMateState) -> dict[str, Any]:
    trip_plan = next_state.get("trip_plan", {}) if isinstance(next_state.get("trip_plan"), dict) else {}
    memories = []
    for item in next_state.get("memory_candidates", [])[:5]:
        if isinstance(item, dict):
            memories.append({
                "title": _truncate_text(item.get("title"), 80),
                "content": _truncate_text(item.get("content"), 120),
                "category": item.get("category"),
            })
    return {
        "message": next_state.get("message"),
        "intent": next_state.get("intent"),
        "profile": next_state.get("user_profile", {}),
        "tripPlan": {
            "title": _truncate_text(trip_plan.get("title"), 120),
            "destination": trip_plan.get("destination"),
            "summary": _truncate_text(trip_plan.get("summary"), 300),
            "risks": (trip_plan.get("risks") or [])[:4],
            "profileMatches": (trip_plan.get("profileMatches") or [])[:4],
        },
        "memoryCandidates": memories,
        "avatarStatus": next_state.get("avatar_status", {}),
    }


def _model_chat_response(next_state: TravelMateState) -> dict[str, Any]:
    provider = build_model_provider(get_settings())
    payload = provider.generate_json(
        scenario="companion_chat",
        system_prompt="Return structured TravelMate chat response JSON only.",
        user_prompt=json.dumps(_compact_chat_state(next_state), ensure_ascii=False),
        schema={"task": "chat"},
    )
    payload = _normalize_chat_payload(payload, next_state)
    if "chat" not in payload:
        raise ModelProviderError("model output missing chat")
    output = ChatOutput.model_validate(payload["chat"])
    result = output.model_dump()
    result["cards"] = result["cards"] or next_state.get("cards", [])
    result["memoryCandidates"] = _merge_memory_candidates(
        result["memoryCandidates"] or [],
        next_state.get("memory_candidates", []),
    )
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


def fast_chat_response(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "fast_chat_response")
    text = str(next_state.get("normalized_input") or next_state.get("message") or "").strip()
    next_state["memory_candidates"] = build_rule_memory_candidates(text)
    next_state["avatar_state"] = "hello"
    next_state["emotion"] = "warm"
    next_state["next_actions"] = [
        {"type": "openTripPlan", "label": "需要时我可以继续帮你生成行程"},
        {"type": "openReview", "label": "旅行结束后我可以帮你复盘"},
    ]
    try:
        next_state["response"] = _model_chat_response(next_state)
        return next_state
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
    reply = "模型回复暂时没有返回，我先保留这轮上下文；你可以直接重试或继续补充目的地、预算和同行人。"
    next_state["response"] = {
        "replyText": reply,
        "voiceText": reply,
        "avatarState": "thinking",
        "emotion": "fallback",
        "cards": [],
        "memoryCandidates": next_state["memory_candidates"],
        "toolTrace": next_state.get("tool_trace", []),
        "nextActions": next_state["next_actions"],
        "syncSuggestions": next_state["sync_suggestions"],
        "errors": next_state["errors"] + [
            {"code": "MODEL_CHAT_FALLBACK", "message": "模型聊天回复暂时不可用。"}
        ],
    }
    return next_state


def response_composer(state: TravelMateState) -> TravelMateState:
    next_state = _next_state(state, "response_composer")
    trip_plan = next_state["trip_plan"]
    destination = str(trip_plan.get("destination") or _extract_trip_destination(next_state))
    reply = (
        f"\u6536\u5230\uff0c\u6211\u4f1a\u5148\u6309\u8f7b\u677e\u8282\u594f\u89c4\u5212{destination}\u884c\u7a0b\u3002"
        "\u591c\u666f\u4f1a\u4f18\u5148\u653e\u5728\u66f4\u9002\u5408\u89c2\u770b\u7684\u65f6\u6bb5\uff0c"
        "\u9910\u996e\u4e5f\u4f1a\u63d0\u9192\u907f\u5f00\u4f60\u5df2\u786e\u8ba4\u7684\u5fcc\u53e3\uff0c"
        "\u5982\u679c\u771f\u5b9e\u6a21\u578b\u6216\u5916\u90e8\u670d\u52a1\u6682\u65f6\u4e0d\u7a33\uff0c"
        "\u6211\u4e5f\u4f1a\u7528\u5f53\u524d\u8f93\u5165\u5148\u7ed9\u4f60\u53ef\u8c03\u6574\u7684\u7248\u672c\u3002"
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
    if get_settings().model_provider != "mock":
        try:
            next_state["response"] = _model_chat_response(next_state)
            next_state["response"]["replyText"] = reply
            next_state["response"]["voiceText"] = reply
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
        reply = "\u6211\u5148\u7528\u79bb\u7ebf\u6a21\u5f0f\u966a\u4f60\u89c4\u5212\uff0c\u7a0d\u540e\u518d\u540c\u6b65\u66f4\u5b8c\u6574\u7684\u8def\u7ebf\u3002"
        next_state["response"] = {
            "replyText": reply,
            "voiceText": reply,
            "avatarState": "thinking",
            "emotion": "fallback",
            "cards": [],
            "memoryCandidates": [],
            "toolTrace": next_state.get("tool_trace", []),
            "nextActions": [],
            "syncSuggestions": [],
            "errors": [{"code": "GRAPH_EMPTY_RESPONSE", "message": "\u672a\u751f\u6210\u6b63\u5f0f\u54cd\u5e94"}],
        }
    return next_state

