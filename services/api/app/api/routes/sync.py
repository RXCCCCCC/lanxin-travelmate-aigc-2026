import json
from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlmodel import Session, select

from app.core.security import CurrentUser, get_current_user, resolve_effective_user_id
from app.db.models import CloudMemory, CloudTrip, CloudUserProfile, SyncRecord, utc_now
from app.db.session import get_session


router = APIRouter(prefix="/sync", tags=["sync"])


class SyncMemoryPayload(BaseModel):
    id: str
    title: str
    content: str
    scope: str
    category: str = "travel_preference"
    status: str = "confirmed"
    confidence: float = 1.0
    updatedAt: str | None = None


class SyncProfilePayload(BaseModel):
    travelPace: str = "轻松"
    dietaryPreferences: list[str] = Field(default_factory=list)
    interestTags: list[str] = Field(default_factory=list)
    transportPreferences: list[str] = Field(default_factory=list)
    budgetPreference: str | None = None
    expressionStyle: str | None = None


class SyncTripPayload(BaseModel):
    id: str
    destination: str
    status: str = "planning"
    plan: dict[str, object] = Field(default_factory=dict)


class SyncPushRequest(BaseModel):
    userId: str = "guest"
    conflictStrategy: str = "serverWins"
    memories: list[SyncMemoryPayload] = Field(default_factory=list)
    profile: SyncProfilePayload | None = None
    trips: list[SyncTripPayload] = Field(default_factory=list)


class SelectedMemorySyncRequest(BaseModel):
    userId: str = "guest"
    memoryIds: list[str]


class RevokeSyncRequest(BaseModel):
    userId: str = "guest"
    memories: list[str] = Field(default_factory=list)
    profile: bool = False
    trips: list[str] = Field(default_factory=list)


def _record_sync(session: Session, user_id: str, entity_type: str, entity_id: str, status: str) -> None:
    session.add(
        SyncRecord(
            id=f"sync-{uuid4().hex}",
            user_id=user_id,
            entity_type=entity_type,
            entity_id=entity_id,
            status=status,
            created_at=utc_now(),
        )
    )


def _parse_client_updated_at(value: str | None) -> datetime | None:
    if not value:
        return None
    normalized = value.replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return parsed
    return parsed.astimezone(utc_now().tzinfo)


def _timestamp(value: datetime) -> float:
    if value.tzinfo is None:
        return value.replace(tzinfo=utc_now().tzinfo).timestamp()
    return value.timestamp()

def _memory_conflict(memory: CloudMemory, item: SyncMemoryPayload, resolution: str) -> dict[str, object]:
    return {
        "entityType": "memory",
        "entityId": item.id,
        "resolution": resolution,
        "clientUpdatedAt": item.updatedAt,
        "serverUpdatedAt": memory.updated_at.isoformat(),
        "server": _memory_response(memory),
        "client": item.model_dump(),
    }

def _memory_response(memory: CloudMemory) -> dict[str, object]:
    return {
        "id": memory.id,
        "title": memory.title,
        "content": memory.content,
        "scope": memory.scope,
        "category": memory.category,
        "status": memory.status,
        "confidence": memory.confidence,
        "updatedAt": memory.updated_at.isoformat(),
    }


