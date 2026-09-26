import json
from uuid import uuid4

from sqlmodel import Session

from app.db.models import ModelCallLog, utc_now


def persist_model_call_logs(session: Session, records: list[dict[str, object]]) -> None:
    if not records:
        return
    for record in records:
        session.add(
            ModelCallLog(
                id=f"model-{uuid4().hex}",
                provider=str(record.get("provider") or "unknown"),
                scenario=str(record.get("scenario") or "unknown"),
                fallback=bool(record.get("fallback", False)),
                elapsed_ms=int(record.get("elapsedMs") or 0),
                error=str(record["error"]) if record.get("error") else None,
                request_summary_json=json.dumps(record.get("requestSummary") or {}, ensure_ascii=False),
                created_at=utc_now(),
            )
        )
    session.commit()
