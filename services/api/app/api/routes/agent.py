from fastapi import APIRouter

from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.state import create_initial_state
from app.schemas.agent import AgentChatRequest, AgentChatResponse


router = APIRouter(prefix="/agent", tags=["agent"])


@router.post("/chat", response_model=AgentChatResponse)
def chat(request: AgentChatRequest) -> AgentChatResponse:
    graph = TravelMateGraph()
    state = create_initial_state(
        message=request.message,
        session_id=request.sessionId,
        user_id=request.userId,
        trip_id=request.tripId,
        context=request.context,
    )
    result = graph.invoke(state)
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
