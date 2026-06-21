from datetime import UTC, datetime

from sqlmodel import Field, SQLModel


def utc_now() -> datetime:
    return datetime.now(UTC)


class User(SQLModel, table=True):
    __tablename__ = "users"

    id: str = Field(primary_key=True)
    display_name: str
    auth_mode: str = "guest"
    created_at: datetime = Field(default_factory=utc_now)
    last_active_at: datetime = Field(default_factory=utc_now)


class AuthCredential(SQLModel, table=True):
    __tablename__ = "auth_credentials"

    id: str = Field(primary_key=True)
    user_id: str = Field(index=True)
    provider: str
    subject: str
    password_hash: str | None = None


class CloudMemory(SQLModel, table=True):
    __tablename__ = "cloud_memories"

    id: str = Field(primary_key=True)
    user_id: str = Field(default="guest", index=True)
    title: str
    content: str
    scope: str
    category: str = "travel_preference"
    status: str = "confirmed"
    source_text: str | None = None
    confidence: float = 1.0
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)


class CloudUserProfile(SQLModel, table=True):
    __tablename__ = "cloud_user_profiles"

    id: str = Field(primary_key=True)
    user_id: str = Field(index=True)
    profile_json: str
    updated_at: datetime = Field(default_factory=utc_now)


class CloudTrip(SQLModel, table=True):
    __tablename__ = "cloud_trips"

    id: str = Field(primary_key=True)
    user_id: str = Field(default="guest", index=True)
    destination: str
    destination_type: str = "city"
    status: str = "planning"
    start_date: str | None = None
    end_date: str | None = None
    budget: str | None = None
    companions_json: str = "[]"
    trip_style: str | None = None
    plan_json: str = "{}"
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)


class CloudTripReview(SQLModel, table=True):
    __tablename__ = "cloud_trip_reviews"

    id: str = Field(primary_key=True)
    trip_id: str = Field(index=True)
    review_json: str


class SyncRecord(SQLModel, table=True):
    __tablename__ = "sync_records"

    id: str = Field(primary_key=True)
    user_id: str = Field(index=True)
    entity_type: str
    entity_id: str
    status: str
    created_at: datetime = Field(default_factory=utc_now)


class ModelCallLog(SQLModel, table=True):
    __tablename__ = "model_call_logs"

    id: str = Field(primary_key=True)
    provider: str
    scenario: str
    fallback: bool = False
    elapsed_ms: int = 0
    error: str | None = None
    request_summary_json: str = "{}"
    created_at: datetime = Field(default_factory=utc_now)



class ToolCacheEntry(SQLModel, table=True):
    __tablename__ = "tool_cache_entries"

    cache_key: str = Field(primary_key=True)
    provider: str = Field(index=True)
    path: str = Field(index=True)
    response_json: str
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)

class ToolCallLog(SQLModel, table=True):
    __tablename__ = "tool_call_logs"

    id: str = Field(primary_key=True)
    user_id: str = Field(default="guest", index=True)
    tool_name: str
    mock: bool = True
    provider: str | None = None
    created_at: datetime = Field(default_factory=utc_now)


class UploadedFile(SQLModel, table=True):
    __tablename__ = "uploaded_files"

    id: str = Field(primary_key=True)
    user_id: str = Field(index=True)
    filename: str
    content_type: str
    local_path: str | None = None
    remote_url: str | None = None
    created_at: datetime = Field(default_factory=utc_now)


class PhotoCandidateRecord(SQLModel, table=True):
    __tablename__ = "photo_candidates"

    id: str = Field(primary_key=True)
    user_id: str = Field(default="guest", index=True)
    trip_id: str | None = Field(default=None, index=True)
    local_uri: str | None = None
    remote_url: str | None = None
    location_label: str = "未标注地点"
    content_tags_json: str = "[]"
    share_score: float = 0.0
    description: str = ""
    can_add_to_review: bool = True
    copywriting_json: str = "{}"
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)

class ReminderEvent(SQLModel, table=True):
    __tablename__ = "reminder_events"

    id: str = Field(primary_key=True)
    user_id: str = Field(default="guest", index=True)
    trip_id: str | None = Field(default=None, index=True)
    trigger_type: str
    location: str | None = None
    event_payload_json: str = "{}"
    reminders_json: str = "[]"
    created_at: datetime = Field(default_factory=utc_now)

class GroupCoordinationRecord(SQLModel, table=True):
    __tablename__ = "group_coordination_records"

    id: str = Field(primary_key=True)
    user_id: str = Field(default="guest", index=True)
    trip_id: str = Field(index=True)
    destination: str | None = None
    members_json: str = "[]"
    conflicts_json: str = "[]"
    compromise_plan_json: str = "{}"
    privacy_summary_json: str = "{}"
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)

class BlindBoxTaskRecord(SQLModel, table=True):
    __tablename__ = "blind_box_task_records"

    id: str = Field(primary_key=True)
    user_id: str = Field(default="guest", index=True)
    trip_id: str = Field(index=True)
    task_id: str = Field(index=True)
    status: str = "available"
    note: str | None = None
    reward_applied: bool = False
    accepted_at: datetime | None = None
    completed_at: datetime | None = None
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)
class TripRoutePointRecord(SQLModel, table=True):
    __tablename__ = "trip_route_points"

    id: str = Field(primary_key=True)
    user_id: str = Field(default="guest", index=True)
    trip_id: str = Field(index=True)
    sequence: int = 0
    label: str
    latitude: float
    longitude: float
    source: str = "device"
    recorded_at: str | None = None
    created_at: datetime = Field(default_factory=utc_now)
class AvatarStateEventRecord(SQLModel, table=True):
    __tablename__ = "avatar_state_events"

    id: str = Field(primary_key=True)
    user_id: str = Field(default="guest", index=True)
    trip_id: str = Field(index=True)
    event_type: str = Field(index=True)
    title: str
    deltas_json: str = "{}"
    reason: str = ""
    created_at: datetime = Field(default_factory=utc_now)
