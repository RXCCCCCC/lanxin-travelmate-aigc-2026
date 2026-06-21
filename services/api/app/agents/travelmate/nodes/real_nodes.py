"""真实节点：通过 build_model_provider() 调用 LLM 完成核心推理。

当 Provider 不可用或返回 fallback 时，自动降级到 fallback_nodes.py 的规则实现。
"""

from typing import Any

from app.agents.travelmate.nodes.common import (
    MECHANICAL_NODE_TABLE,
    _contains_any,
    _next_state,
)
from app.agents.travelmate.nodes.fallback_nodes import (
    FALLBACK_NODE_TABLE as _FALLBACK,
)
from app.agents.travelmate.prompts.templates import build_prompt_bundle
from app.agents.travelmate.schemas.model_outputs import (
    CopywriterOutput,
    IntentRoutingOutput,
    MemoryExtractionOutput,
    MemoryWriterOutput,
    ReminderCheckOutput,
    ReviewOutput,
    ToolPlanningOutput,
    TripAdjustmentOutput,
    TripContextOutput,
    TripPlanningOutput,
    get_schema,
)
from app.agents.travelmate.state import TravelMateState
from app.core.config import get_settings
from app.services.model_providers import (
    ModelProviderConfigError,
    ModelProviderError,
    build_model_provider,
)

# ── 通用调用助手 ────────────────────────────────────────────────────────────


def _try_llm(
    state: TravelMateState,
    node_name: str,
    scenario: str,
    payload: dict[str, Any],
) -> tuple[TravelMateState, dict[str, Any] | None]:
    """尝试调用 LLM，返回 (next_state, result_or_none)。

    如果 LLM 不可用、返回 fallback 或出错，result 为 None。
    """
    next_state = _next_state(state, node_name)
    schema = get_schema(scenario)
    bundle = build_prompt_bundle(scenario, payload, schema)
    settings = get_settings()
    try:
        provider = build_model_provider(settings)
        result = provider.generate_json(
            scenario=bundle.scenario,
            system_prompt=bundle.system,
            user_prompt=bundle.user,
            schema=bundle.response_schema,
        )
    except (ModelProviderError, ModelProviderConfigError):
        return next_state, None
    if result.get("fallback"):
        return next_state, None
    return next_state, result


# ── 真实节点实现 ────────────────────────────────────────────────────────────


def context_loader(state: TravelMateState) -> TravelMateState:
    """加载用户画像。

    真实路径尝试从 context 中提取已持久化的 profile；无可用数据时降级。
    """
    next_state = _next_state(state, "context_loader")
    ctx = next_state.get("context", {})
    profile = ctx.get("userProfile") or ctx.get("profile")
    if isinstance(profile, dict) and profile:
        next_state["user_profile"] = profile
        return next_state
    return _FALLBACK["context_loader"](state)


def intent_router(state: TravelMateState) -> TravelMateState:
    text = next_state["normalized_input"] if (next_state := _next_state(state, "")) else state["normalized_input"]
    next_state, result = _try_llm(
        state, "intent_router",
        scenario="intent_routing",
        payload={"user_message": text},
    )
    if result is None:
        return _FALLBACK["intent_router"](state)
    try:
        parsed = IntentRoutingOutput.model_validate(result)
        next_state["intent"] = parsed.intent
        return next_state
    except Exception:
        return _FALLBACK["intent_router"](state)


def memory_extractor(state: TravelMateState) -> TravelMateState:
    next_state, result = _try_llm(
        state, "memory_extractor",
        scenario="memory_extraction",
        payload={
            "user_message": state.get("normalized_input", state.get("message", "")),
            "user_profile": state.get("user_profile", {}),
        },
    )
    if result is None:
        return _FALLBACK["memory_extractor"](state)
    try:
        parsed = MemoryExtractionOutput.model_validate(result)
        next_state["memory_candidates"] = [c.model_dump() for c in parsed.candidates]
        return next_state
    except Exception:
        return _FALLBACK["memory_extractor"](state)


