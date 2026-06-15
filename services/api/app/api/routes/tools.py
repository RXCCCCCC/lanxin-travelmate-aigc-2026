from fastapi import APIRouter

from app.tools.registry import build_mock_tool_registry


router = APIRouter(prefix="/tools", tags=["tools"])


@router.get("")
def list_tools() -> dict[str, list[str]]:
    return {"tools": build_mock_tool_registry().tool_names()}
