import json
from uuid import uuid4

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field, ValidationError
from sqlmodel import Session, select

from app.agents.travelmate.schemas import PhotoCopywritingOutput
from app.core.config import get_settings
from app.core.security import CurrentUser, get_current_user, resolve_effective_user_id
from app.db.models import PhotoCandidateRecord, UploadedFile, utc_now
from app.db.session import get_session
from app.services.model_audit import persist_model_call_logs
from app.services.model_providers import ModelProviderError, build_model_provider
from app.services.model_providers.call_log import ModelCallLogger


router = APIRouter(prefix="/photo", tags=["photo"])


class CopywritingSchemaError(ValueError):
    def __init__(self, provider: str, message: str) -> None:
        super().__init__(message)
        self.provider = provider


class PhotoCandidatePayload(BaseModel):
    id: str | None = None
    userId: str = "guest"
    tripId: str | None = None
    localUri: str | None = None
    remoteUrl: str | None = None
    location: str = "未标注地点"
    score: float = Field(default=0.0, ge=0, le=10)
    description: str = ""
    tags: list[str] = Field(default_factory=list)
    canAddToReview: bool = True


class PhotoUploadMetadataRequest(BaseModel):
    userId: str = "guest"
    filename: str
    contentType: str = "image/jpeg"
    localPath: str | None = None
    remoteUrl: str | None = None


class CopywritingRequest(BaseModel):
    photoIds: list[str] = Field(default_factory=list)
    userId: str = "guest"
    persona: str = "活泼向导"
    style: str = "轻松"


def _candidate_response(item: PhotoCandidateRecord) -> dict[str, object]:
    return {
        "id": item.id,
        "userId": item.user_id,
        "tripId": item.trip_id,
        "localUri": None,
        "remoteUrl": item.remote_url,
        "location": item.location_label,
        "score": item.share_score,
        "description": item.description,
        "tags": json.loads(item.content_tags_json),
        "canAddToReview": item.can_add_to_review,
        "copywriting": json.loads(item.copywriting_json),
        "createdAt": item.created_at.isoformat(),
        "updatedAt": item.updated_at.isoformat(),
    }


def _copywriting_for(candidates: list[PhotoCandidateRecord], persona: str, style: str) -> dict[str, object]:
    locations = [item.location_label for item in candidates] or ["旅途中"]
    tags = sorted({tag for item in candidates for tag in json.loads(item.content_tags_json)})
    tag_text = "、".join(tags[:4]) if tags else "真实旅拍"
    location_text = "、".join(locations[:3])
    persona_hint = f"蓝小心以{persona}语气"
    return {
        "photoIds": [item.id for item in candidates],
        "persona": persona,
        "style": style,
        "moments": f"朋友圈文案：在{location_text}收下今天的高光，{tag_text}都刚刚好。{persona_hint}提醒你记得慢慢看。",
        "xiaohongshu": f"小红书文案：{location_text}旅拍候选｜{style}风格出片记录，标签：{tag_text}。",
        "diary": f"旅行日记：今天的照片来自{location_text}，这些画面会进入复盘，成为下一次旅行画像的线索。",
        "vlogNarration": f"Vlog 旁白：镜头来到{location_text}，蓝小心说，这一段值得放进今日高光。",
        "reviewSuggestion": "建议加入今日复盘的高光照片区。",
    }


def _candidate_prompt_context(candidates: list[PhotoCandidateRecord], persona: str, style: str) -> dict[str, object]:
    return {
        "persona": persona,
        "style": style,
        "photos": [
            {
                "id": item.id,
                "location": item.location_label,
                "score": item.share_score,
                "description": item.description,
                "tags": json.loads(item.content_tags_json),
            }
            for item in candidates
        ],
    }


def _first_text(payload: dict[str, object], keys: list[str]) -> str:
    for key in keys:
        value = payload.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


def _normalize_copywriting_payload(
    payload: dict[str, object],
    candidates: list[PhotoCandidateRecord],
    persona: str,
    style: str,
) -> dict[str, object]:
    root = payload.get("photoCopywriting")
    if isinstance(root, dict):
        return {"photoCopywriting": dict(root)}

    normalized = dict(payload)
    fallback = _copywriting_for(candidates, persona, style)
    normalized["photoIds"] = normalized.get("photoIds") if isinstance(normalized.get("photoIds"), list) else fallback["photoIds"]
    normalized["persona"] = _first_text(normalized, ["persona", "tone", "voice"]) or persona
    normalized["style"] = _first_text(normalized, ["style", "copyStyle"]) or style
    normalized["moments"] = _first_text(normalized, ["moments", "moment", "wechat", "wechatMoments", "friendCircle"]) or fallback["moments"]
    normalized["xiaohongshu"] = _first_text(normalized, ["xiaohongshu", "xhs", "rednote", "redBook"]) or fallback["xiaohongshu"]
    normalized["diary"] = _first_text(normalized, ["diary", "travelDiary", "journal"]) or fallback["diary"]
    normalized["vlogNarration"] = _first_text(normalized, ["vlogNarration", "vlog", "narration", "voiceover"]) or fallback["vlogNarration"]
    normalized["reviewSuggestion"] = _first_text(normalized, ["reviewSuggestion", "review", "summarySuggestion"]) or fallback["reviewSuggestion"]
    return {"photoCopywriting": normalized}


