import json
from uuid import uuid4

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlmodel import Session, select

from app.db.models import PhotoCandidateRecord, UploadedFile, utc_now
from app.db.session import get_session


router = APIRouter(prefix="/photo", tags=["photo"])


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


@router.get("/candidates")
def list_photo_candidates(
    userId: str = Query(default="guest"),
    tripId: str | None = Query(default=None),
    session: Session = Depends(get_session),
) -> dict[str, list[dict[str, object]]]:
    statement = select(PhotoCandidateRecord).where(PhotoCandidateRecord.user_id == userId)
    if tripId:
        statement = statement.where(PhotoCandidateRecord.trip_id == tripId)
    items = session.exec(statement.order_by(PhotoCandidateRecord.updated_at.desc())).all()
    return {"items": [_candidate_response(item) for item in items]}


@router.post("/candidates")
def create_photo_candidate(
    payload: PhotoCandidatePayload,
    session: Session = Depends(get_session),
) -> dict[str, object]:
    now = utc_now()
    candidate_id = payload.id or f"photo-{uuid4().hex}"
    item = session.get(PhotoCandidateRecord, candidate_id)
    if item:
        item.user_id = payload.userId
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
            user_id=payload.userId,
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
    session: Session = Depends(get_session),
) -> dict[str, object]:
    item = UploadedFile(
        id=f"file-{uuid4().hex}",
        user_id=payload.userId,
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
def create_photo_copywriting(payload: CopywritingRequest, session: Session = Depends(get_session)) -> dict[str, object]:
    if payload.photoIds:
        candidates = session.exec(
            select(PhotoCandidateRecord).where(
                PhotoCandidateRecord.user_id == payload.userId,
                PhotoCandidateRecord.id.in_(payload.photoIds),
            )
        ).all()
    else:
        candidates = session.exec(
            select(PhotoCandidateRecord).where(PhotoCandidateRecord.user_id == payload.userId).order_by(PhotoCandidateRecord.updated_at.desc())
        ).all()
    copywriting = _copywriting_for(candidates, payload.persona, payload.style)
    for item in candidates:
        item.copywriting_json = json.dumps(copywriting, ensure_ascii=False)
        item.updated_at = utc_now()
        session.add(item)
    session.commit()
    return copywriting
