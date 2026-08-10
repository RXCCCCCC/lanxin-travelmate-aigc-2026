import json
from datetime import timedelta
from typing import Any
from uuid import uuid4

from sqlmodel import Session, select

from app.db.models import AgentRunRecord, utc_now
from app.services.model_providers.call_log import redact_request_summary


PROMPT_VERSION = "travelmate-v1"
DEFAULT_RUN_TTL = timedelta(hours=24)


def start_agent_run(
    session: Session,
    *,
    user_id: str,
    session_id: str | None,
    trip_id: str | None,
    idempotency_key: str | None = None,
) -> AgentRunRecord:
    normalized_key = str(idempotency_key or "").strip() or None
    if normalized_key:
        existing = session.exec(
            select(AgentRunRecord).where(
                AgentRunRecord.user_id == user_id,
                AgentRunRecord.idempotency_key == normalized_key,
            )
        ).first()
        if existing:
            return existing

    now = utc_now()
    record = AgentRunRecord(
        run_id=f"run-{uuid4().hex}",
        request_id=f"req-{uuid4().hex}",
        idempotency_key=normalized_key,
        user_id=user_id,
        session_id=str(session_id or f"session-{uuid4().hex}"),
        trip_id=trip_id,
        status="running",
        prompt_version=PROMPT_VERSION,
        created_at=now,
        updated_at=now,
        expires_at=now + DEFAULT_RUN_TTL,
    )
    session.add(record)
    session.commit()
    session.refresh(record)
    return record


def complete_agent_run(
    session: Session,
    record: AgentRunRecord,
    *,
    result: dict[str, Any],
    node_trace: list[dict[str, Any]] | None = None,
    status: str = "completed",
) -> AgentRunRecord:
    structured_state = _build_structured_state(result, node_trace or [])
    record.status = status
    record.intent = str(result.get("intent") or "") or None
    record.state_json = json.dumps(structured_state, ensure_ascii=False, separators=(",", ":"))
    record.summary = _build_summary(structured_state, status)
    record.updated_at = utc_now()
    session.add(record)
    session.commit()
    session.refresh(record)
    return record


def fail_agent_run(
    session: Session,
    record: AgentRunRecord,
    *,
    error: Exception,
    node_trace: list[dict[str, Any]] | None = None,
) -> AgentRunRecord:
    return complete_agent_run(
        session,
        record,
        result={
            "errors": [{"errorType": type(error).__name__}],
        },
        node_trace=node_trace,
        status="failed",
    )


def _build_structured_state(
    result: dict[str, Any],
    node_trace: list[dict[str, Any]],
) -> dict[str, Any]:
    trip_context = result.get("trip_context") if isinstance(result.get("trip_context"), dict) else {}
    trip_plan = result.get("trip_plan") if isinstance(result.get("trip_plan"), dict) else {}
    memory_references = (
        trip_plan.get("memoryReferences")
        if isinstance(trip_plan.get("memoryReferences"), list)
        else []
    )
    return redact_request_summary(
        {
            "intent": result.get("intent"),
            "tripContext": {
                key: trip_context.get(key)
                for key in ("destination", "durationDays", "pace")
                if trip_context.get(key) is not None
            },
            "memoryReferences": memory_references,
            "toolPlan": _dict_list(result.get("tool_plan")),
            "toolTrace": _dict_list(result.get("tool_trace")),
            "visitedNodes": [
                str(item)
                for item in result.get("visited_nodes", [])
                if isinstance(item, str)
            ],
            "nodeTrace": _dict_list(node_trace),
            "modelCalls": [
                _normalize_model_call(item)
                for item in _dict_list(result.get("model_call_logs"))
            ],
            "errors": _dict_list(result.get("errors")),
        }
    )


def _normalize_model_call(record: dict[str, Any]) -> dict[str, Any]:
    return {
        "provider": str(record.get("provider") or "unknown"),
        "scenario": str(record.get("scenario") or "unknown"),
        "elapsedMs": int(record.get("elapsedMs") or 0),
        "fallback": bool(record.get("fallback", False)),
        "errorType": str(record.get("errorType") or record.get("error") or "") or None,
        "tokenUsage": _normalize_usage(record.get("usage") or record.get("tokenUsage")),
    }


def _normalize_usage(value: object) -> dict[str, Any]:
    if not isinstance(value, dict):
        return {"status": "unknown"}
    input_tokens = value.get("inputTokens", value.get("prompt_tokens"))
    output_tokens = value.get("outputTokens", value.get("completion_tokens"))
    if not isinstance(input_tokens, int) or not isinstance(output_tokens, int):
        return {"status": "unknown"}
    return {
        "status": "reported",
        "inputTokens": input_tokens,
        "outputTokens": output_tokens,
        "totalTokens": int(value.get("totalTokens", value.get("total_tokens", input_tokens + output_tokens))),
    }


def _dict_list(value: object) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    return [dict(item) for item in value if isinstance(item, dict)]


def _build_summary(state: dict[str, Any], status: str) -> str:
    return (
        f"status={status}; intent={state.get('intent') or 'unknown'}; "
        f"nodes={len(state.get('nodeTrace') or [])}; "
        f"tools={len(state.get('toolTrace') or [])}; "
        f"models={len(state.get('modelCalls') or [])}"
    )
