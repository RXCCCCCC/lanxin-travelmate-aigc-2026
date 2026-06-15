from fastapi import APIRouter


router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/guest")
def guest_auth_placeholder() -> dict[str, str]:
    return {"mode": "guest", "status": "mock"}
