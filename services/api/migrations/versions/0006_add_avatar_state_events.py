"""add avatar state events

Revision ID: 0006_add_avatar_state_events
Revises: 0005_add_trip_route_points
Create Date: 2026-06-20 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0006_add_avatar_state_events"
down_revision: Union[str, Sequence[str], None] = "0005_add_trip_route_points"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "avatar_state_events",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("trip_id", sa.String(), nullable=False),
        sa.Column("event_type", sa.String(), nullable=False),
        sa.Column("title", sa.String(), nullable=False),
        sa.Column("deltas_json", sa.String(), nullable=False),
        sa.Column("reason", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_avatar_state_events_user_id", "avatar_state_events", ["user_id"])
    op.create_index("ix_avatar_state_events_trip_id", "avatar_state_events", ["trip_id"])
    op.create_index("ix_avatar_state_events_event_type", "avatar_state_events", ["event_type"])


def downgrade() -> None:
    op.drop_index("ix_avatar_state_events_event_type", table_name="avatar_state_events")
    op.drop_index("ix_avatar_state_events_trip_id", table_name="avatar_state_events")
    op.drop_index("ix_avatar_state_events_user_id", table_name="avatar_state_events")
    op.drop_table("avatar_state_events")