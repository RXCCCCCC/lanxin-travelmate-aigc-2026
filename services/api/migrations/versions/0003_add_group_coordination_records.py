"""add group coordination records

Revision ID: 0003_add_group_coordination_records
Revises: 0002_add_reminder_events
Create Date: 2026-06-20 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0003_add_group_coordination_records"
down_revision: Union[str, Sequence[str], None] = "0002_add_reminder_events"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "group_coordination_records",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("trip_id", sa.String(), nullable=False),
        sa.Column("destination", sa.String(), nullable=True),
        sa.Column("members_json", sa.String(), nullable=False),
        sa.Column("conflicts_json", sa.String(), nullable=False),
        sa.Column("compromise_plan_json", sa.String(), nullable=False),
        sa.Column("privacy_summary_json", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_group_coordination_records_user_id", "group_coordination_records", ["user_id"])
    op.create_index("ix_group_coordination_records_trip_id", "group_coordination_records", ["trip_id"])


def downgrade() -> None:
    op.drop_index("ix_group_coordination_records_trip_id", table_name="group_coordination_records")
    op.drop_index("ix_group_coordination_records_user_id", table_name="group_coordination_records")
    op.drop_table("group_coordination_records")