from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.state import create_initial_state


router = APIRouter(prefix="/trip", tags=["trip"])


class TripPlanRequest(BaseModel):
    message: str


class TripReviewRequest(BaseModel):
    message: str = "生成今天旅行复盘"
    tripId: str | None = None
    completedTasks: list[dict[str, object]] = Field(default_factory=list)
    temporaryMemories: list[dict[str, object]] = Field(default_factory=list)


class ReminderTriggerRequest(BaseModel):
    triggerType: str
    location: str | None = None
    eventPayload: dict[str, object] = Field(default_factory=dict)


@router.get("/current")
def read_current_trip_placeholder() -> dict[str, str]:
    return {"tripId": "demo-chongqing-weekend", "status": "mock"}


@router.post("/plan")
def create_trip_plan(payload: TripPlanRequest) -> dict[str, object]:
    state = create_initial_state(message=payload.message, session_id="demo-session")
    result = TravelMateGraph().invoke(state)
    return result["trip_plan"]


@router.post("/review")
def create_trip_review(payload: TripReviewRequest) -> dict[str, object]:
    state = create_initial_state(
        message=payload.message,
        session_id="demo-session",
        trip_id=payload.tripId,
        context={
            "completedTasks": payload.completedTasks,
            "temporaryMemories": payload.temporaryMemories,
        },
    )
    result = TravelMateGraph().invoke(state)
    return result["review"]


@router.post("/reminders/trigger")
def trigger_reminders(payload: ReminderTriggerRequest) -> dict[str, list[dict[str, object]]]:
    state = create_initial_state(
        message=f"触发提醒：{payload.triggerType} {payload.location or ''}",
        session_id="demo-session",
        context={
            "triggerType": payload.triggerType,
            "location": payload.location,
            "eventPayload": payload.eventPayload,
        },
    )
    result = TravelMateGraph().invoke(state)
    return {"items": result["reminders"]}


@router.get("/blind-box/tasks")
def read_blind_box_tasks() -> dict[str, list[dict[str, object]]]:
    return {
        "items": [
            {
                "id": "task-photo-night",
                "type": "photo",
                "title": "拍一张不是游客照的重庆夜景",
                "reward": "好感度 +2",
                "reviewImpact": "进入今日高光照片。",
            },
            {
                "id": "task-food-no-cilantro",
                "type": "food",
                "title": "找到一家不用香菜也好吃的小店",
                "reward": "默契值 +1",
                "reviewImpact": "强化餐饮避雷记忆。",
            },
            {
                "id": "task-route-slow",
                "type": "route",
                "title": "主动选择一次少走路的路线",
                "reward": "精力 +5",
                "reviewImpact": "沉淀慢节奏旅行偏好。",
            },
            {
                "id": "task-interaction",
                "type": "interaction",
                "title": "让蓝小心推荐一个附近小发现",
                "reward": "好奇心 +3",
                "reviewImpact": "记录一次搭子共同发现。",
            },
            {
                "id": "task-story",
                "type": "story",
                "title": "给今天的高光照片写一句标题",
                "reward": "默契值 +2",
                "reviewImpact": "用于复盘卡标题和分享文案。",
            },
        ]
    }
