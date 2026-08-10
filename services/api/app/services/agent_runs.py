import hashlib
import hmac
import json
import secrets
from dataclasses import dataclass
from datetime import timedelta
from typing import Any
from uuid import uuid4

from sqlmodel import Session, select

from app.db.models import AgentRunRecord, CloudMemory, utc_now
from app.services.model_providers.call_log import redact_request_summary


PROMPT_VERSION = "travelmate-v1"
DEFAULT_RUN_TTL = timedelta(hours=24)


class AgentRunError(RuntimeError):
    pass


class AgentRunNotFoundError(AgentRunError):
    pass


class AgentRunExpiredError(AgentRunError):
    pass


class ResumeTokenInvalidError(AgentRunError):
    pass


class AgentRunConflictError(AgentRunError):
    pass


@dataclass(frozen=True)
class AgentRunResumeResult:
    run_id: str
    request_id: str
    status: str
    action: str
    saved_memory_ids: list[str]
    already_applied: bool


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


def prepare_agent_run_completion(
    session: Session,
    record: AgentRunRecord,
    *,
    result: dict[str, Any],
    node_trace: list[dict[str, Any]] | None = None,
) -> tuple[AgentRunRecord, str | None]:
    candidates = _pending_memory_candidates(result)
    if not candidates:
        return (
            complete_agent_run(
                session,
                record,
                result=result,
                node_trace=node_trace,
            ),
            None,
        )

    resume_token = secrets.token_urlsafe(32)
    pending_result = dict(result)
    pending_result["pending_confirmation"] = {
        "tokenHash": _token_hash(resume_token),
        "candidates": candidates,
        "decision": None,
        "savedMemoryIds": [],
    }
    pending = complete_agent_run(
        session,
        record,
        result=pending_result,
        node_trace=node_trace,
        status="pending_confirmation",
    )
    return pending, resume_token


def resume_agent_run(
    session: Session,
    *,
    run_id: str,
    user_id: str,
    resume_token: str,
    action: str,
    candidate_ids: list[str] | None = None,
) -> AgentRunResumeResult:
    record = session.exec(
        select(AgentRunRecord).where(
            AgentRunRecord.run_id == run_id,
            AgentRunRecord.user_id == user_id,
        )
    ).first()
    if not record:
        raise AgentRunNotFoundError("Agent run not found")
    if _run_is_expired(record):
        raise AgentRunExpiredError("Agent run expired")

    state = json.loads(record.state_json or "{}")
    pending = state.get("pendingConfirmation")
    if not isinstance(pending, dict):
        raise AgentRunConflictError("Agent run is not awaiting confirmation")
    token_hash = str(pending.get("tokenHash") or "")
    if not token_hash or not hmac.compare_digest(token_hash, _token_hash(resume_token)):
        raise ResumeTokenInvalidError("Resume token is invalid")

    normalized_action = str(action or "").strip().lower()
    if normalized_action not in {"confirm", "cancel"}:
        raise AgentRunConflictError("Unsupported resume action")
    decision = pending.get("decision")
    if isinstance(decision, dict) and decision.get("action"):
        previous_action = str(decision["action"])
        if previous_action != normalized_action:
            raise AgentRunConflictError("Agent run already resumed with another action")
        return AgentRunResumeResult(
            run_id=record.run_id,
            request_id=record.request_id,
            status=record.status,
            action=previous_action,
            saved_memory_ids=[
                str(item)
                for item in pending.get("savedMemoryIds", [])
                if isinstance(item, str)
            ],
            already_applied=True,
        )

    saved_memory_ids: list[str] = []
    if normalized_action == "confirm":
        selected_ids = {str(item) for item in (candidate_ids or []) if str(item).strip()}
        candidates = pending.get("candidates") if isinstance(pending.get("candidates"), list) else []
        for candidate in candidates:
            if not isinstance(candidate, dict):
                continue
            candidate_id = str(candidate.get("id") or "")
            if selected_ids and candidate_id not in selected_ids:
                continue
            memory = _upsert_confirmed_memory(session, record, candidate)
            saved_memory_ids.append(memory.id)

    pending["decision"] = {"action": normalized_action}
    pending["savedMemoryIds"] = saved_memory_ids
    record.status = "completed"
    record.state_json = json.dumps(state, ensure_ascii=False, separators=(",", ":"))
    record.summary = f"{record.summary}; confirmation={normalized_action}; memories={len(saved_memory_ids)}"
    record.updated_at = utc_now()
    session.add(record)
    session.commit()
    session.refresh(record)
    return AgentRunResumeResult(
        run_id=record.run_id,
        request_id=record.request_id,
        status=record.status,
        action=normalized_action,
        saved_memory_ids=saved_memory_ids,
        already_applied=False,
    )


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
            "pendingConfirmation": (
                dict(result["pending_confirmation"])
                if isinstance(result.get("pending_confirmation"), dict)
                else None
            ),
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


