from fastapi import APIRouter

from app.core.config import get_settings
from app.schemas.health import HealthResponse


router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse, summary="健康检查")
def read_health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        status="ok",
        service="lanxin-travelmate-api",
        version=settings.app_version,
    )
