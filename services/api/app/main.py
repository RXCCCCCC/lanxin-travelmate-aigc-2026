from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import agent, audio, audit, auth, health, memory, photo, privacy, profile, sync, tools, trip
from app.core.config import get_settings
from app.core.logging import configure_logging
from app.db.session import create_db_and_tables


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)
    create_db_and_tables()

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="蓝心同行 FastAPI + LangGraph Agent 后端",
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router, prefix=settings.api_prefix)
    app.include_router(agent.router, prefix=settings.api_prefix)
    app.include_router(auth.router, prefix=settings.api_prefix)
    app.include_router(memory.router, prefix=settings.api_prefix)
    app.include_router(profile.router, prefix=settings.api_prefix)
    app.include_router(trip.router, prefix=settings.api_prefix)
    app.include_router(tools.router, prefix=settings.api_prefix)
    app.include_router(sync.router, prefix=settings.api_prefix)
    app.include_router(audio.router, prefix=settings.api_prefix)
    app.include_router(audit.router, prefix=settings.api_prefix)
    app.include_router(photo.router, prefix=settings.api_prefix)
    app.include_router(privacy.router, prefix=settings.api_prefix)
    return app


app = create_app()