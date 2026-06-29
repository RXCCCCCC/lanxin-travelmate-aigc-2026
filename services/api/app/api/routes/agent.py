import json

from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from app.agents.travelmate.graph import TravelMateGraph
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
    result = graph.invoke(state)
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
