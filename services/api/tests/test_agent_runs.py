import json
from datetime import UTC, datetime

from sqlalchemy.pool import StaticPool
from sqlmodel import Session, SQLModel, create_engine

from app.services.agent_runs import complete_agent_run, start_agent_run


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
