from collections.abc import Generator

from sqlalchemy import inspect, text
from sqlmodel import Session, SQLModel, create_engine

from app.core.config import get_settings


def _connect_args(database_url: str) -> dict[str, bool]:
    if database_url.startswith("sqlite"):
        return {"check_same_thread": False}
    return {}


settings = get_settings()
engine = create_engine(
    settings.database_url,
    echo=False,
    connect_args=_connect_args(settings.database_url),
)


def _add_column_if_missing(table_name: str, column_name: str, ddl: str) -> None:
    inspector = inspect(engine)
    if table_name not in inspector.get_table_names():
        return
    existing_columns = {column["name"] for column in inspector.get_columns(table_name)}
    if column_name in existing_columns:
        return
    with engine.begin() as connection:
        connection.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {ddl}"))


def _run_lightweight_migrations() -> None:
    if not settings.database_url.startswith("sqlite"):
        return
    _add_column_if_missing("auth_credentials", "password_hash", "password_hash VARCHAR")


def create_db_and_tables() -> None:
    SQLModel.metadata.create_all(engine)
    _run_lightweight_migrations()


def get_session() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session