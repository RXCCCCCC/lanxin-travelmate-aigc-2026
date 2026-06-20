"""add blind box task records

Revision ID: 0004_add_blind_box_task_records
Revises: 0003_add_group_coordination_records
Create Date: 2026-06-20 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0004_add_blind_box_task_records"
down_revision: Union[str, Sequence[str], None] = "0003_add_group_coordination_records"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "blind_box_task_records",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("trip_id", sa.String(), nullable=False),
        sa.Column("task_id", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("note", sa.String(), nullable=True),
        sa.Column("reward_applied", sa.Boolean(), nullable=False),
        sa.Column("accepted_at", sa.DateTime(), nullable=True),
        sa.Column("completed_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_blind_box_task_records_user_id", "blind_box_task_records", ["user_id"])
    op.create_index("ix_blind_box_task_records_trip_id", "blind_box_task_records", ["trip_id"])
    op.create_index("ix_blind_box_task_records_task_id", "blind_box_task_records", ["task_id"])


def downgrade() -> None:
    op.drop_index("ix_blind_box_task_records_task_id", table_name="blind_box_task_records")
    op.drop_index("ix_blind_box_task_records_trip_id", table_name="blind_box_task_records")
    op.drop_index("ix_blind_box_task_records_user_id", table_name="blind_box_task_records")
    op.drop_table("blind_box_task_records")