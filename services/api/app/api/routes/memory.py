from pydantic import BaseModel
from fastapi import APIRouter, HTTPException


router = APIRouter(prefix="/memory", tags=["memory"])

_memory_store: dict[str, dict[str, str]] = {}


class MemoryCapsulePayload(BaseModel):
    id: str
    title: str
    content: str
    scope: str


class MemoryCapsuleUpdatePayload(BaseModel):
    title: str
    content: str


@router.get("/capsules")
def list_memory_capsules_placeholder() -> dict[str, list[dict[str, str]]]:
    return {"items": list(_memory_store.values())}


@router.post("/capsules")
def create_memory_capsule(payload: MemoryCapsulePayload) -> dict[str, str]:
    _memory_store[payload.id] = payload.model_dump()
    return _memory_store[payload.id]


@router.put("/capsules/{memory_id}")
def update_memory_capsule(memory_id: str, payload: MemoryCapsuleUpdatePayload) -> dict[str, str]:
    if memory_id not in _memory_store:
        raise HTTPException(status_code=404, detail="Memory capsule not found")
    _memory_store[memory_id]["title"] = payload.title
    _memory_store[memory_id]["content"] = payload.content
    return _memory_store[memory_id]


@router.delete("/capsules/{memory_id}")
def delete_memory_capsule(memory_id: str) -> dict[str, bool]:
    if memory_id not in _memory_store:
        raise HTTPException(status_code=404, detail="Memory capsule not found")
    del _memory_store[memory_id]
    return {"deleted": True}
