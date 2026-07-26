import json
from collections.abc import Iterator

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlmodel import Session, select

from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.nodes.registry import (
    CHAT_ONLY_NODE_SEQUENCE,
    NODE_SEQUENCE,
    PLAN_ONLY_NODE_SEQUENCE,
    REVIEW_ONLY_NODE_SEQUENCE,
)
from app.agents.travelmate.nodes.fallback_nodes import build_rule_memory_candidates
from app.agents.travelmate.state import create_initial_state
from app.core.security import CurrentUser, get_current_user, resolve_effective_user_id
from app.db.models import CloudUserProfile
from app.db.session import get_session
from app.schemas.agent import AgentChatRequest, AgentChatResponse
from app.services.model_audit import persist_model_call_logs
from app.services.trip_plan_formatter import sanitize_trip_plan_for_client


router = APIRouter(prefix="/agent", tags=["agent"])


def _load_user_settings(session: Session, user_id: str | None) -> dict[str, object]:
    if not user_id:
        return {}
    profile = session.exec(select(CloudUserProfile).where(CloudUserProfile.user_id == user_id)).first()
    if not profile:
        return {}
    data = json.loads(profile.profile_json)
    return {
        key: data.get(key)
        for key in (
            "personality",
            "proactivityLevel",
            "syncStrategy",
            "notificationEnabled",
            "voiceEnabled",
            "textModePreferred",
            "customPrompt",
        )
        if key in data
    }


def _compact_text(value: object, fallback: str = "") -> str:
    text = str(value or "").strip()
    return text or fallback


def _safe_plan_reply_text(value: object, fallback: str = "") -> str:
    text = _compact_text(value)
    if not text:
        return fallback
    normalized = text.lower()
    if (
        "真实模型" in text
        or "模型返回" in text
        or "路线规划工具" in text
        or "缺少坐标" in text
        or "手动规划" in text
        or "route_tool" in normalized
        or "model_provider" in normalized
        or "model fallback" in normalized
        or "fallback model" in normalized
        or "provider=" in normalized
    ):
        return fallback
    english_letters = sum(1 for char in text if "a" <= char.lower() <= "z")
    chinese_chars = sum(1 for char in text if "\u4e00" <= char <= "\u9fff")
    if english_letters and not chinese_chars:
        return fallback
    return text


def _build_plan_chat_reply(plan: dict[str, object]) -> str:
    destination = _safe_plan_reply_text(plan.get("destination"), "这次旅行")
    title = _safe_plan_reply_text(plan.get("title"))
    summary = _safe_plan_reply_text(
        plan.get("summary"),
        "我会把路线安排成更稳妥的版本，并提醒你出发前结合天气、体力和地图 App 再确认。",
    )
    alternatives = plan.get("alternatives")
    first_alternative = alternatives[0] if isinstance(alternatives, list) and alternatives else {}
    alternative_title = ""
    alternative_summary = ""
    if isinstance(first_alternative, dict):
        alternative_title = _safe_plan_reply_text(first_alternative.get("title"))
        alternative_summary = _safe_plan_reply_text(
            first_alternative.get("summary"),
            "适合在天气变化、排队拥挤或体力不足时切换。",
        )

    parts = [f"蓝小心先替你把{destination}这趟行程捋顺了。"]
    if title:
        parts.append(f"主线我先定成{title}。")
    if summary:
        parts.append(summary)
    if alternative_title or alternative_summary:
        alternative = "：".join(part for part in (alternative_title, alternative_summary) if part)
        parts.append(f"我还顺手备了一条可切换方案，{alternative}")
    parts.append("你继续告诉我预算、节奏、同行人，或者哪类地方坚决不去，我就直接贴着你的偏好往下改。")
    return "".join(parts)


_PLAN_KEYWORDS_EN = ("plan", "route", "itinerary", "destination", "weekend")
_PLAN_KEYWORDS_CN = (
    "\u89c4\u5212",
    "\u8def\u7ebf",
    "\u884c\u7a0b",
    "\u5468\u672b",
    "\u4e24\u5929",
    "\u76ee\u7684\u5730",
    "\u653b\u7565",
    "\u600e\u4e48\u73a9",
    "\u600e\u4e48\u9009",
    "\u597d\u73a9",
    "\u666f\u70b9",
    "\u53bb\u54ea\u73a9",
    "\u54ea\u91cc\u73a9",
    "\u63a8\u8350",
)
_GREETING_KEYWORDS = ("\u4f60\u597d", "\u5728\u5417")
_REVIEW_KEYWORDS = ("\u590d\u76d8", "\u603b\u7ed3")


