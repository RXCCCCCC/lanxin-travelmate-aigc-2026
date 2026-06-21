import json
from typing import Any, Literal

from pydantic import BaseModel, Field, ValidationError


class MemoryCandidateOutput(BaseModel):
    title: str
    content: str
    category: str = "travel_preference"
    recommendedScope: Literal["longTerm", "currentTrip", "temporary", "ignore"]
    confidence: float = Field(ge=0, le=1)
    reason: str


class MemoryExtractionOutput(BaseModel):
    candidates: list[MemoryCandidateOutput] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


class TripPlanningOutput(BaseModel):
    title: str
    destination: str
    summary: str
    profileMatches: list[str] = Field(default_factory=list)
    risks: list[str] = Field(default_factory=list)
    alternatives: list[dict[str, Any]] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


class ChatOutput(BaseModel):
    replyText: str
    voiceText: str
    avatarState: str
    emotion: str
    cards: list[dict[str, Any]] = Field(default_factory=list)
    memoryCandidates: list[dict[str, Any]] = Field(default_factory=list)
    toolTrace: list[dict[str, Any]] = Field(default_factory=list)
    nextActions: list[dict[str, Any]] = Field(default_factory=list)
    syncSuggestions: list[dict[str, Any]] = Field(default_factory=list)
    errors: list[dict[str, Any]] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


class PhotoCopywritingOutput(BaseModel):
    photoIds: list[str] = Field(default_factory=list)
    persona: str
    style: str
    moments: str
    xiaohongshu: str
    diary: str
    vlogNarration: str
    reviewSuggestion: str
    fallback: bool = False
    fallbackReason: str | None = None


class TripReviewOutput(BaseModel):
    route: str | None = None
    highlightPhotos: list[str] = Field(default_factory=list)
    completedTasks: list[dict[str, Any]] = Field(default_factory=list)
    reminderHighlights: list[dict[str, Any]] = Field(default_factory=list)
    avatarStatusChanges: list[str] = Field(default_factory=list)
    newMemories: list[str] = Field(default_factory=list)
    nextTripSuggestions: list[str] = Field(default_factory=list)
    temporaryMemoryPromotions: list[dict[str, Any]] = Field(default_factory=list)
    profileContext: dict[str, Any] = Field(default_factory=dict)
    fallback: bool = False
    fallbackReason: str | None = None


class ModelTaskOutput(BaseModel):
    replyText: str | None = None
    chat: ChatOutput | None = None
    memoryExtraction: MemoryExtractionOutput | None = None
    tripPlanning: TripPlanningOutput | None = None
    photoCopywriting: PhotoCopywritingOutput | None = None
    tripReview: TripReviewOutput | None = None
    raw: dict[str, Any] = Field(default_factory=dict)
    fallback: bool = False
    fallbackReason: str | None = None


def parse_model_output(text: str) -> ModelTaskOutput:
    try:
        payload = json.loads(text)
        if not isinstance(payload, dict):
            raise TypeError("model output root must be an object")
        return ModelTaskOutput.model_validate(payload | {"raw": payload})
    except json.JSONDecodeError as exc:
        return ModelTaskOutput(
            fallback=True,
            fallbackReason=f"model output is not valid JSON: {exc}",
            raw={"text": text},
        )
    except ValidationError as exc:
        return ModelTaskOutput(
            fallback=True,
            fallbackReason=f"model output validation failed: {exc}",
            raw=payload,
        )
    except TypeError as exc:
        return ModelTaskOutput(
            fallback=True,
            fallbackReason=f"model output validation failed: {exc}",
            raw={"text": text},
        )
