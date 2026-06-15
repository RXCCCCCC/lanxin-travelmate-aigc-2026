from datetime import datetime

from sqlmodel import Field, SQLModel


class User(SQLModel, table=True):
    __tablename__ = "users"

    id: str = Field(primary_key=True)
    display_name: str
    created_at: datetime = Field(default_factory=datetime.utcnow)


class AuthCredential(SQLModel, table=True):
    __tablename__ = "auth_credentials"

    id: str = Field(primary_key=True)
    user_id: str = Field(index=True)
    provider: str
    subject: str


class CloudMemory(SQLModel, table=True):
    __tablename__ = "cloud_memories"

    id: str = Field(primary_key=True)
    user_id: str = Field(index=True)
    title: str
    content: str
    scope: str
    created_at: datetime = Field(default_factory=datetime.utcnow)


class CloudUserProfile(SQLModel, table=True):
    __tablename__ = "cloud_user_profiles"

    id: str = Field(primary_key=True)
    user_id: str = Field(index=True)
    profile_json: str
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class CloudTrip(SQLModel, table=True):
    __tablename__ = "cloud_trips"

    id: str = Field(primary_key=True)
    user_id: str = Field(index=True)
    destination: str
    status: str


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


class ModelCallLog(SQLModel, table=True):
    __tablename__ = "model_call_logs"

    id: str = Field(primary_key=True)
    provider: str
    scenario: str
    created_at: datetime = Field(default_factory=datetime.utcnow)


class ToolCallLog(SQLModel, table=True):
    __tablename__ = "tool_call_logs"

    id: str = Field(primary_key=True)
    tool_name: str
    mock: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)


class UploadedFile(SQLModel, table=True):
    __tablename__ = "uploaded_files"

    id: str = Field(primary_key=True)
    user_id: str = Field(index=True)
    filename: str
    content_type: str
