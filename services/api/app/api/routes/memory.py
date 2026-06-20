
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlmodel import Session, select

from app.db.models import CloudMemory, utc_now
from app.db.session import get_session


router = APIRouter(prefix="/memory", tags=["memory"])


class MemoryCapsulePayload(BaseModel):
    id: str
    title: str
    content: str
    scope: str
    userId: str = "guest"
    category: str = "travel_preference"
    sourceText: str | None = None
    confidence: float = 1.0


class MemoryCapsuleUpdatePayload(BaseModel):
    title: str
    content: str
    scope: str | None = None
    category: str | None = None
    status: str | None = None


def _to_response(memory: CloudMemory) -> dict[str, object]:
    return {
        "id": memory.id,
        "userId": memory.user_id,
        "title": memory.title,
        "content": memory.content,
        "scope": memory.scope,
        "category": memory.category,
        "status": memory.status,
        "sourceText": memory.source_text,
        "confidence": memory.confidence,
        "createdAt": memory.created_at.isoformat(),
        "updatedAt": memory.updated_at.isoformat(),
    }


@router.get("/capsules")
def list_memory_capsules(
    userId: str = Query(default="guest"),
    session: Session = Depends(get_session),
) -> dict[str, list[dict[str, object]]]:
    memories = session.exec(
        select(CloudMemory).where(CloudMemory.user_id == userId).order_by(CloudMemory.updated_at.desc())
    ).all()
    return {"items": [_to_response(memory) for memory in memories]}


@router.post("/capsules")
def create_memory_capsule(
    payload: MemoryCapsulePayload,
    session: Session = Depends(get_session),
) -> dict[str, object]:
    existing = session.get(CloudMemory, payload.id)
    now = utc_now()
    if existing:
        existing.user_id = payload.userId
        existing.title = payload.title
        existing.content = payload.content
        existing.scope = payload.scope
        existing.category = payload.category
        existing.source_text = payload.sourceText
        existing.confidence = payload.confidence
        existing.updated_at = now
        session.add(existing)
        session.commit()
        session.refresh(existing)
        return _to_response(existing)
    memory = CloudMemory(
        id=payload.id,
        user_id=payload.userId,
        title=payload.title,
        content=payload.content,
        scope=payload.scope,
        category=payload.category,
        source_text=payload.sourceText,
        confidence=payload.confidence,
        created_at=now,
        updated_at=now,
    )
    session.add(memory)
    session.commit()
    session.refresh(memory)
    return _to_response(memory)


@router.put("/capsules/{memory_id}")
def update_memory_capsule(
    memory_id: str,
    payload: MemoryCapsuleUpdatePayload,
    session: Session = Depends(get_session),
) -> dict[str, object]:
    memory = session.get(CloudMemory, memory_id)
    if not memory:
        raise HTTPException(status_code=404, detail="Memory capsule not found")
    memory.title = payload.title
    memory.content = payload.content
    if payload.scope is not None:
        memory.scope = payload.scope
    if payload.category is not None:
        memory.category = payload.category
    if payload.status is not None:
        memory.status = payload.status
    memory.updated_at = utc_now()
    session.add(memory)
    session.commit()
    session.refresh(memory)
    return _to_response(memory)


@router.delete("/capsules/{memory_id}")
def delete_memory_capsule(memory_id: str, session: Session = Depends(get_session)) -> dict[str, bool]:
    memory = session.get(CloudMemory, memory_id)
    if not memory:
        raise HTTPException(status_code=404, detail="Memory capsule not found")
    session.delete(memory)
    session.commit()
    return {"deleted": True}


@router.get("/export")
def export_memories(
    userId: str = Query(default="guest"),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    memories = session.exec(select(CloudMemory).where(CloudMemory.user_id == userId)).all()
    return {"userId": userId, "items": [_to_response(memory) for memory in memories]}


@router.delete("/capsules")
def clear_memory_capsules(
    userId: str = Query(default="guest"),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    memories = session.exec(select(CloudMemory).where(CloudMemory.user_id == userId)).all()
    count = len(memories)
    for memory in memories:
        session.delete(memory)
    session.commit()
    return {"deleted": count, "userId": userId}