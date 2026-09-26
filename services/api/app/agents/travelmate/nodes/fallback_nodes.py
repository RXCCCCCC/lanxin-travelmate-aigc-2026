from typing import Any

from app.agents.travelmate.state import TravelMateState


def _contains_any(text: str, words: list[str]) -> bool:
    return any(word in text for word in words)


def build_rule_memory_candidates(text: str) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []
    if "不吃香菜" in text or "香菜" in text:
        candidates.append({
            "id": "mem-cilantro",
            "title": "不吃香菜",
            "content": "用户明确表示不吃香菜，后续餐厅和菜品推荐需要避开。",
            "category": "dietary_preference",
            "sensitivity": "personal",
            "requiresExplicitConsent": True,
            "scopeOptions": ["longTerm", "currentTrip", "temporary", "ignore"],
            "recommendedScope": "longTerm",
            "reason": "饮食忌口会长期影响餐饮推荐，但仍需要用户明确确认后保存。",
        })
    if "夜景" in text:
        candidates.append({
            "id": "mem-night-view",
            "title": "喜欢夜景",
            "content": "用户偏好夜景路线，规划时优先保留傍晚和夜间观景点。",
            "scopeOptions": ["longTerm", "currentTrip", "temporary", "ignore"],
            "recommendedScope": "longTerm",
            "reason": "这是可复用的旅行兴趣偏好。",
        })
    if _contains_any(text, ["不想太累", "慢一点", "轻松"]):
        candidates.append({
            "id": "mem-slow-pace",
            "title": "本次旅行想轻松一点",
            "content": "用户本次行程希望低强度，减少跨区移动和密集景点。",
            "scopeOptions": ["currentTrip", "temporary", "ignore"],
            "recommendedScope": "currentTrip",
            "reason": "这更像本次旅行约束，先按本次行程保存。",
        })
    if _contains_any(text, ["膝盖", "腿疼", "不舒服", "晕车", "过敏", "低血糖", "身体"]):
        candidates.append({
            "id": "mem-health-condition",
            "title": "身体状态需要照顾",
            "content": "用户提到身体状态可能影响步行强度，规划时需要降低爬坡和长距离步行。",
            "category": "health",
            "sensitivity": "sensitive",
            "requiresExplicitConsent": True,
            "scopeOptions": ["currentTrip", "temporary", "ignore"],
            "recommendedScope": "currentTrip",
            "reason": "身体状态属于敏感信息，只在用户明确确认后按本次旅行使用，不默认长期保存。",
        })
    if _contains_any(text, ["住在", "家在", "酒店在", "附近"]):
        candidates.append({
            "id": "mem-location-context",
            "title": "位置上下文需要保护",
            "content": "用户提到住址或当前位置相关信息，可用于本次路线避绕，但不应默认长期保存。",
            "category": "location",
            "sensitivity": "sensitive",
            "requiresExplicitConsent": True,
            "scopeOptions": ["currentTrip", "temporary", "ignore"],
            "recommendedScope": "temporary",
            "reason": "位置相关信息属于高敏感上下文，默认仅作本次会话或本次旅行使用。",
        })
    if _contains_any(text, ["妈妈", "爸爸", "孩子", "女朋友", "男朋友", "朋友", "同事", "同行"]):
        candidates.append({
            "id": "mem-companion-context",
            "title": "同行人信息需要确认",
            "content": "用户提到同行人，规划可考虑同行人节奏，但多人信息不应默认进入长期画像。",
            "category": "companion",
            "sensitivity": "sensitive",
            "requiresExplicitConsent": True,
            "scopeOptions": ["currentTrip", "temporary", "ignore"],
            "recommendedScope": "currentTrip",
            "reason": "同行人信息涉及他人隐私，需要更高确认门槛。",
        })
    return candidates


def default_completed_tasks() -> list[dict[str, Any]]:
    return []


def default_temporary_memories() -> list[dict[str, Any]]:
    return []


def build_fallback_review_payload(next_state: TravelMateState) -> dict[str, Any]:
    return {
        "route": next_state["context"].get("route") or "",
        "highlightPhotos": next_state["context"].get("highlightPhotos") or [],
        "newMemories": next_state["context"].get("newMemories") or [
            item["title"] for item in next_state["memory_candidates"]
        ],
        "completedTasks": next_state["completed_tasks"],
        "reminderHighlights": next_state["context"].get("reminderHighlights") or [],
        "avatarStatusChanges": next_state["context"].get("avatarStatusChanges") or [],
        "nextTripSuggestions": next_state["context"].get("nextTripSuggestions")
        or [],
        "temporaryMemoryPromotions": next_state["temporary_memory_promotions"],
        "profileContext": next_state["context"].get("profileContext") or {},
    }