def _detect_route_mode(message: str) -> str:
    normalized = message.lower()
    if any(keyword in message for keyword in _REVIEW_KEYWORDS):
        return "review"
    if any(keyword in normalized for keyword in _PLAN_KEYWORDS_EN):
        return "plan"
    if any(keyword in message for keyword in _PLAN_KEYWORDS_CN) and not any(
        keyword in message for keyword in _GREETING_KEYWORDS
    ):
        return "plan"
    return "chat"


def _compose_review_response(result: dict[str, object]) -> None:
    reply = "\u590d\u76d8\u5df2\u7ecf\u751f\u6210\uff0c\u6211\u628a\u91cd\u70b9\u653e\u5728\u5b8c\u6210\u4efb\u52a1\u3001\u7167\u7247\u9ad8\u5149\u548c\u4e0b\u6b21\u5efa\u8bae\u4e0a\u3002"
    result["response"] = {
        "replyText": reply,
        "voiceText": reply,
        "avatarState": "after_playing",
        "emotion": "reflective",
        "cards": [{"type": "tripReview", "payload": result.get("review", {})}],
        "memoryCandidates": [],
        "toolTrace": result.get("tool_trace", []),
        "nextActions": [],
        "syncSuggestions": [],
        "errors": result.get("errors", []),
    }


def _compose_plan_response(result: dict[str, object], message: str) -> None:
    memory_candidates = build_rule_memory_candidates(message)
    trip_plan = sanitize_trip_plan_for_client(
        result.get("trip_plan", {}) if isinstance(result.get("trip_plan"), dict) else {},
        requested_destination=str(result.get("trip_context", {}).get("destination") or ""),
        message=message,
    )
    reply = _build_plan_chat_reply(trip_plan if isinstance(trip_plan, dict) else {})
    result["response"] = {
        "replyText": reply,
        "voiceText": reply,
        "avatarState": "planning",
        "emotion": "curious",
        "cards": [{"type": "tripPlan", "payload": trip_plan}],
        "memoryCandidates": memory_candidates,
        "toolTrace": result.get("tool_trace", []),
        "nextActions": [{"type": "openTripPlan", "label": "\u67e5\u770b\u884c\u7a0b"}],
        "syncSuggestions": [],
        "errors": result.get("errors", []),
    }


def _route_agent_graph(graph: TravelMateGraph, state: dict[str, object]) -> dict[str, object]:
    message = str(state.get("message") or "")
    mode = _detect_route_mode(message)
    if mode == "review":
        result = graph.invoke_review_only(state)
        _compose_review_response(result)
        return result
    if mode == "plan":
        result = graph.invoke_plan_only(state)
        _compose_plan_response(result, message)
        return result
    return graph.invoke_chat_only(state)


_NODE_STAGE_LABELS = {
    "input_normalizer": "\u7406\u89e3\u4f60\u7684\u9700\u6c42",
    "context_loader": "\u56de\u5fc6\u4f60\u7684\u65c5\u884c\u753b\u50cf",
    "intent_router": "\u5224\u65ad\u5982\u4f55\u5e2e\u4f60",
    "memory_extractor": "\u8bc6\u522b\u65b0\u7684\u65c5\u884c\u504f\u597d",
    "trip_context_builder": "\u6574\u7406\u884c\u7a0b\u7ea6\u675f",
    "tool_planner": "\u51c6\u5907\u5929\u6c14\u4e0e\u5730\u70b9\u67e5\u8be2",
    "tool_executor": "\u67e5\u8be2\u5b9e\u65f6\u5929\u6c14\u4e0e\u666f\u70b9",
    "trip_planner": "\u751f\u6210\u4e2a\u6027\u5316\u8def\u7ebf",
    "trip_adjuster": "\u4f18\u5316\u8def\u7ebf\u7ec6\u8282",
    "fast_chat_response": "\u7ec4\u7ec7\u56de\u590d",
    "review_generator": "\u751f\u6210\u65c5\u884c\u590d\u76d8",
    "response_composer": "\u6574\u7406\u56de\u590d",
}


_SEQUENCE_BY_STREAM_MODE = {
    "full": NODE_SEQUENCE,
    "plan": PLAN_ONLY_NODE_SEQUENCE,
    "review": REVIEW_ONLY_NODE_SEQUENCE,
    "chat": CHAT_ONLY_NODE_SEQUENCE,
}


