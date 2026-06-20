"""add trip route points

Revision ID: 0005_add_trip_route_points
Revises: 0004_add_blind_box_task_records
Create Date: 2026-06-20 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0005_add_trip_route_points"
down_revision: Union[str, Sequence[str], None] = "0004_add_blind_box_task_records"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "trip_route_points",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("trip_id", sa.String(), nullable=False),
        sa.Column("sequence", sa.Integer(), nullable=False),
        sa.Column("label", sa.String(), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.Column("source", sa.String(), nullable=False),
        sa.Column("recorded_at", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_trip_route_points_user_id", "trip_route_points", ["user_id"])
    op.create_index("ix_trip_route_points_trip_id", "trip_route_points", ["trip_id"])


def downgrade() -> None:
    op.drop_index("ix_trip_route_points_trip_id", table_name="trip_route_points")
    op.drop_index("ix_trip_route_points_user_id", table_name="trip_route_points")
    op.drop_table("trip_route_points")