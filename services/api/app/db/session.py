from collections.abc import Generator

from sqlmodel import Session, SQLModel, create_engine


engine = create_engine("sqlite:///./lanxin_travelmate.db", echo=False)


def create_db_and_tables() -> None:
    SQLModel.metadata.create_all(engine)


def get_session() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session
