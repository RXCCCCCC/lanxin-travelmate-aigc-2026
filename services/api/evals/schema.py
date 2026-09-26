from typing import Any

from pydantic import BaseModel, Field


class ExpectedOutcome(BaseModel):
    intent: str
    tools: list[str] = Field(default_factory=list)
    excludedTools: list[str] = Field(default_factory=list)
    destination: str | None = None
    memoryTitles: list[str] = Field(default_factory=list)
    sensitiveMemoryTitles: list[str] = Field(default_factory=list)
    plannerFallback: bool = True


class GoldenCase(BaseModel):
    id: str
    category: str
    message: str
    context: dict[str, Any] = Field(default_factory=dict)
    expected: ExpectedOutcome


class CaseResult(BaseModel):
    id: str
    category: str
    passed: bool
    elapsedMs: int
    checks: dict[str, bool]
    expected: dict[str, Any]
    actual: dict[str, Any]
    differences: list[str] = Field(default_factory=list)
