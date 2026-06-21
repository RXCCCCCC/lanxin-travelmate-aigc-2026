from typing import Any, TypedDict


class TravelMateState(TypedDict, total=False):
    message: str
    session_id: str | None
    user_id: str | None
    trip_id: str | None
    context: dict[str, Any]
    normalized_input: str
    intent: str
    memory_candidates: list[dict[str, Any]]
    memory_conflicts: list[dict[str, Any]]
    user_profile: dict[str, Any]
    trip_context: dict[str, Any]
    tool_plan: list[dict[str, Any]]
    tool_trace: list[dict[str, Any]]
    trip_plan: dict[str, Any]
    reminders: list[dict[str, Any]]
    photo_candidates: list[dict[str, Any]]
    completed_tasks: list[dict[str, Any]]
    temporary_memory_promotions: list[dict[str, Any]]
    review: dict[str, Any]
    avatar_status: dict[str, Any]
    avatar_state: str
    emotion: str
    cards: list[dict[str, Any]]
    next_actions: list[dict[str, Any]]
    sync_suggestions: list[dict[str, Any]]
    errors: list[dict[str, Any]]
    response: dict[str, Any]
    model_call_logs: list[dict[str, Any]]
    visited_nodes: list[str]


def create_initial_state(
    *,
    message: str,
    session_id: str | None = None,
    user_id: str | None = None,
    trip_id: str | None = None,
    context: dict[str, Any] | None = None,
) -> TravelMateState:
    return {
        "message": message,
        "session_id": session_id,
        "user_id": user_id or "guest",
        "trip_id": trip_id,
        "context": context or {},
        "memory_candidates": [],
        "memory_conflicts": [],
        "user_profile": {},
        "trip_context": {},
        "tool_plan": [],
        "tool_trace": [],
        "trip_plan": {},
        "reminders": [],
        "photo_candidates": [],
        "completed_tasks": [],
        "temporary_memory_promotions": [],
        "review": {},
        "avatar_status": {
            "energy": 90,
            "mood": "开心",
            "curiosity": 72,
            "rapport": 12,
            "affection": 36,
        },
        "avatar_state": "idle",
        "emotion": "calm",
        "cards": [],
        "next_actions": [],
        "sync_suggestions": [],
        "errors": [],
        "model_call_logs": [],
        "visited_nodes": [],
    }
