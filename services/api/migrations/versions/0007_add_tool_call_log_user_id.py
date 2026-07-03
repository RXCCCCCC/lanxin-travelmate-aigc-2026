"""add tool call log user ownership

Revision ID: 0007_tool_call_user_id
Revises: 0006_add_avatar_state_events
Create Date: 2026-06-21 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0007_tool_call_user_id"
down_revision: Union[str, Sequence[str], None] = "0006_add_avatar_state_events"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "tool_call_logs",
        sa.Column("user_id", sa.String(), nullable=False, server_default="guest"),
    )
    op.create_index("ix_tool_call_logs_user_id", "tool_call_logs", ["user_id"])
    op.alter_column("tool_call_logs", "user_id", server_default=None)


def downgrade() -> None:
    op.drop_index("ix_tool_call_logs_user_id", table_name="tool_call_logs")
    op.drop_column("tool_call_logs", "user_id")