def memory_writer(state: TravelMateState) -> TravelMateState:
    next_state, result = _try_llm(
        state, "memory_writer",
        scenario="memory_writing",
        payload={
            "new_candidates": state.get("memory_candidates", []),
            "confirmed_memories": state.get("context", {}).get("confirmedMemories", []),
            "existing_profile": state.get("user_profile", {}),
        },
    )
    if result is None:
        return _FALLBACK["memory_writer"](state)
    try:
        parsed = MemoryWriterOutput.model_validate(result)
        next_state["context"]["pendingMemoryCount"] = parsed.pendingMemoryCount or len(state.get("memory_candidates", []))
        if parsed.conflicts:
            next_state["memory_conflicts"] = [c.model_dump() for c in parsed.conflicts]
            for conflict in parsed.conflicts:
                next_state["sync_suggestions"].append({
                    "type": "memoryConflict",
                    "title": "发现节奏偏好变化",
                    "description": conflict.resolution,
                    "conflictId": conflict.id,
                })
        return next_state
    except Exception:
        return _FALLBACK["memory_writer"](state)


def trip_context_builder(state: TravelMateState) -> TravelMateState:
    next_state, result = _try_llm(
        state, "trip_context_builder",
        scenario="trip_context_building",
        payload={
            "user_message": state.get("normalized_input", state.get("message", "")),
            "user_profile": state.get("user_profile", {}),
            "intent": state.get("intent", ""),
        },
    )
    if result is None:
        return _FALLBACK["trip_context_builder"](state)
    try:
        parsed = TripContextOutput.model_validate(result)
        next_state["trip_context"] = {
            "destination": parsed.destination,
            "durationDays": parsed.durationDays,
            "pace": parsed.pace,
            "mustKeep": parsed.mustKeep,
            "budget": parsed.budget,
            "companions": parsed.companions,
        }
        return next_state
    except Exception:
        return _FALLBACK["trip_context_builder"](state)


def tool_planner(state: TravelMateState) -> TravelMateState:
    next_state, result = _try_llm(
        state, "tool_planner",
        scenario="tool_planning",
        payload={
            "intent": state.get("intent", ""),
            "trip_context": state.get("trip_context", {}),
        },
    )
    if result is None:
        return _FALLBACK["tool_planner"](state)
    try:
        parsed = ToolPlanningOutput.model_validate(result)
        if parsed.tools:
            next_state["tool_plan"] = [t.model_dump() for t in parsed.tools]
            return next_state
    except Exception:
        pass
    return _FALLBACK["tool_planner"](state)


def trip_planner(state: TravelMateState) -> TravelMateState:
    """规划节点：保留原有 real+fallback 模式并增强结构化校验。"""
    next_state, result = _try_llm(
        state, "trip_planner",
        scenario="trip_planning",
        payload={
            "trip_context": state.get("trip_context", {}),
            "user_profile": state.get("user_profile", {}),
            "tool_trace": state.get("tool_trace", []),
            "memory_candidates": state.get("memory_candidates", []),
        },
    )
    if result is None:
        return _FALLBACK["trip_planner"](state)
    try:
        parsed = TripPlanningOutput.model_validate(result)
        next_state["trip_plan"] = parsed.model_dump()
        next_state.setdefault("tool_trace", []).append({
            "tool": "model_provider",
            "provider": get_settings().model_provider,
            "fallback": False,
            "scenario": "trip_planning",
        })
        return next_state
    except Exception:
        return _FALLBACK["trip_planner"](state)


def trip_adjuster(state: TravelMateState) -> TravelMateState:
    next_state, result = _try_llm(
        state, "trip_adjuster",
        scenario="trip_adjustment",
        payload={
            "trip_plan": state.get("trip_plan", {}),
            "tool_trace": state.get("tool_trace", []),
            "trigger": state.get("context", {}).get("triggerType", ""),
        },
    )
    if result is None:
        return _FALLBACK["trip_adjuster"](state)
    try:
        parsed = TripAdjustmentOutput.model_validate(result)
        next_state["trip_plan"]["dynamicAdjustment"] = {
            "trigger": parsed.trigger,
            "suggestion": parsed.suggestion,
        }
        return next_state
    except Exception:
        return _FALLBACK["trip_adjuster"](state)


