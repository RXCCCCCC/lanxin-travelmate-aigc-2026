import json
from uuid import uuid4

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlmodel import Session, select

from app.core.security import CurrentUser, get_current_user, resolve_effective_user_id
from app.db.models import CloudUserProfile, utc_now
from app.db.session import get_session


router = APIRouter(prefix="/profile", tags=["profile"])


class ProfilePayload(BaseModel):
    travelPace: str = "轻松"
    dietaryPreferences: list[str] = Field(default_factory=list)
    interestTags: list[str] = Field(default_factory=list)
    transportPreferences: list[str] = Field(default_factory=list)
    budgetPreference: str | None = None
    expressionStyle: str | None = None
    personality: str = "gentle_companion"
    proactivityLevel: str = "standard"
    syncStrategy: str = "all"
    notificationEnabled: bool = True
    voiceEnabled: bool = True
    textModePreferred: bool = False
    customPrompt: str | None = None


DEFAULT_PROFILE = ProfilePayload(
    travelPace="轻松",
    dietaryPreferences=[],
    interestTags=[],
)


def _profile_response(user_id: str, payload: dict[str, object]) -> dict[str, object]:
    return {"userId": user_id, **payload}


def _read_profile(session: Session, user_id: str) -> CloudUserProfile | None:
    return session.exec(select(CloudUserProfile).where(CloudUserProfile.user_id == user_id)).first()


@router.get("/me")
def read_profile(
    userId: str | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    profile = _read_profile(session, effective_user_id)
    if not profile:
        return _profile_response(effective_user_id, DEFAULT_PROFILE.model_dump())
    return _profile_response(effective_user_id, json.loads(profile.profile_json))


@router.put("/me")
def update_profile(
    payload: ProfilePayload,
    userId: str | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    profile = _read_profile(session, effective_user_id)
    data = payload.model_dump()
    if profile:
        profile.profile_json = json.dumps(data, ensure_ascii=False)
        profile.updated_at = utc_now()
    else:
        profile = CloudUserProfile(
            id=f"profile-{uuid4().hex}",
            user_id=effective_user_id,
            profile_json=json.dumps(data, ensure_ascii=False),
            updated_at=utc_now(),
        )
    session.add(profile)
    session.commit()
    return _profile_response(effective_user_id, data)