def _copywriting_with_model(
    candidates: list[PhotoCandidateRecord],
    persona: str,
    style: str,
    logger: ModelCallLogger,
) -> dict[str, object]:
    provider = build_model_provider(get_settings())
    context = _candidate_prompt_context(candidates, persona, style)
    timer = logger.track(
        provider.name,
        "photo_copywriting",
        {
            "photoCount": len(candidates),
            "photoIds": [item.id for item in candidates],
            "persona": persona,
            "style": style,
        },
    )
    try:
        payload = provider.generate_json(
            scenario="photo_copywriting",
            system_prompt="Return structured travel photo copywriting JSON only.",
            user_prompt=json.dumps(context, ensure_ascii=False),
            schema={"task": "photoCopywriting"},
        )
        normalized = _normalize_copywriting_payload(payload, candidates, persona, style)
        output = PhotoCopywritingOutput.model_validate(normalized["photoCopywriting"])
    except ValidationError as exc:
        timer.finish(fallback=True, error=f"schema_validation:{exc}")
        raise CopywritingSchemaError(provider.name, str(exc)) from exc
    except ModelProviderError as exc:
        timer.finish(fallback=True, error=f"provider_error:{exc}")
        raise
    except Exception as exc:
        timer.finish(fallback=True, error=f"unexpected_error:{exc}")
        raise
    timer.finish(fallback=False)
    result = output.model_dump()
    result["provider"] = provider.name
    result["fallback"] = False
    result["errorType"] = None
    return result


def _copywriting_fallback(
    candidates: list[PhotoCandidateRecord],
    persona: str,
    style: str,
    *,
    provider: str,
    error_type: str,
    fallback_reason: str,
) -> dict[str, object]:
    copywriting = _copywriting_for(candidates, persona, style)
    copywriting["provider"] = provider
    copywriting["fallback"] = True
    copywriting["errorType"] = error_type
    copywriting["fallbackReason"] = fallback_reason
    return copywriting


@router.get("/candidates")
def list_photo_candidates(
    userId: str | None = Query(default=None),
    tripId: str | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, list[dict[str, object]]]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    statement = select(PhotoCandidateRecord).where(PhotoCandidateRecord.user_id == effective_user_id)
    if tripId:
        statement = statement.where(PhotoCandidateRecord.trip_id == tripId)
    items = session.exec(statement.order_by(PhotoCandidateRecord.updated_at.desc())).all()
    return {"items": [_candidate_response(item) for item in items]}

@router.post("/candidates")
def create_photo_candidate(
    payload: PhotoCandidatePayload,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    now = utc_now()
    candidate_id = payload.id or f"photo-{uuid4().hex}"
    item = session.get(PhotoCandidateRecord, candidate_id)
    if item:
        item.user_id = effective_user_id
        item.trip_id = payload.tripId
        item.local_uri = None
        item.remote_url = payload.remoteUrl
        item.location_label = payload.location
        item.share_score = payload.score
        item.description = payload.description
        item.content_tags_json = json.dumps(payload.tags, ensure_ascii=False)
        item.can_add_to_review = payload.canAddToReview
        item.updated_at = now
    else:
        item = PhotoCandidateRecord(
            id=candidate_id,
            user_id=effective_user_id,
            trip_id=payload.tripId,
            local_uri=None,
            remote_url=payload.remoteUrl,
            location_label=payload.location,
            share_score=payload.score,
            description=payload.description,
            content_tags_json=json.dumps(payload.tags, ensure_ascii=False),
            can_add_to_review=payload.canAddToReview,
            created_at=now,
            updated_at=now,
        )
    session.add(item)
    session.commit()
    session.refresh(item)
    return _candidate_response(item)

@router.post("/upload-metadata")
def create_upload_metadata(
    payload: PhotoUploadMetadataRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    item = UploadedFile(
        id=f"file-{uuid4().hex}",
        user_id=effective_user_id,
        filename=payload.filename,
        content_type=payload.contentType,
        local_path=None,
        remote_url=payload.remoteUrl,
        created_at=utc_now(),
    )
    session.add(item)
    session.commit()
    session.refresh(item)
    return {
        "id": item.id,
        "userId": item.user_id,
        "filename": item.filename,
        "contentType": item.content_type,
        "localPath": None,
        "remoteUrl": item.remote_url,
        "privacy": {"localPathStored": False},
        "createdAt": item.created_at.isoformat(),
    }

@router.post("/copywriting")
def create_photo_copywriting(
    payload: CopywritingRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    if payload.photoIds:
        candidates = session.exec(
            select(PhotoCandidateRecord).where(
                PhotoCandidateRecord.user_id == effective_user_id,
                PhotoCandidateRecord.id.in_(payload.photoIds),
            )
        ).all()
    else:
        candidates = session.exec(
            select(PhotoCandidateRecord)
            .where(PhotoCandidateRecord.user_id == effective_user_id)
            .order_by(PhotoCandidateRecord.updated_at.desc())
        ).all()
    logger = ModelCallLogger()
    try:
        copywriting = _copywriting_with_model(candidates, payload.persona, payload.style, logger)
    except ModelProviderError as exc:
        copywriting = _copywriting_fallback(
            candidates,
            payload.persona,
            payload.style,
            provider=get_settings().model_provider,
            error_type="provider_error",
            fallback_reason=str(exc),
        )
    except CopywritingSchemaError as exc:
        copywriting = _copywriting_fallback(
            candidates,
            payload.persona,
            payload.style,
            provider=exc.provider,
            error_type="schema_validation",
            fallback_reason=str(exc),
        )
    for item in candidates:
        item.copywriting_json = json.dumps(copywriting, ensure_ascii=False)
        item.updated_at = utc_now()
        session.add(item)
    persist_model_call_logs(session, [record.__dict__ for record in logger.records])
    session.commit()
    return copywriting
