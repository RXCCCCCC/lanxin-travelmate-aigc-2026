import json

from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from app.agents.travelmate.graph import TravelMateGraph
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


def _route_agent_graph(graph: TravelMateGraph, state: dict[str, object]) -> dict[str, object]:
    message = str(state.get("message") or "")
    normalized_message = message.lower()
    if any(keyword in message for keyword in ("复盘", "总结")):
        result = graph.invoke_review_only(state)
        reply = "复盘已经生成，我把重点放在完成任务、照片高光和下次建议上。"
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
        return result
    if any(keyword in normalized_message for keyword in ("plan", "route", "itinerary", "destination", "weekend")):
        result = graph.invoke_plan_only(state)
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
            "nextActions": [{"type": "openTripPlan", "label": "查看行程详情"}],
            "syncSuggestions": [],
            "errors": result.get("errors", []),
        }
        return result
    if any(
        keyword in message
        for keyword in (
            "规划",
            "路线",
            "行程",
            "周末",
            "两天",
            "目的地",
            "攻略",
            "怎么玩",
            "怎么逛",
            "好玩",
            "景点",
            "去哪玩",
            "哪里玩",
            "推荐",
        )
    ) and not any(keyword in message for keyword in ("你好", "在吗")):
        result = graph.invoke_plan_only(state)
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
            "nextActions": [{"type": "openTripPlan", "label": "查看行程"}],
            "syncSuggestions": [],
            "errors": result.get("errors", []),
        }
        return result
    return graph.invoke_chat_only(state)


@router.post("/chat", response_model=AgentChatResponse)
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


@router.get("/avatar-state")
def read_avatar_state() -> dict[str, int | str]:
    return {
        "energy": 85,
        "mood": "planning",
        "curiosity": 76,
        "rapport": 13,
        "affection": 38,
    }
