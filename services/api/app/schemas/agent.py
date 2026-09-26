from typing import Any, Literal

from pydantic import BaseModel, Field


class AgentChatRequest(BaseModel):
    message: str = Field(min_length=1)
    sessionId: str | None = None
    userId: str | None = None
    tripId: str | None = None
    idempotencyKey: str | None = None
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
    runId: str | None = None
    requestId: str | None = None
    status: str = "completed"
    resumeToken: str | None = None


class AgentRunResumeRequest(BaseModel):
    resumeToken: str = Field(min_length=1)
    action: Literal["confirm", "cancel"]
    candidateIds: list[str] = Field(default_factory=list)


class AgentRunResumeResponse(BaseModel):
    runId: str
    requestId: str
    status: str
    action: Literal["confirm", "cancel"]
    savedMemoryIds: list[str]
    alreadyApplied: bool
