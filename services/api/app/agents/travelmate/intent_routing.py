from typing import Literal

from pydantic import BaseModel

from app.agents.travelmate.state import TravelMateState


class IntentDecision(BaseModel):
    intent: Literal["companion_chat", "trip_planning", "trip_review"]
    mode: Literal["chat", "plan", "review"]
    reason: str
    provider: str = "deterministic"
    fallback: bool = True


_PLAN_KEYWORDS_EN = ("plan", "route", "itinerary", "destination", "weekend", "recommend", "attraction")
_PLAN_KEYWORDS_CN = (
    "规划",
    "路线",
    "行程",
    "周末",
    "两天",
    "目的地",
    "攻略",
    "怎么玩",
    "怎么选",
    "好玩",
    "景点",
    "去哪玩",
    "哪里玩",
    "推荐",
)
_GREETING_KEYWORDS = ("你好", "在吗")
_REVIEW_KEYWORDS = ("复盘", "总结", "review", "recap")


def decide_intent(message: str) -> dict[str, object]:
    normalized = message.lower()
    if any(keyword in normalized for keyword in _REVIEW_KEYWORDS):
        decision = IntentDecision(
            intent="trip_review",
            mode="review",
            reason="输入包含旅行复盘或总结意图。",
        )
    elif (
        any(keyword in normalized for keyword in _PLAN_KEYWORDS_EN)
        or any(keyword in message for keyword in _PLAN_KEYWORDS_CN)
    ) and not any(keyword in message for keyword in _GREETING_KEYWORDS):
        decision = IntentDecision(
            intent="trip_planning",
            mode="plan",
            reason="输入包含目的地、路线、景点或行程规划意图。",
        )
    else:
        decision = IntentDecision(
            intent="companion_chat",
            mode="chat",
            reason="输入未触发行程规划或旅行复盘规则。",
        )
    return decision.model_dump()


def ensure_intent_decision(state: TravelMateState) -> dict[str, object]:
    existing = state.get("intent_decision")
    if isinstance(existing, dict) and existing:
        return IntentDecision.model_validate(existing).model_dump()
    decision = decide_intent(str(state.get("normalized_input") or state.get("message") or ""))
    state["intent_decision"] = decision
    return decision
