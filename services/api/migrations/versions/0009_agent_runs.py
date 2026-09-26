"""add structured agent run state

Revision ID: 0009_agent_runs
Revises: 0008_trip_review_scope
Create Date: 2026-08-10 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0009_agent_runs"
down_revision: Union[str, Sequence[str], None] = "0008_trip_review_scope"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "agent_runs",
        sa.Column("run_id", sa.String(), nullable=False),
        sa.Column("request_id", sa.String(), nullable=False),
        sa.Column("idempotency_key", sa.String(), nullable=True),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("session_id", sa.String(), nullable=False),
        sa.Column("trip_id", sa.String(), nullable=True),
        sa.Column("status", sa.String(), nullable=False, server_default="running"),
        sa.Column("intent", sa.String(), nullable=True),
        sa.Column("state_json", sa.String(), nullable=False, server_default="{}"),
        sa.Column("summary", sa.String(), nullable=False, server_default=""),
        sa.Column("prompt_version", sa.String(), nullable=False, server_default="travelmate-v1"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("run_id"),
        sa.UniqueConstraint(
            "user_id",
            "idempotency_key",
            name="uq_agent_runs_user_id_idempotency_key",
        ),
    )
    op.create_index("ix_agent_runs_request_id", "agent_runs", ["request_id"], unique=True)
    op.create_index("ix_agent_runs_idempotency_key", "agent_runs", ["idempotency_key"])
    op.create_index("ix_agent_runs_user_id", "agent_runs", ["user_id"])
    op.create_index("ix_agent_runs_session_id", "agent_runs", ["session_id"])
    op.create_index("ix_agent_runs_trip_id", "agent_runs", ["trip_id"])
    op.create_index("ix_agent_runs_status", "agent_runs", ["status"])
    op.create_index("ix_agent_runs_expires_at", "agent_runs", ["expires_at"])


def downgrade() -> None:
    op.drop_index("ix_agent_runs_expires_at", table_name="agent_runs")
    op.drop_index("ix_agent_runs_status", table_name="agent_runs")
    op.drop_index("ix_agent_runs_trip_id", table_name="agent_runs")
    op.drop_index("ix_agent_runs_session_id", table_name="agent_runs")
    op.drop_index("ix_agent_runs_user_id", table_name="agent_runs")
    op.drop_index("ix_agent_runs_idempotency_key", table_name="agent_runs")
    op.drop_index("ix_agent_runs_request_id", table_name="agent_runs")
    op.drop_table("agent_runs")