def _stream_agent_events(
    graph: TravelMateGraph,
    state: dict[str, object],
    session: Session,
) -> Iterator[str]:
    message = str(state.get("message") or "")
    mode = _detect_route_mode(message)
    merged_state: dict[str, object] = dict(state)

    def _stage_event(node: str) -> str:
        payload = json.dumps(
            {"type": "stage", "node": node, "label": _NODE_STAGE_LABELS[node]},
            ensure_ascii=False,
        )
        return f"event: stage\ndata: {payload}\n\n"

    try:
        sequence = list(_SEQUENCE_BY_STREAM_MODE.get(mode, []))
        labeled = [name for name in sequence if name in _NODE_STAGE_LABELS]
        # 先推送第一个阶段，之后每完成一个节点推送下一个“正在进行”的阶段
        if labeled:
            yield _stage_event(labeled[0])
        for node_name, node_state in graph.stream_nodes(state, mode=mode):
            if isinstance(node_state, dict):
                merged_state.update(node_state)
            if node_name in labeled:
                index = labeled.index(node_name)
                if index + 1 < len(labeled):
                    yield _stage_event(labeled[index + 1])
        if mode == "review":
            _compose_review_response(merged_state)
        elif mode == "plan":
            _compose_plan_response(merged_state, message)
        elif "response" not in merged_state:
            merged_state["response"] = {
                "replyText": "\u6211\u5148\u7528\u79bb\u7ebf\u6a21\u5f0f\u966a\u4f60\u89c4\u5212\u3002",
                "voiceText": "",
                "avatarState": "thinking",
                "emotion": "fallback",
                "cards": [],
                "memoryCandidates": [],
                "toolTrace": merged_state.get("tool_trace", []),
                "nextActions": [],
                "syncSuggestions": [],
                "errors": [{"code": "GRAPH_EMPTY_RESPONSE", "message": "\u672a\u751f\u6210\u6b63\u5f0f\u54cd\u5e94"}],
            }
        persist_model_call_logs(session, merged_state.get("model_call_logs", []))
        response = AgentChatResponse.model_validate(merged_state["response"])
        payload = response.model_dump_json()
        yield f"event: final\ndata: {payload}\n\n"
    except Exception as exc:  # noqa: BLE001 - \u6d41\u5f0f\u901a\u9053\u5185\u5fc5\u987b\u81ea\u884c\u5151\u5e95
        payload = json.dumps(
            {"type": "error", "message": str(exc)[:200]},
            ensure_ascii=False,
        )
        yield f"event: error\ndata: {payload}\n\n"


@router.post("/chat", response_model=AgentChatResponse, summary="Agent 聊天（非流式）")
def chat(
    request: AgentChatRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> AgentChatResponse:
    graph = TravelMateGraph()
    effective_user_id = resolve_effective_user_id(request.userId, current_user)
    context = dict(request.context or {})
    user_settings = _load_user_settings(session, effective_user_id)
    if user_settings:
        context["userSettings"] = user_settings
    state = create_initial_state(
        message=request.message,
        session_id=request.sessionId,
        user_id=effective_user_id,
        trip_id=request.tripId,
        context=context,
    )
    result = _route_agent_graph(graph, state)
    persist_model_call_logs(session, result.get("model_call_logs", []))
    return AgentChatResponse.model_validate(result["response"])


@router.post("/chat/stream", summary="Agent 聊天（SSE 流式）")
def chat_stream(
    request: AgentChatRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> StreamingResponse:
    """SSE \u6d41\u5f0f\u7248\u804a\u5929\uff1a\u5148\u63a8\u9001\u9010\u8282\u70b9\u9636\u6bb5\u4e8b\u4ef6\uff0c\u6700\u540e\u63a8\u9001\u5b8c\u6574\u54cd\u5e94\u3002"""
    graph = TravelMateGraph()
    effective_user_id = resolve_effective_user_id(request.userId, current_user)
    context = dict(request.context or {})
    user_settings = _load_user_settings(session, effective_user_id)
    if user_settings:
        context["userSettings"] = user_settings
    state = create_initial_state(
        message=request.message,
        session_id=request.sessionId,
        user_id=effective_user_id,
        trip_id=request.tripId,
        context=context,
    )
    return StreamingResponse(
        _stream_agent_events(graph, state, session),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@router.get("/avatar-state", summary="蓝小心状态查询")
def read_avatar_state() -> dict[str, int | str]:
    return {
        "energy": 85,
        "mood": "planning",
        "curiosity": 76,
        "rapport": 13,
        "affection": 38,
    }
