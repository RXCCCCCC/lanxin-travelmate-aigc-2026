import json
from uuid import uuid4

from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.state import create_initial_state
from app.db.models import CloudUserProfile, ModelCallLog, utc_now
from app.db.session import get_session
from app.schemas.agent import AgentChatRequest, AgentChatResponse


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


def _persist_model_call_logs(session: Session, records: list[dict[str, object]]) -> None:
    if not records:
        return
    for record in records:
        session.add(
            ModelCallLog(
                id=f"model-{uuid4().hex}",
                provider=str(record.get("provider") or "unknown"),
                scenario=str(record.get("scenario") or "unknown"),
                fallback=bool(record.get("fallback", False)),
                elapsed_ms=int(record.get("elapsedMs") or 0),
                error=str(record["error"]) if record.get("error") else None,
                request_summary_json=json.dumps(record.get("requestSummary") or {}, ensure_ascii=False),
                created_at=utc_now(),
            )
        )
    session.commit()

@router.post("/chat", response_model=AgentChatResponse)
def chat(request: AgentChatRequest, session: Session = Depends(get_session)) -> AgentChatResponse:
    graph = TravelMateGraph()
    context = dict(request.context or {})
    user_settings = _load_user_settings(session, request.userId)
    if user_settings:
        context["userSettings"] = user_settings
    state = create_initial_state(
        message=request.message,
        session_id=request.sessionId,
        user_id=request.userId,
        trip_id=request.tripId,
        context=context,
    )
    result = graph.invoke(state)
    _persist_model_call_logs(session, result.get("model_call_logs", []))
    return AgentChatResponse.model_validate(result["response"])


@router.get("/avatar-state")
def read_avatar_state() -> dict[str, int | str]:
    return {
        "energy": 85,
        "mood": "规划中",
        "curiosity": 76,
        "rapport": 13,
        "affection": 38,
    }
