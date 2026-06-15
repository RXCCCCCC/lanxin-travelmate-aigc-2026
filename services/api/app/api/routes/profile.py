from fastapi import APIRouter
from pydantic import BaseModel


router = APIRouter(prefix="/profile", tags=["profile"])

_profile_store: dict[str, object] = {
    "travelPace": "轻松",
    "dietaryPreferences": ["不吃香菜"],
    "interestTags": ["夜景"],
}


class ProfilePayload(BaseModel):
    travelPace: str
    dietaryPreferences: list[str]
    interestTags: list[str]


@router.get("/me")
def read_profile_placeholder() -> dict[str, object]:
    return {"userId": "guest", **_profile_store}


@router.put("/me")
def update_profile(payload: ProfilePayload) -> dict[str, object]:
    _profile_store.update(payload.model_dump())
    return {"userId": "guest", **_profile_store}
