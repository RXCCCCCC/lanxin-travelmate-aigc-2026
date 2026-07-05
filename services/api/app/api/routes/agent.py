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
        destination = result.get("trip_plan", {}).get("destination", "this trip")
        reply = (
            f"I have prepared a travel plan for {destination}. "
            "You can keep adjusting budget, transport, or companions."
        )
        result["response"] = {
            "replyText": reply,
            "voiceText": reply,
            "avatarState": "planning",
            "emotion": "curious",
            "cards": [{"type": "tripPlan", "payload": result.get("trip_plan", {})}],
            "memoryCandidates": memory_candidates,
            "toolTrace": result.get("tool_trace", []),
            "nextActions": [{"type": "openTripPlan", "label": "View trip plan"}],
            "syncSuggestions": [],
            "errors": result.get("errors", []),
        }
        return result
    if any(keyword in message for keyword in ("规划", "路线", "行程", "周末", "两天", "目的地")) and not any(
        keyword in message for keyword in ("你好", "在吗")
    ):
        result = graph.invoke_plan_only(state)
        memory_candidates = build_rule_memory_candidates(message)
        destination = result.get("trip_plan", {}).get("destination", "这次旅行")
        reply = f"我已经按轻松节奏生成{destination}行程，你可以继续让我调整预算、交通或同行人安排。"
        result["response"] = {
            "replyText": reply,
            "voiceText": reply,
            "avatarState": "planning",
            "emotion": "curious",
            "cards": [{"type": "tripPlan", "payload": result.get("trip_plan", {})}],
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
