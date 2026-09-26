"""add reminder events

Revision ID: 0002_add_reminder_events
Revises: 0001_initial_schema
Create Date: 2026-06-19 00:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0002_add_reminder_events"
down_revision: Union[str, Sequence[str], None] = "0001_initial_schema"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "reminder_events",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("trip_id", sa.String(), nullable=True),
        sa.Column("trigger_type", sa.String(), nullable=False),
        sa.Column("location", sa.String(), nullable=True),
        sa.Column("event_payload_json", sa.String(), nullable=False),
        sa.Column("reminders_json", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_reminder_events_user_id", "reminder_events", ["user_id"])
    op.create_index("ix_reminder_events_trip_id", "reminder_events", ["trip_id"])


def downgrade() -> None:
    op.drop_index("ix_reminder_events_trip_id", table_name="reminder_events")
    op.drop_index("ix_reminder_events_user_id", table_name="reminder_events")
    op.drop_table("reminder_events")