def _pending_memory_candidates(result: dict[str, Any]) -> list[dict[str, Any]]:
    response = result.get("response") if isinstance(result.get("response"), dict) else {}
    raw_candidates = response.get("memoryCandidates")
    if not isinstance(raw_candidates, list):
        raw_candidates = result.get("memory_candidates")
    if not isinstance(raw_candidates, list):
        return []
    candidates: list[dict[str, Any]] = []
    for item in raw_candidates:
        if not isinstance(item, dict) or not bool(item.get("requiresExplicitConsent")):
            continue
        candidate_id = str(item.get("id") or "").strip()
        title = str(item.get("title") or "").strip()
        memory_value = str(item.get("content") or title).strip()
        if not candidate_id or not title or not memory_value:
            continue
        candidates.append(
            {
                "id": candidate_id,
                "title": title,
                "memoryValue": memory_value,
                "category": str(item.get("category") or "travel_preference"),
                "scope": str(item.get("recommendedScope") or "currentTrip"),
                "confidence": float(item.get("confidence") or 1.0),
                "sensitivity": str(item.get("sensitivity") or "personal"),
            }
        )
    return candidates


def _upsert_confirmed_memory(
    session: Session,
    record: AgentRunRecord,
    candidate: dict[str, Any],
) -> CloudMemory:
    candidate_id = str(candidate.get("id") or "")
    digest = hashlib.sha256(f"{record.user_id}:{candidate_id}".encode("utf-8")).hexdigest()[:24]
    memory_id = f"memory-{digest}"
    scope = str(candidate.get("scope") or "currentTrip")
    if scope not in {"longTerm", "currentTrip"}:
        scope = "currentTrip" if record.trip_id else "longTerm"
    if scope == "currentTrip" and not record.trip_id:
        scope = "longTerm"
    now = utc_now()
    memory = session.get(CloudMemory, memory_id)
    if not memory:
        memory = CloudMemory(
            id=memory_id,
            user_id=record.user_id,
            title=str(candidate.get("title") or "旅行偏好"),
            content=str(candidate.get("memoryValue") or candidate.get("title") or ""),
            scope=scope,
            category=str(candidate.get("category") or "travel_preference"),
            status="confirmed",
            source_text=record.trip_id if scope == "currentTrip" else None,
            confidence=float(candidate.get("confidence") or 1.0),
            created_at=now,
            updated_at=now,
        )
    else:
        memory.title = str(candidate.get("title") or memory.title)
        memory.content = str(candidate.get("memoryValue") or memory.content)
        memory.scope = scope
        memory.category = str(candidate.get("category") or memory.category)
        memory.status = "confirmed"
        memory.source_text = record.trip_id if scope == "currentTrip" else None
        memory.confidence = float(candidate.get("confidence") or memory.confidence)
        memory.updated_at = now
    session.add(memory)
    return memory


def _token_hash(value: str) -> str:
    return hashlib.sha256(str(value).encode("utf-8")).hexdigest()


def _run_is_expired(record: AgentRunRecord) -> bool:
    now = utc_now()
    expires_at = record.expires_at
    if expires_at.tzinfo is None:
        now = now.replace(tzinfo=None)
    return expires_at <= now
