from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlmodel import Session, select

from app.core.security import CurrentUser, create_access_token, get_current_user, hash_password, verify_password
from app.db.models import AuthCredential, User, utc_now
from app.db.session import get_session


router = APIRouter(tags=["auth"])


class GuestRequest(BaseModel):
    deviceId: str | None = None
    displayName: str = "游客"


class RegisterRequest(BaseModel):
    account: str = Field(min_length=3)
    password: str = Field(min_length=6)
    displayName: str = "蓝心用户"


class LoginRequest(BaseModel):
    account: str
    password: str


def _user_response(user: User, token: str, *, is_guest: bool) -> dict[str, object]:
    return {
        "userId": user.id,
        "displayName": user.display_name,
        "authMode": user.auth_mode,
        "isGuest": is_guest,
        "accessToken": token,
    }


def _ensure_user(session: Session, user_id: str, display_name: str, auth_mode: str) -> User:
    user = session.get(User, user_id)
    now = utc_now()
    if user:
        user.display_name = display_name or user.display_name
        user.auth_mode = auth_mode
        user.last_active_at = now
    else:
        user = User(
            id=user_id,
            display_name=display_name,
            auth_mode=auth_mode,
            created_at=now,
            last_active_at=now,
        )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@router.post("/auth/guest")
def create_guest(payload: GuestRequest, session: Session = Depends(get_session)) -> dict[str, object]:
    user_id = f"guest-{payload.deviceId}" if payload.deviceId else f"guest-{uuid4().hex}"
    user = _ensure_user(session, user_id, payload.displayName, "guest")
    token = create_access_token(user.id, is_guest=True)
    return _user_response(user, token, is_guest=True)


@router.get("/auth/guest")
def read_guest(session: Session = Depends(get_session)) -> dict[str, object]:
    user = _ensure_user(session, "guest", "游客", "guest")
    token = create_access_token(user.id, is_guest=True)
    return _user_response(user, token, is_guest=True)


@router.post("/auth/register")
def register(payload: RegisterRequest, session: Session = Depends(get_session)) -> dict[str, object]:
    existing = session.exec(
        select(AuthCredential).where(AuthCredential.provider == "password", AuthCredential.subject == payload.account)
    ).first()
    if existing:
        raise HTTPException(status_code=409, detail="Account already exists")
    user = _ensure_user(session, f"user-{uuid4().hex}", payload.displayName, "password")
    credential = AuthCredential(
        id=f"cred-{uuid4().hex}",
        user_id=user.id,
        provider="password",
        subject=payload.account,
        password_hash=hash_password(payload.password),
    )
    session.add(credential)
    session.commit()
    token = create_access_token(user.id, is_guest=False)
    return _user_response(user, token, is_guest=False)


@router.post("/auth/login")
def login(payload: LoginRequest, session: Session = Depends(get_session)) -> dict[str, object]:
    credential = session.exec(
        select(AuthCredential).where(AuthCredential.provider == "password", AuthCredential.subject == payload.account)
    ).first()
    if not credential or not credential.password_hash or not verify_password(payload.password, credential.password_hash):
        raise HTTPException(status_code=401, detail="Invalid account or password")
    user = session.get(User, credential.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.last_active_at = utc_now()
    session.add(user)
    session.commit()
    session.refresh(user)
    token = create_access_token(user.id, is_guest=False)
    return _user_response(user, token, is_guest=False)


@router.post("/auth/logout")
def logout() -> dict[str, bool]:
    return {"ok": True}


@router.get("/users/me")
def read_me(
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    user = session.get(User, current_user.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "userId": user.id,
        "displayName": user.display_name,
        "authMode": user.auth_mode,
        "isGuest": current_user.is_guest,
    }