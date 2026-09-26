from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlmodel import Session

from app.core.security import CurrentUser, get_current_user, resolve_effective_user_id
from app.db.models import ToolCallLog, utc_now
from app.db.session import get_session
from app.tools.registry import build_tool_registry


router = APIRouter(prefix="/tools", tags=["tools"])


class ToolCallRequest(BaseModel):
    userId: str = "guest"
    payload: dict[str, object] = Field(default_factory=dict)


def _log_tool_call(session: Session, user_id: str, tool_name: str, result: dict[str, object]) -> str:
    provider = result.get("provider")
    fallback = bool(result.get("fallback", False))
    trace = ToolCallLog(
        id=f"tool-{uuid4().hex}",
        user_id=user_id,
        tool_name=tool_name,
        mock=fallback and provider in {"fallback", "unconfigured", None},
        provider=str(provider) if provider is not None else None,
        created_at=utc_now(),
    )
    session.add(trace)
    session.commit()
    return trace.id


@router.get("")
def list_tools() -> dict[str, list[str]]:
    return {"tools": build_tool_registry().tool_names()}


@router.post("/{tool_name}/call")
def call_tool(
    tool_name: str,
    request: ToolCallRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    registry = build_tool_registry()
    if tool_name not in registry.tool_names():
        raise HTTPException(status_code=404, detail="Tool not registered")
    effective_user_id = resolve_effective_user_id(request.userId, current_user)
    result = registry.call(tool_name, dict(request.payload))
    trace_id = _log_tool_call(session, effective_user_id, tool_name, result)
    return {
        "toolTraceId": trace_id,
        "toolName": tool_name,
        "userId": effective_user_id,
        "result": result,
    }
