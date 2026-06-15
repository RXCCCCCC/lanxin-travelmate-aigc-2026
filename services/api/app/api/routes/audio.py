from fastapi import APIRouter


router = APIRouter(prefix="/audio", tags=["audio"])


@router.get("/status")
def audio_placeholder() -> dict[str, str]:
    return {"status": "mock"}
