from uuid import uuid4

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlmodel import Session

from app.core.security import CurrentUser, get_current_user, resolve_effective_user_id
from app.db.models import ToolCallLog, utc_now
from app.db.session import get_session
from app.tools.registry import build_mock_tool_registry


router = APIRouter(prefix="/audio", tags=["audio"])


class AsrRequest(BaseModel):
    userId: str = "guest"
    audioRef: str | None = None
    mockText: str | None = None
    language: str = "zh-CN"


class TtsRequest(BaseModel):
    userId: str = "guest"
    text: str = Field(min_length=1)
    voice: str = "lanxiaoxin"
    format: str = "mp3"


def _log_tool_call(session: Session, user_id: str, tool_name: str, provider: str, mock: bool) -> str:
    record = ToolCallLog(
        id=f"tool-{uuid4().hex}",
        user_id=user_id,
        tool_name=tool_name,
        provider=provider,
        mock=mock,
        created_at=utc_now(),
    )
    session.add(record)
    session.commit()
    return record.id


@router.get("/status")
def read_audio_status() -> dict[str, object]:
    return {
        "status": "ready",
        "asr": {"provider": "fallback", "configured": False},
        "tts": {"provider": "fallback", "configured": False},
    }


@router.post("/asr")
def transcribe_audio(
    payload: AsrRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    registry = build_mock_tool_registry()
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    result = registry.call("asr_tool", {"mockText": payload.mockText or ""})
    trace_id = _log_tool_call(session, effective_user_id, "asr_tool", "fallback", True)
    text = result.get("text") or ""
    return {
        "userId": effective_user_id,
        "text": text,
        "language": payload.language,
        "audioRef": payload.audioRef,
        "provider": "fallback",
        "fallback": True,
        "fallbackReason": "真实 ASR 尚未配置；当前仅回传 mockText 或空文本用于端到端联调。",
        "toolTraceId": trace_id,
    }


@router.post("/tts")
def synthesize_speech(
    payload: TtsRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    registry = build_mock_tool_registry()
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    result = registry.call("tts_tool", {"text": payload.text})
    trace_id = _log_tool_call(session, effective_user_id, "tts_tool", "fallback", True)
    return {
        "userId": effective_user_id,
        "voiceText": result.get("voiceText", payload.text),
        "audioUrl": None,
        "voice": payload.voice,
        "format": payload.format,
        "provider": "fallback",
        "fallback": True,
        "fallbackReason": "真实 TTS 尚未配置；当前仅返回待播报文本，端侧可用系统 TTS 或文字模式降级。",
        "toolTraceId": trace_id,
    }