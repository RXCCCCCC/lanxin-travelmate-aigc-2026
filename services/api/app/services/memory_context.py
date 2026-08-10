from collections.abc import Iterable
from typing import Any

from sqlmodel import Session, select

from app.db.models import CloudMemory


MAX_LONG_TERM_MEMORIES = 8
MAX_CURRENT_TRIP_MEMORIES = 8
MAX_MEMORY_TITLE_CHARS = 80
MAX_MEMORY_CONTENT_CHARS = 160

_SENSITIVE_CATEGORIES = {
    "health",
    "location",
    "companion",
    "identity",
    "financial",
    "sensitive",
}


def _is_sensitive(memory: CloudMemory) -> bool:
    return memory.category.strip().lower() in _SENSITIVE_CATEGORIES


def _compact_text(value: object, limit: int) -> str:
    text = str(value or "").strip()
    if len(text) <= limit:
        return text
    return f"{text[:limit]}..."


def _memory_item(memory: CloudMemory) -> dict[str, Any]:
    sensitive = _is_sensitive(memory)
    return {
        "memoryId": memory.id,
        "title": _compact_text(memory.title, MAX_MEMORY_TITLE_CHARS),
        "content": (
            "[敏感记忆已确认，仅保留结构化约束]"
            if sensitive
            else _compact_text(memory.content, MAX_MEMORY_CONTENT_CHARS)
        ),
        "category": memory.category,
        "scope": memory.scope,
        "confidence": memory.confidence,
        "sensitive": sensitive,
    }


def _sort_memories(memories: Iterable[CloudMemory]) -> list[CloudMemory]:
    return sorted(memories, key=lambda item: item.updated_at, reverse=True)


def build_memory_context(
    session: Session,
    user_id: str,
    trip_id: str | None = None,
) -> dict[str, Any]:
    if not user_id:
        return {"items": [], "longTerm": [], "currentTrip": [], "memoryCount": 0}

    records = session.exec(
        select(CloudMemory)
        .where(CloudMemory.user_id == user_id)
        .where(CloudMemory.status == "confirmed")
        .where(CloudMemory.scope.in_(["longTerm", "currentTrip"]))
    ).all()
    long_term = _sort_memories(item for item in records if item.scope == "longTerm")[:MAX_LONG_TERM_MEMORIES]
    current_trip = _sort_memories(
        item
        for item in records
        if item.scope == "currentTrip" and trip_id and item.source_text == trip_id
    )[:MAX_CURRENT_TRIP_MEMORIES]
    items = [_memory_item(item) for item in [*long_term, *current_trip]]
    return {
        "items": items,
        "longTerm": [_memory_item(item) for item in long_term],
        "currentTrip": [_memory_item(item) for item in current_trip],
        "memoryCount": len(items),
    }


def aggregate_memory_profile(memory_context: dict[str, Any]) -> dict[str, Any]:
    profile: dict[str, Any] = {
        "dietaryPreferences": [],
        "travelPace": None,
        "interestTags": [],
        "transportPreferences": [],
        "budgetPreferences": [],
        "sensitiveConstraints": [],
    }
    category_groups = {
        "dietaryPreferences": {"dietary_preference", "dietary", "food_preference"},
        "interestTags": {"interest", "interest_tag", "activity_preference"},
        "transportPreferences": {"transport", "transport_preference"},
        "budgetPreferences": {"budget", "budget_preference"},
    }
    for item in memory_context.get("items", []):
        if not isinstance(item, dict):
            continue
        category = str(item.get("category") or "").strip().lower()
        value = str(item.get("content") or item.get("title") or "").strip()
        if item.get("sensitive"):
            profile["sensitiveConstraints"].append(
                {
                    "memoryId": item.get("memoryId"),
                    "title": item.get("title"),
                    "category": item.get("category"),
                    "scope": item.get("scope"),
                }
            )
            continue
        if category in {"pace_preference", "travel_pace", "pace"}:
            if value and profile["travelPace"] is None:
                profile["travelPace"] = value
            continue
        for field, categories in category_groups.items():
            if category in categories and value and value not in profile[field]:
                profile[field].append(value)
                break
    return profile
