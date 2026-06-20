import json

from fastapi import APIRouter, Depends, Query
from sqlmodel import Session, select

from app.db.models import ModelCallLog, ToolCallLog
from app.db.session import get_session


router = APIRouter(prefix="/audit", tags=["audit"])


def _tool_call_response(record: ToolCallLog) -> dict[str, object]:
    return {
        "toolTraceId": record.id,
        "toolName": record.tool_name,
        "provider": record.provider,
        "mock": record.mock,
        "fallback": record.mock or record.provider in {"fallback", "unconfigured", None},
        "createdAt": record.created_at.isoformat(),
    }


def _model_call_response(record: ModelCallLog) -> dict[str, object]:
    return {
        "modelTraceId": record.id,
        "provider": record.provider,
        "scenario": record.scenario,
        "fallback": record.fallback,
        "elapsedMs": record.elapsed_ms,
        "error": record.error,
        "requestSummary": json.loads(record.request_summary_json),
        "createdAt": record.created_at.isoformat(),
    }


@router.get("/tool-calls")
def read_tool_call_logs(
    toolName: str | None = Query(default=None),
    provider: str | None = Query(default=None),
    fallback: bool | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    statement = select(ToolCallLog)
    if toolName:
        statement = statement.where(ToolCallLog.tool_name == toolName)
    if provider:
        statement = statement.where(ToolCallLog.provider == provider)
    if fallback is not None:
        if fallback:
            statement = statement.where(ToolCallLog.mock == True)  # noqa: E712
        else:
            statement = statement.where(ToolCallLog.mock == False)  # noqa: E712
    records = session.exec(statement.order_by(ToolCallLog.created_at.desc()).limit(limit)).all()
    return {"total": len(records), "items": [_tool_call_response(record) for record in records]}


@router.get("/model-calls")
def read_model_call_logs(
    provider: str | None = Query(default=None),
    scenario: str | None = Query(default=None),
    fallback: bool | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    statement = select(ModelCallLog)
    if provider:
        statement = statement.where(ModelCallLog.provider == provider)
    if scenario:
        statement = statement.where(ModelCallLog.scenario == scenario)
    if fallback is not None:
        statement = statement.where(ModelCallLog.fallback == fallback)
    records = session.exec(statement.order_by(ModelCallLog.created_at.desc()).limit(limit)).all()
    return {"total": len(records), "items": [_model_call_response(record) for record in records]}