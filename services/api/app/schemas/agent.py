from typing import Any

from pydantic import BaseModel, Field


class AgentChatRequest(BaseModel):
    message: str = Field(min_length=1)
    sessionId: str | None = None
    userId: str | None = None
    tripId: str | None = None
    context: dict[str, Any] | None = None


class AgentChatResponse(BaseModel):
    replyText: str
    voiceText: str
    avatarState: str
    emotion: str
    cards: list[dict[str, Any]]
    memoryCandidates: list[dict[str, Any]]
    toolTrace: list[dict[str, Any]]
    nextActions: list[dict[str, Any]]
    syncSuggestions: list[dict[str, Any]]
    errors: list[dict[str, Any]]
