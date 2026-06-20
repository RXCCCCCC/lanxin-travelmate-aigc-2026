"""initial schema

Revision ID: 0001_initial_schema
Revises:
Create Date: 2026-06-19 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0001_initial_schema"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("display_name", sa.String(), nullable=False),
        sa.Column("auth_mode", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("last_active_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "auth_credentials",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("provider", sa.String(), nullable=False),
        sa.Column("subject", sa.String(), nullable=False),
        sa.Column("password_hash", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_auth_credentials_user_id", "auth_credentials", ["user_id"])

    op.create_table(
        "cloud_memories",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("title", sa.String(), nullable=False),
        sa.Column("content", sa.String(), nullable=False),
        sa.Column("scope", sa.String(), nullable=False),
        sa.Column("category", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("source_text", sa.String(), nullable=True),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_cloud_memories_user_id", "cloud_memories", ["user_id"])

    op.create_table(
        "cloud_user_profiles",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("profile_json", sa.String(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_cloud_user_profiles_user_id", "cloud_user_profiles", ["user_id"])

    op.create_table(
        "cloud_trips",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("destination", sa.String(), nullable=False),
        sa.Column("destination_type", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("start_date", sa.String(), nullable=True),
        sa.Column("end_date", sa.String(), nullable=True),
        sa.Column("budget", sa.String(), nullable=True),
        sa.Column("companions_json", sa.String(), nullable=False),
        sa.Column("trip_style", sa.String(), nullable=True),
        sa.Column("plan_json", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_cloud_trips_user_id", "cloud_trips", ["user_id"])

    op.create_table(
        "cloud_trip_reviews",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("trip_id", sa.String(), nullable=False),
        sa.Column("review_json", sa.String(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_cloud_trip_reviews_trip_id", "cloud_trip_reviews", ["trip_id"])

    op.create_table(
        "sync_records",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("entity_type", sa.String(), nullable=False),
        sa.Column("entity_id", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_sync_records_user_id", "sync_records", ["user_id"])

    op.create_table(
        "model_call_logs",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("provider", sa.String(), nullable=False),
        sa.Column("scenario", sa.String(), nullable=False),
        sa.Column("fallback", sa.Boolean(), nullable=False),
        sa.Column("elapsed_ms", sa.Integer(), nullable=False),
        sa.Column("error", sa.String(), nullable=True),
        sa.Column("request_summary_json", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "tool_cache_entries",
        sa.Column("cache_key", sa.String(), nullable=False),
        sa.Column("provider", sa.String(), nullable=False),
        sa.Column("path", sa.String(), nullable=False),
        sa.Column("response_json", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("cache_key"),
    )
    op.create_index("ix_tool_cache_entries_provider", "tool_cache_entries", ["provider"])
    op.create_index("ix_tool_cache_entries_path", "tool_cache_entries", ["path"])

    op.create_table(
        "tool_call_logs",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("tool_name", sa.String(), nullable=False),
        sa.Column("mock", sa.Boolean(), nullable=False),
        sa.Column("provider", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "uploaded_files",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("filename", sa.String(), nullable=False),
        sa.Column("content_type", sa.String(), nullable=False),
        sa.Column("local_path", sa.String(), nullable=True),
        sa.Column("remote_url", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_uploaded_files_user_id", "uploaded_files", ["user_id"])

    op.create_table(
        "photo_candidates",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("trip_id", sa.String(), nullable=True),
        sa.Column("local_uri", sa.String(), nullable=True),
        sa.Column("remote_url", sa.String(), nullable=True),
        sa.Column("location_label", sa.String(), nullable=False),
        sa.Column("content_tags_json", sa.String(), nullable=False),
        sa.Column("share_score", sa.Float(), nullable=False),
        sa.Column("description", sa.String(), nullable=False),
        sa.Column("can_add_to_review", sa.Boolean(), nullable=False),
        sa.Column("copywriting_json", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_photo_candidates_user_id", "photo_candidates", ["user_id"])
    op.create_index("ix_photo_candidates_trip_id", "photo_candidates", ["trip_id"])


def downgrade() -> None:
    op.drop_index("ix_photo_candidates_trip_id", table_name="photo_candidates")
    op.drop_index("ix_photo_candidates_user_id", table_name="photo_candidates")
    op.drop_table("photo_candidates")
    op.drop_index("ix_uploaded_files_user_id", table_name="uploaded_files")
    op.drop_table("uploaded_files")
    op.drop_table("tool_call_logs")
    op.drop_index("ix_tool_cache_entries_path", table_name="tool_cache_entries")
    op.drop_index("ix_tool_cache_entries_provider", table_name="tool_cache_entries")
    op.drop_table("tool_cache_entries")
    op.drop_table("model_call_logs")
    op.drop_index("ix_sync_records_user_id", table_name="sync_records")
    op.drop_table("sync_records")
    op.drop_index("ix_cloud_trip_reviews_trip_id", table_name="cloud_trip_reviews")
    op.drop_table("cloud_trip_reviews")
    op.drop_index("ix_cloud_trips_user_id", table_name="cloud_trips")
    op.drop_table("cloud_trips")
    op.drop_index("ix_cloud_user_profiles_user_id", table_name="cloud_user_profiles")
    op.drop_table("cloud_user_profiles")
    op.drop_index("ix_cloud_memories_user_id", table_name="cloud_memories")
    op.drop_table("cloud_memories")
    op.drop_index("ix_auth_credentials_user_id", table_name="auth_credentials")
    op.drop_table("auth_credentials")
    op.drop_table("users")