import json
from datetime import UTC, datetime, timedelta

from sqlalchemy.pool import StaticPool
from sqlmodel import Session, SQLModel, create_engine, select

from app.db.models import AgentRunRecord, CloudMemory
from app.services.agent_runs import (
    AgentRunExpiredError,
    AgentRunNotFoundError,
    ResumeTokenInvalidError,
    complete_agent_run,
    prepare_agent_run_completion,
    resume_agent_run,
    start_agent_run,
)


def _session() -> Session:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    SQLModel.metadata.create_all(engine)
    return Session(engine)


def test_start_agent_run_is_idempotent_within_user_scope():
    with _session() as session:
        first = start_agent_run(
            session,
            user_id="user-a",
            session_id="session-a",
            trip_id="trip-a",
            idempotency_key="message-1",
        )
        repeated = start_agent_run(
            session,
            user_id="user-a",
            session_id="session-a",
            trip_id="trip-a",
            idempotency_key="message-1",
        )
        other_user = start_agent_run(
            session,
            user_id="user-b",
            session_id="session-b",
            trip_id=None,
            idempotency_key="message-1",
        )
        first_run_id = first.run_id
        first_request_id = first.request_id
        repeated_run_id = repeated.run_id
        repeated_request_id = repeated.request_id
        other_user_run_id = other_user.run_id
        first_expires_at = first.expires_at

    assert repeated_run_id == first_run_id
    assert repeated_request_id == first_request_id
    assert other_user_run_id != first_run_id
    assert first_expires_at > datetime.now(UTC).replace(tzinfo=None)


def test_complete_agent_run_persists_redacted_trace_and_unknown_usage():
    raw_message = "只用于断言不应落库的完整用户消息-TRACE-SECRET"
    with _session() as session:
        run = start_agent_run(
            session,
            user_id="user-a",
            session_id="session-a",
            trip_id="trip-a",
        )
        completed = complete_agent_run(
            session,
            run,
            result={
                "message": raw_message,
                "context": {"recentMessages": [{"content": raw_message}]},
                "intent": "trip_planning",
                "visited_nodes": ["input_normalizer", "tool_executor"],
                "trip_context": {"destination": "广州", "durationDays": 2, "pace": "slow"},
                "tool_plan": [{"stepId": "weather", "tool": "weather_tool"}],
                "tool_trace": [{"stepId": "weather", "tool": "weather_tool", "elapsedMs": 12}],
                "trip_plan": {"memoryReferences": [{"memoryId": "memory-1", "title": "慢节奏"}]},
                "model_call_logs": [
                    {
                        "provider": "lanxin",
                        "scenario": "trip_planning",
                        "elapsedMs": 80,
                        "fallback": False,
                    }
                ],
                "errors": [],
            },
            node_trace=[
                {"node": "input_normalizer", "elapsedMs": 2, "status": "completed"},
                {"node": "tool_executor", "elapsedMs": 15, "status": "completed"},
            ],
        )

    state = json.loads(completed.state_json)
    assert completed.status == "completed"
    assert completed.intent == "trip_planning"
    assert state["tripContext"]["destination"] == "广州"
    assert state["nodeTrace"][1]["elapsedMs"] == 15
    assert state["modelCalls"][0]["tokenUsage"] == {"status": "unknown"}
    assert raw_message not in completed.state_json
    assert "recentMessages" not in completed.state_json


def test_resume_agent_run_confirms_memory_once_with_user_scoped_id():
    with _session() as session:
        run = start_agent_run(
            session,
            user_id="user-a",
            session_id="session-a",
            trip_id="trip-a",
        )
        pending, resume_token = prepare_agent_run_completion(
            session,
            run,
            result={
                "intent": "chat",
                "response": {
                    "memoryCandidates": [
                        {
                            "id": "mem-cilantro",
                            "title": "不吃香菜",
                            "content": "用户不吃香菜。",
                            "category": "dietary_preference",
                            "recommendedScope": "longTerm",
                            "confidence": 0.96,
                            "requiresExplicitConsent": True,
                        }
                    ]
                },
            },
        )
        pending_status = pending.status

        first = resume_agent_run(
            session,
            run_id=pending.run_id,
            user_id="user-a",
            resume_token=resume_token,
            action="confirm",
            candidate_ids=["mem-cilantro"],
        )
        repeated = resume_agent_run(
            session,
            run_id=pending.run_id,
            user_id="user-a",
            resume_token=resume_token,
            action="confirm",
            candidate_ids=["mem-cilantro"],
        )
        memories = session.exec(
            select(CloudMemory).where(CloudMemory.user_id == "user-a")
        ).all()

    assert pending_status == "pending_confirmation"
    assert resume_token
    assert first.status == "completed"
    assert first.already_applied is False
    assert repeated.already_applied is True
    assert first.saved_memory_ids == repeated.saved_memory_ids
    assert len(memories) == 1
    assert memories[0].title == "不吃香菜"
    assert memories[0].source_text is None


def test_resume_agent_run_cancel_completes_without_saving_memory():
    with _session() as session:
        run = start_agent_run(
            session,
            user_id="user-a",
            session_id="session-a",
            trip_id="trip-a",
        )
        pending, resume_token = prepare_agent_run_completion(
            session,
            run,
            result={
                "response": {
                    "memoryCandidates": [
                        {
                            "id": "memory-1",
                            "title": "膝盖不适",
                            "content": "用户当前膝盖不适。",
                            "category": "health",
                            "recommendedScope": "currentTrip",
                            "requiresExplicitConsent": True,
                        }
                    ]
                }
            },
        )

        result = resume_agent_run(
            session,
            run_id=pending.run_id,
            user_id="user-a",
            resume_token=resume_token,
            action="cancel",
        )
        memories = session.exec(select(CloudMemory)).all()

    assert result.status == "completed"
    assert result.saved_memory_ids == []
    assert memories == []


def test_resume_agent_run_rejects_other_user_invalid_token_and_expired_run():
    with _session() as session:
        run = start_agent_run(
            session,
            user_id="user-a",
            session_id="session-a",
            trip_id=None,
        )
        pending, resume_token = prepare_agent_run_completion(
            session,
            run,
            result={
                "response": {
                    "memoryCandidates": [
                        {
                            "id": "memory-1",
                            "title": "慢节奏",
                            "content": "偏好慢节奏。",
                            "recommendedScope": "longTerm",
                            "requiresExplicitConsent": True,
                        }
                    ]
                }
            },
        )

        try:
            resume_agent_run(
                session,
                run_id=pending.run_id,
                user_id="user-b",
                resume_token=resume_token,
                action="confirm",
            )
            raise AssertionError("other user must not resume this run")
        except AgentRunNotFoundError:
            pass

        try:
            resume_agent_run(
                session,
                run_id=pending.run_id,
                user_id="user-a",
                resume_token="wrong-token",
                action="confirm",
            )
            raise AssertionError("invalid token must be rejected")
        except ResumeTokenInvalidError:
            pass

        stored = session.get(AgentRunRecord, pending.run_id)
        stored.expires_at = datetime.now(UTC).replace(tzinfo=None) - timedelta(seconds=1)
        session.add(stored)
        session.commit()
        try:
            resume_agent_run(
                session,
                run_id=pending.run_id,
                user_id="user-a",
                resume_token=resume_token,
                action="confirm",
            )
            raise AssertionError("expired run must be rejected")
        except AgentRunExpiredError:
            pass
