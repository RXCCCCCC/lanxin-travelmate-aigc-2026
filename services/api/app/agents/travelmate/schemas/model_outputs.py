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


class ModelTaskOutput(BaseModel):
    replyText: str | None = None
    memoryExtraction: MemoryExtractionOutput | None = None
    tripPlanning: TripPlanningOutput | None = None
    raw: dict[str, Any] = Field(default_factory=dict)
    fallback: bool = False
    fallbackReason: str | None = None


def parse_model_output(text: str) -> ModelTaskOutput:
    try:
        payload = json.loads(text)
        return ModelTaskOutput.model_validate(payload | {"raw": payload})
    except (json.JSONDecodeError, ValidationError) as exc:
        return ModelTaskOutput(
            fallback=True,
            fallbackReason=f"模型输出不是合法结构化 JSON：{exc}",
            raw={"text": text},
        )