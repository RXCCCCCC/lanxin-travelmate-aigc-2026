"""add trip review user scope and created time

Revision ID: 0008_trip_review_scope
Revises: 0007_tool_call_user_id
Create Date: 2026-07-05 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0008_trip_review_scope"
down_revision: Union[str, Sequence[str], None] = "0007_tool_call_user_id"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "cloud_trip_reviews",
        sa.Column("user_id", sa.String(), nullable=False, server_default="guest"),
    )
    op.add_column(
        "cloud_trip_reviews",
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
    )
    op.create_index("ix_cloud_trip_reviews_user_id", "cloud_trip_reviews", ["user_id"])
    op.alter_column("cloud_trip_reviews", "user_id", server_default=None)


def downgrade() -> None:
    op.drop_index("ix_cloud_trip_reviews_user_id", table_name="cloud_trip_reviews")
    op.drop_column("cloud_trip_reviews", "created_at")
    op.drop_column("cloud_trip_reviews", "user_id")
