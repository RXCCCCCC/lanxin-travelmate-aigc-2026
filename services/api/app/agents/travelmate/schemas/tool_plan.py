from typing import Any

from pydantic import BaseModel, Field, field_validator


class ToolStep(BaseModel):
    stepId: str = Field(min_length=1, max_length=64)
    tool: str = Field(min_length=1, max_length=64)
    reason: str = Field(min_length=1, max_length=240)
    input: dict[str, Any] = Field(min_length=1)
    dependsOn: list[str] = Field(default_factory=list)

    @field_validator("dependsOn")
    @classmethod
    def unique_dependencies(cls, value: list[str]) -> list[str]:
        return list(dict.fromkeys(value))


class ToolPlan(BaseModel):
    goal: str = Field(min_length=1, max_length=240)
    steps: list[ToolStep] = Field(default_factory=list)
    maxSteps: int = Field(default=4, ge=0, le=4)
    plannerProvider: str = Field(min_length=1, max_length=64)
    fallback: bool = False
    fallbackReason: str | None = None
