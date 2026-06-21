"""Agent 节点 LLM 输出的 JSON Schema 定义（Pydantic）。"""

import json
from typing import Any, Literal

from pydantic import BaseModel, Field, ValidationError


# ── Memory Extraction ───────────────────────────────────────────────────────

class MemoryCandidateOutput(BaseModel):
    title: str
    content: str
    category: str = "travel_preference"
    sensitivity: Literal["normal", "personal", "sensitive"] = "normal"
    requiresExplicitConsent: bool = False
    recommendedScope: Literal["longTerm", "currentTrip", "temporary", "ignore"]
    scopeOptions: list[str] = Field(default_factory=lambda: ["currentTrip", "temporary", "ignore"])
    confidence: float = Field(ge=0, le=1)
    reason: str


class MemoryExtractionOutput(BaseModel):
    candidates: list[MemoryCandidateOutput] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


# ── Intent Routing ──────────────────────────────────────────────────────────

class IntentRoutingOutput(BaseModel):
    intent: Literal["trip_planning", "trip_review", "companion_chat"]
    confidence: float = Field(ge=0, le=1)
    reason: str = ""
    fallback: bool = False
    fallbackReason: str | None = None


# ── Trip Planning ───────────────────────────────────────────────────────────

class TripDayItem(BaseModel):
    time: str
    location: str
    activity: str
    reason: str


class TripDay(BaseModel):
    dayLabel: str
    items: list[TripDayItem] = Field(default_factory=list)


class TripAlternative(BaseModel):
    id: str
    title: str
    summary: str
    bestFor: str


class TripPlanningOutput(BaseModel):
    title: str
    destination: str
    dateRange: str = ""
    summary: str = ""
    profileMatches: list[str] = Field(default_factory=list)
    days: list[TripDay] = Field(default_factory=list)
    risks: list[str] = Field(default_factory=list)
    alternatives: list[TripAlternative] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


# ── Reminder ────────────────────────────────────────────────────────────────

class ReminderOutput(BaseModel):
    id: str
    title: str
    triggerType: Literal["time", "location", "behavior", "status", "external"]
    description: str
    cooldownMinutes: int = 60
    priority: Literal["low", "normal", "high"] = "normal"


class ReminderCheckOutput(BaseModel):
    reminders: list[ReminderOutput] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


# ── Photo Analysis ──────────────────────────────────────────────────────────

class PhotoCandidateOutput(BaseModel):
    id: str
    location: str = ""
    score: float = Field(ge=0, le=10)
    description: str
    tags: list[str] = Field(default_factory=list)


class PhotoAnalysisOutput(BaseModel):
    candidates: list[PhotoCandidateOutput] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


# ── Copywriting / Next Actions ──────────────────────────────────────────────

class NextActionOutput(BaseModel):
    type: str
    label: str
    priority: Literal["low", "normal", "high"] = "normal"


class CopywriterOutput(BaseModel):
    replyText: str = ""
    nextActions: list[NextActionOutput] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


# ── Review ──────────────────────────────────────────────────────────────────

class MemoryPromotionOutput(BaseModel):
    id: str
    title: str
    content: str
    suggestedScope: Literal["longTerm", "currentTrip", "temporary"]
    reason: str


class ReviewOutput(BaseModel):
    route: str = ""
    highlightPhotos: list[str] = Field(default_factory=list)
    completedTasks: list[dict[str, Any]] = Field(default_factory=list)
    reminderHighlights: list[str] = Field(default_factory=list)
    avatarStatusChanges: list[str] = Field(default_factory=list)
    newMemories: list[str] = Field(default_factory=list)
    nextTripSuggestions: list[str] = Field(default_factory=list)
    temporaryMemoryPromotions: list[MemoryPromotionOutput] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


# ── Tool Planning ───────────────────────────────────────────────────────────

class ToolPlanItem(BaseModel):
    tool: str
    input: dict[str, Any] = Field(default_factory=dict)


class ToolPlanningOutput(BaseModel):
    tools: list[ToolPlanItem] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


# ── Trip Context Building ───────────────────────────────────────────────────

class TripContextOutput(BaseModel):
    destination: str = ""
    durationDays: int = 1
    pace: Literal["轻松", "适中", "紧凑"] = "适中"
    mustKeep: list[str] = Field(default_factory=list)
    budget: str = ""
    companions: list[str] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


# ── Memory Writer / Conflict Detection ──────────────────────────────────────

class MemoryConflictOutput(BaseModel):
    id: str
    previousPreference: str
    currentPreference: str
    resolution: str


class MemoryWriterOutput(BaseModel):
    conflicts: list[MemoryConflictOutput] = Field(default_factory=list)
    pendingMemoryCount: int = 0
    fallback: bool = False
    fallbackReason: str | None = None


# ── Trip Adjustment ─────────────────────────────────────────────────────────

class TripAdjustmentOutput(BaseModel):
    trigger: str
    suggestion: str
    affectedDays: list[int] = Field(default_factory=list)
    fallback: bool = False
    fallbackReason: str | None = None


# ── Top-level Union ─────────────────────────────────────────────────────────

class ModelTaskOutput(BaseModel):
    replyText: str | None = None
    intentRouting: IntentRoutingOutput | None = None
    memoryExtraction: MemoryExtractionOutput | None = None
    tripPlanning: TripPlanningOutput | None = None
    reminderCheck: ReminderCheckOutput | None = None
    photoAnalysis: PhotoAnalysisOutput | None = None
    copywriter: CopywriterOutput | None = None
    review: ReviewOutput | None = None
    toolPlanning: ToolPlanningOutput | None = None
    tripContext: TripContextOutput | None = None
    memoryWriter: MemoryWriterOutput | None = None
    tripAdjustment: TripAdjustmentOutput | None = None
    raw: dict[str, Any] = Field(default_factory=dict)
    fallback: bool = False
    fallbackReason: str | None = None


# ── Schema Maps ─────────────────────────────────────────────────────────────

SCHEMA_MAP: dict[str, type[BaseModel]] = {
    "intent_routing": IntentRoutingOutput,
    "memory_extraction": MemoryExtractionOutput,
    "trip_planning": TripPlanningOutput,
    "trip_adjustment": TripAdjustmentOutput,
    "reminder_check": ReminderCheckOutput,
    "photo_analysis": PhotoAnalysisOutput,
    "copywriting": CopywriterOutput,
    "review_generation": ReviewOutput,
    "tool_planning": ToolPlanningOutput,
    "trip_context_building": TripContextOutput,
    "memory_writing": MemoryWriterOutput,
}


def get_schema(scenario: str) -> dict[str, Any]:
    """返回指定场景的 JSON Schema（用于传入模型）。"""
    model = SCHEMA_MAP.get(scenario)
    if model is None:
        return {}
    return model.model_json_schema()


def parse_model_output(text: str) -> ModelTaskOutput:
    """通用 JSON 解析 + Pydantic 校验入口。"""
    try:
        payload = json.loads(text)
        return ModelTaskOutput.model_validate(payload | {"raw": payload})
    except (json.JSONDecodeError, ValidationError) as exc:
        return ModelTaskOutput(
            fallback=True,
            fallbackReason=f"模型输出不是合法结构化 JSON：{exc}",
            raw={"text": text},
        )