def reminder_checker(state: TravelMateState) -> TravelMateState:
    next_state, result = _try_llm(
        state, "reminder_checker",
        scenario="reminder_check",
        payload={
            "user_profile": state.get("user_profile", {}),
            "trip_context": state.get("trip_context", {}),
            "trip_plan": state.get("trip_plan", {}),
            "context": state.get("context", {}),
            "tool_trace": state.get("tool_trace", []),
        },
    )
    if result is None:
        return _FALLBACK["reminder_checker"](state)
    try:
        parsed = ReminderCheckOutput.model_validate(result)
        if parsed.reminders:
            next_state["reminders"] = [r.model_dump() for r in parsed.reminders]
            return next_state
    except Exception:
        pass
    return _FALLBACK["reminder_checker"](state)


def photo_analyzer(state: TravelMateState) -> TravelMateState:
    """照片分析：在无真实照片输入时直接降级。"""
    ctx = state.get("context", {})
    photos = ctx.get("photos") or ctx.get("photoUris") or []
    if not photos:
        return _FALLBACK["photo_analyzer"](state)
    next_state, result = _try_llm(
        state, "photo_analyzer",
        scenario="photo_analysis",
        payload={"photos": photos, "trip_context": state.get("trip_context", {})},
    )
    if result is None:
        return _FALLBACK["photo_analyzer"](state)
    try:
        from app.agents.travelmate.schemas.model_outputs import PhotoAnalysisOutput
        parsed = PhotoAnalysisOutput.model_validate(result)
        next_state["photo_candidates"] = [c.model_dump() for c in parsed.candidates]
        return next_state
    except Exception:
        return _FALLBACK["photo_analyzer"](state)


def copywriter(state: TravelMateState) -> TravelMateState:
    next_state, result = _try_llm(
        state, "copywriter",
        scenario="copywriting",
        payload={
            "intent": state.get("intent", ""),
            "trip_plan": state.get("trip_plan", {}),
            "memory_candidates": state.get("memory_candidates", []),
            "reminders": state.get("reminders", []),
            "user_profile": state.get("user_profile", {}),
        },
    )
    if result is None:
        return _FALLBACK["copywriter"](state)
    try:
        parsed = CopywriterOutput.model_validate(result)
        next_state["next_actions"] = [a.model_dump() for a in parsed.nextActions]
        if parsed.replyText:
            next_state["_copywriter_reply"] = parsed.replyText
        return next_state
    except Exception:
        return _FALLBACK["copywriter"](state)


def review_generator(state: TravelMateState) -> TravelMateState:
    next_state, result = _try_llm(
        state, "review_generator",
        scenario="review_generation",
        payload={
            "completed_tasks": state.get("context", {}).get("completedTasks", []),
            "memory_candidates": state.get("memory_candidates", []),
            "trip_plan": state.get("trip_plan", {}),
            "tool_trace": state.get("tool_trace", []),
            "user_profile": state.get("user_profile", {}),
            "avatar_status": state.get("avatar_status", {}),
        },
    )
    if result is None:
        return _FALLBACK["review_generator"](state)
    try:
        parsed = ReviewOutput.model_validate(result)
        next_state["completed_tasks"] = parsed.completedTasks
        next_state["temporary_memory_promotions"] = [p.model_dump() for p in parsed.temporaryMemoryPromotions]
        next_state["review"] = {
            "route": parsed.route,
            "highlightPhotos": parsed.highlightPhotos,
            "newMemories": state.get("context", {}).get("newMemories") or [
                item["title"] for item in state.get("memory_candidates", [])
            ],
            "completedTasks": parsed.completedTasks,
            "reminderHighlights": parsed.reminderHighlights,
            "avatarStatusChanges": parsed.avatarStatusChanges,
            "nextTripSuggestions": parsed.nextTripSuggestions,
            "temporaryMemoryPromotions": next_state["temporary_memory_promotions"],
            "profileContext": state.get("context", {}).get("profileContext") or {},
        }
        return next_state
    except Exception:
        return _FALLBACK["review_generator"](state)


REAL_NODE_TABLE = {
    "context_loader": context_loader,
    "intent_router": intent_router,
    "memory_extractor": memory_extractor,
    "memory_writer": memory_writer,
    "trip_context_builder": trip_context_builder,
    "tool_planner": tool_planner,
    "trip_planner": trip_planner,
    "trip_adjuster": trip_adjuster,
    "reminder_checker": reminder_checker,
    "photo_analyzer": photo_analyzer,
    "copywriter": copywriter,
    "review_generator": review_generator,
    **MECHANICAL_NODE_TABLE,
}
