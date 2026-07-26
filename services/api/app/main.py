from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

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
        description=(
            "蓝心同行 AI 旅行陪伴 Agent 后端。\n\n"
            "核心能力：LangGraph 状态机 Agent、SSE 流式聊天、"
            "高德天气/POI/路线工具、OpenAI 兼容模型结构化输出、"
            "记忆胶囊、个性化规划、旅行复盘、审计日志。\n\n"
            "GitHub: https://github.com/RXCCCCCC/lanxin-travelmate-aigc-2026"
        ),
    )
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error", "type": type(exc).__name__},
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