@router.post("/push")
def push_sync(
    payload: SyncPushRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    now = utc_now()
    pushed = {"memories": 0, "profile": 0, "trips": 0}
    conflicts: list[dict[str, object]] = []
    for item in payload.memories:
        memory = session.get(CloudMemory, item.id)
        if memory and memory.user_id != effective_user_id:
            raise HTTPException(status_code=403, detail="Memory belongs to another user")
        client_updated_at = _parse_client_updated_at(item.updatedAt)
        has_conflict = memory is not None and client_updated_at is not None and _timestamp(client_updated_at) < _timestamp(memory.updated_at)
        if memory and has_conflict and payload.conflictStrategy != "clientWins":
            conflicts.append(_memory_conflict(memory, item, "serverWins"))
            _record_sync(session, effective_user_id, "memory", item.id, "conflict_server_wins")
            continue
        if memory:
            if has_conflict:
                conflicts.append(_memory_conflict(memory, item, "clientWins"))
            memory.title = item.title
            memory.content = item.content
            memory.scope = item.scope
            memory.category = item.category
            memory.status = item.status
            memory.confidence = item.confidence
            memory.updated_at = client_updated_at or now
        else:
            memory = CloudMemory(
                id=item.id,
                user_id=effective_user_id,
                title=item.title,
                content=item.content,
                scope=item.scope,
                category=item.category,
                status=item.status,
                confidence=item.confidence,
                created_at=now,
                updated_at=client_updated_at or now,
            )
        session.add(memory)
        _record_sync(session, effective_user_id, "memory", item.id, "pushed")
        pushed["memories"] += 1

    if payload.profile:
        profile = session.exec(select(CloudUserProfile).where(CloudUserProfile.user_id == effective_user_id)).first()
        profile_json = json.dumps(payload.profile.model_dump(), ensure_ascii=False)
        if profile:
            profile.profile_json = profile_json
            profile.updated_at = now
        else:
            profile = CloudUserProfile(
                id=f"profile-{uuid4().hex}",
                user_id=effective_user_id,
                profile_json=profile_json,
                updated_at=now,
            )
        session.add(profile)
        _record_sync(session, effective_user_id, "profile", profile.id, "pushed")
        pushed["profile"] = 1

    for item in payload.trips:
        trip = session.get(CloudTrip, item.id)
        if trip and trip.user_id != effective_user_id:
            raise HTTPException(status_code=403, detail="Trip belongs to another user")
        if trip:
            trip.destination = item.destination
            trip.status = item.status
            trip.plan_json = json.dumps(item.plan, ensure_ascii=False)
            trip.updated_at = now
        else:
            trip = CloudTrip(
                id=item.id,
                user_id=effective_user_id,
                destination=item.destination,
                status=item.status,
                plan_json=json.dumps(item.plan, ensure_ascii=False),
                created_at=now,
                updated_at=now,
            )
        session.add(trip)
        _record_sync(session, effective_user_id, "trip", item.id, "pushed")
        pushed["trips"] += 1

    session.commit()
    return {"status": "ok", "pushed": pushed, "conflicts": conflicts}

@router.get("/pull")
def pull_sync(
    userId: str | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    memories = session.exec(select(CloudMemory).where(CloudMemory.user_id == effective_user_id)).all()
    profile = session.exec(select(CloudUserProfile).where(CloudUserProfile.user_id == effective_user_id)).first()
    trips = session.exec(select(CloudTrip).where(CloudTrip.user_id == effective_user_id)).all()
    return {
        "userId": effective_user_id,
        "memories": [_memory_response(memory) for memory in memories],
        "profile": json.loads(profile.profile_json) if profile else None,
        "trips": [
            {
                "id": trip.id,
                "destination": trip.destination,
                "status": trip.status,
                "plan": json.loads(trip.plan_json),
                "updatedAt": trip.updated_at.isoformat(),
            }
            for trip in trips
        ],
    }

@router.post("/selected-memory")
def sync_selected_memory(
    payload: SelectedMemorySyncRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    memories = session.exec(
        select(CloudMemory).where(CloudMemory.user_id == effective_user_id, CloudMemory.id.in_(payload.memoryIds))
    ).all()
    for memory in memories:
        _record_sync(session, effective_user_id, "memory", memory.id, "selected")
    session.commit()
    return {"status": "ok", "selected": [_memory_response(memory) for memory in memories]}

@router.post("/revoke")
def revoke_sync(
    payload: RevokeSyncRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    revoked = {"memories": 0, "profile": 0, "trips": 0}
    records: list[dict[str, object]] = []

    for memory_id in payload.memories:
        memory = session.get(CloudMemory, memory_id)
        if memory and memory.user_id == effective_user_id:
            session.delete(memory)
            _record_sync(session, effective_user_id, "memory", memory_id, "revoked")
            records.append({"entityType": "memory", "entityId": memory_id, "status": "revoked"})
            revoked["memories"] += 1

    if payload.profile:
        profiles = session.exec(select(CloudUserProfile).where(CloudUserProfile.user_id == effective_user_id)).all()
        for profile in profiles:
            session.delete(profile)
            _record_sync(session, effective_user_id, "profile", profile.id, "revoked")
            records.append({"entityType": "profile", "entityId": profile.id, "status": "revoked"})
            revoked["profile"] += 1

    for trip_id in payload.trips:
        trip = session.get(CloudTrip, trip_id)
        if trip and trip.user_id == effective_user_id:
            session.delete(trip)
            _record_sync(session, effective_user_id, "trip", trip_id, "revoked")
            records.append({"entityType": "trip", "entityId": trip_id, "status": "revoked"})
            revoked["trips"] += 1

    session.commit()
    return {"status": "ok", "revoked": revoked, "records": records}
