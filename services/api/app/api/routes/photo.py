import base64
import binascii
import json
import struct
import zlib
from uuid import uuid4

from fastapi import APIRouter, Depends, Query
import httpx
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


_PLACEHOLDER_LOCATION_MARKERS = (
    "无法仅凭画面确认",
    "无法仅凭这张图确认",
    "无法确认城市或景点",
    "地点待确认",
    "待确认地点",
    "未标注地点",
    "补充地点",
    "待确认照片",
    "无法僅憑",
    "無法僅憑",
    "ÎÞ·¨½öÆ¾",
)


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


class PhotoAnalyzeRequest(BaseModel):
    userId: str = "guest"
    tripId: str | None = None
    filename: str = "preview.jpg"
    contentType: str = "image/jpeg"
    imageBase64: str
    source: str = "gallery"


def _is_placeholder_location(value: object) -> bool:
    text = str(value or "").strip()
    return not text or any(marker in text for marker in _PLACEHOLDER_LOCATION_MARKERS)


def _next_photo_label(session: Session, user_id: str, trip_id: str | None, candidate_id: str) -> str:
    statement = select(PhotoCandidateRecord).where(PhotoCandidateRecord.user_id == user_id)
    if trip_id:
        statement = statement.where(PhotoCandidateRecord.trip_id == trip_id)
    records = session.exec(statement).all()
    count = sum(1 for record in records if record.id != candidate_id)
    return f"图片{count + 1}"


def _safe_photo_location_label(
    session: Session,
    user_id: str,
    trip_id: str | None,
    candidate_id: str,
    proposed_location: object,
) -> str:
    text = str(proposed_location or "").strip()
    if not _is_placeholder_location(text):
        return text
    return _next_photo_label(session, user_id, trip_id, candidate_id)


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


def _image_dimensions(data: bytes) -> tuple[int, int]:
    if data.startswith(b"\x89PNG\r\n\x1a\n") and len(data) >= 24:
        width, height = struct.unpack(">II", data[16:24])
        return int(width), int(height)
    if data.startswith(b"\xff\xd8"):
        index = 2
        while index + 9 < len(data):
            if data[index] != 0xFF:
                index += 1
                continue
            marker = data[index + 1]
            index += 2
            if marker in {0xD8, 0xD9}:
                continue
            if index + 2 > len(data):
                break
            segment_length = int.from_bytes(data[index : index + 2], "big")
            if segment_length < 2 or index + segment_length > len(data):
                break
            if marker in {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}:
                height = int.from_bytes(data[index + 3 : index + 5], "big")
                width = int.from_bytes(data[index + 5 : index + 7], "big")
                return int(width), int(height)
            index += segment_length
    return 0, 0


def _extract_png_rgba_pixels(data: bytes) -> tuple[int, int, list[tuple[int, int, int, int]]] | None:
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        return None
    offset = 8
    width = 0
    height = 0
    bit_depth = 0
    color_type = 0
    compressed = bytearray()

    while offset + 8 <= len(data):
        length = int.from_bytes(data[offset : offset + 4], "big")
        chunk_type = data[offset + 4 : offset + 8]
        chunk_start = offset + 8
        chunk_end = chunk_start + length
        if chunk_end + 4 > len(data):
            return None
        chunk_data = data[chunk_start:chunk_end]
        offset = chunk_end + 4

        if chunk_type == b"IHDR":
            if length < 13:
                return None
            width = int.from_bytes(chunk_data[0:4], "big")
            height = int.from_bytes(chunk_data[4:8], "big")
            bit_depth = chunk_data[8]
            color_type = chunk_data[9]
        elif chunk_type == b"IDAT":
            compressed.extend(chunk_data)
        elif chunk_type == b"IEND":
            break

    if width <= 0 or height <= 0 or bit_depth != 8 or color_type not in {2, 6}:
        return None

    try:
        raw = zlib.decompress(bytes(compressed))
    except zlib.error:
        return None

    bytes_per_pixel = 4 if color_type == 6 else 3
    stride = width * bytes_per_pixel
    expected = height * (stride + 1)
    if len(raw) < expected:
        return None

    pixels: list[tuple[int, int, int, int]] = []
    prev_row = [0] * stride
    raw_offset = 0
    for _ in range(height):
        filter_type = raw[raw_offset]
        raw_offset += 1
        scanline = list(raw[raw_offset : raw_offset + stride])
        raw_offset += stride
        recon = [0] * stride
        for i in range(stride):
            left = recon[i - bytes_per_pixel] if i >= bytes_per_pixel else 0
            up = prev_row[i]
            up_left = prev_row[i - bytes_per_pixel] if i >= bytes_per_pixel else 0
            if filter_type == 0:
                value = scanline[i]
            elif filter_type == 1:
                value = (scanline[i] + left) & 0xFF
            elif filter_type == 2:
                value = (scanline[i] + up) & 0xFF
            elif filter_type == 3:
                value = (scanline[i] + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                pa = abs(up - up_left)
                pb = abs(left - up_left)
                pc = abs(left + up - 2 * up_left)
                predictor = left if pa <= pb and pa <= pc else up if pb <= pc else up_left
                value = (scanline[i] + predictor) & 0xFF
            else:
                return None
            recon[i] = value
        prev_row = recon
        for pixel_index in range(0, stride, bytes_per_pixel):
            red = recon[pixel_index]
            green = recon[pixel_index + 1]
            blue = recon[pixel_index + 2]
            alpha = recon[pixel_index + 3] if bytes_per_pixel == 4 else 255
            pixels.append((red, green, blue, alpha))
    return width, height, pixels


def _orientation(width: int, height: int) -> str:
    if width <= 0 or height <= 0:
        return "未知方向"
    ratio = width / height
    if ratio > 1.15:
        return "横图"
    if ratio < 0.87:
        return "竖图"
    return "方图"


def _travel_composition_hint(orientation: str) -> tuple[str, str, str]:
    if orientation == "横图":
        return (
            "环境叙事",
            "适合交代城市街景、自然风光或路途中经过的开阔场面",
            "横向构图适合作为复盘里的路线高光或风景开场",
        )
    if orientation == "竖图":
        return (
            "打卡记录",
            "适合记录地标、人像、店铺门面或近距离旅行细节",
            "竖向构图适合作为社媒封面或当天最有记忆点的打卡图",
        )
    if orientation == "方图":
        return (
            "日记切片",
            "适合保留当下氛围、餐食、街角或旅途中的小发现",
            "方形构图适合进入旅行日记和复盘精选瞬间",
        )
    return (
        "旅行线索",
        "适合先作为旅拍候选保存，等补充地点后再生成更准确的文案",
        "可在复盘时补充地点、同行人和当时心情",
    )


def _preview_quality_label(byte_size: int, megapixels: float, width: int, height: int) -> str:
    if width <= 0 or height <= 0:
        return "待确认画面"
    if megapixels >= 2 or byte_size > 150_000:
        return "画面信息较完整"
    if byte_size > 20_000:
        return "预览信息可用"
    return "轻量预览"


def _clamp(value: float, lower: float, upper: float) -> float:
    return max(lower, min(upper, value))


def _photo_score(width: int, height: int, orientation: str, data: bytes) -> float:
    if width <= 0 or height <= 0:
        return 6.4

    megapixels = (width * height) / 1_000_000
    resolution_score = 6.3 + min(megapixels, 12.0) / 12.0 * 2.8

    orientation_score = 8.5 if orientation == "横图" else 8.2 if orientation == "竖图" else 7.9 if orientation == "方图" else 7.4

    rgba = _extract_png_rgba_pixels(data)
    if rgba is None:
        detail_score = 7.4 if megapixels >= 0.5 else 6.9
        lighting_score = 7.2
        color_score = 7.2
    else:
        _, _, pixels = rgba
        if not pixels:
            return round(_clamp((resolution_score + orientation_score) / 2, 6.4, 9.6), 1)

        step = max(1, len(pixels) // 4096)
        sampled = pixels[::step]
        luminances = [0.299 * r + 0.587 * g + 0.114 * b for r, g, b, _ in sampled]
        avg_luminance = sum(luminances) / len(luminances)
        lighting_penalty = min(abs(avg_luminance - 150.0) / 75.0, 1.0)
        lighting_score = 8.8 - lighting_penalty * 2.3

        colorfulness_values = []
        for r, g, b, _ in sampled:
            rg = abs(r - g)
            yb = abs((r + g) / 2 - b)
            colorfulness_values.append((rg + yb) / 2)
        avg_colorfulness = sum(colorfulness_values) / len(colorfulness_values)
        color_score = 6.8 + min(avg_colorfulness / 64.0, 1.0) * 2.0

        edge_total = 0.0
        edge_count = 0
        for y in range(height - 1):
            row_index = y * width
            next_row_index = (y + 1) * width
            x_step = max(1, width // 80)
            for x in range(0, width - 1, x_step):
                r1, g1, b1, _ = pixels[row_index + x]
                r2, g2, b2, _ = pixels[row_index + x + 1]
                r3, g3, b3, _ = pixels[next_row_index + x]
                lum1 = 0.299 * r1 + 0.587 * g1 + 0.114 * b1
                lum2 = 0.299 * r2 + 0.587 * g2 + 0.114 * b2
                lum3 = 0.299 * r3 + 0.587 * g3 + 0.114 * b3
                edge_total += abs(lum1 - lum2) + abs(lum1 - lum3)
                edge_count += 2
        edge_strength = edge_total / edge_count if edge_count else 0.0
        detail_score = 6.6 + min(edge_strength / 48.0, 1.0) * 2.4

    final_score = (
        resolution_score * 0.36
        + orientation_score * 0.12
        + detail_score * 0.22
        + lighting_score * 0.18
        + color_score * 0.12
    )
    return round(_clamp(final_score, 6.4, 9.6), 1)


def _vision_endpoint_config() -> tuple[str, str, str]:
    settings = get_settings()
    if settings.model_provider == "lanxin" and settings.lanxin_base_url and settings.lanxin_api_key:
        return settings.lanxin_base_url.rstrip("/") + "/chat/completions", settings.lanxin_api_key, settings.lanxin_model
    if settings.model_provider == "openai_compatible" and settings.openai_base_url and settings.openai_api_key:
        return settings.openai_base_url.rstrip("/") + "/chat/completions", settings.openai_api_key, settings.openai_model
    raise ModelProviderError("当前模型配置未启用可直接调用的视觉分析端点。")


def _normalize_scene_analysis(payload: dict[str, object]) -> dict[str, object]:
    tags = payload.get("tags")
    normalized_tags = []
    for item in tags if isinstance(tags, list) else []:
        text = str(item or "").strip()
        if text and text not in normalized_tags:
            normalized_tags.append(text)
    return {
        "location": str(payload.get("location") or "无法仅凭这张图确认具体地点").strip() or "无法仅凭这张图确认具体地点",
        "tags": normalized_tags[:5],
        "description": str(payload.get("description") or "").strip(),
        "reviewSuggestion": str(payload.get("reviewSuggestion") or "").strip(),
        "provider": str(payload.get("provider") or get_settings().model_provider),
        "fallback": bool(payload.get("fallback", False)),
    }


def _build_photo_scene_analysis(payload: PhotoAnalyzeRequest) -> dict[str, object]:
    url, api_key, model = _vision_endpoint_config()
    body = {
        "model": model,
        "messages": [
            {
                "role": "system",
                "content": (
                    "你是蓝心同行的旅拍图片分析助手。只根据图片中真正可见的内容做中文分析，不要编造具体地点。"
                    "如果无法确认城市或景点，请明确说无法仅凭画面确认。"
                    '返回一个 JSON 对象：{"location":"...","tags":["..."],"description":"...","reviewSuggestion":"..."}。'
                ),
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": (
                            f"请分析这张旅行照片。来源：{payload.source}；文件名：{payload.filename}。"
                            "重点说明画面主体、旅行场景、适合的旅行叙事，不要输出技术参数。"
                        ),
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:{payload.contentType};base64,{payload.imageBase64}",
                        },
                    },
                ],
            },
        ],
        "response_format": {"type": "json_object"},
        "temperature": 0.2,
    }
    headers = {"Authorization": f"Bearer {api_key}"}
    with httpx.Client(timeout=get_settings().model_timeout_seconds) as client:
        response = client.post(url, headers=headers, json=body)
        response.raise_for_status()
    data = response.json()
    content = data["choices"][0]["message"]["content"]
    parsed = json.loads(content)
    if not isinstance(parsed, dict):
        raise TypeError("视觉模型返回结果不是 JSON 对象。")
    return _normalize_scene_analysis(parsed | {"provider": get_settings().model_provider, "fallback": False})


def _analyze_image_bytes(payload: PhotoAnalyzeRequest) -> dict[str, object]:
    try:
        data = base64.b64decode(payload.imageBase64, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ValueError("imageBase64 不是有效图片预览数据") from exc
    width, height = _image_dimensions(data)
    orientation = _orientation(width, height)
    megapixels = (width * height / 1_000_000) if width and height else 0
    byte_size = len(data)
    scene_label, scene_description, review_hint = _travel_composition_hint(orientation)
    quality_label = _preview_quality_label(byte_size, megapixels, width, height)
    source_label = "相机现场拍摄" if payload.source == "camera" else "相册导入"
    tags = ["真实旅拍", "旅行场景", scene_label, source_label]
    try:
        scene_analysis = _build_photo_scene_analysis(payload)
    except (ModelProviderError, httpx.HTTPError, KeyError, IndexError, TypeError, json.JSONDecodeError):
        scene_analysis = None
    if payload.source == "camera":
        location = "现场旅行画面"
    else:
        location = "相册旅行画面"
    if quality_label != "待确认画面":
        tags.append(quality_label)
    score = _photo_score(width, height, orientation, data)
    if scene_analysis:
        merged_tags = []
        for item in [*tags, *scene_analysis.get("tags", [])]:
            text = str(item or "").strip()
            if text and text not in merged_tags:
                merged_tags.append(text)
        return {
            "width": width,
            "height": height,
            "orientation": orientation,
            "location": scene_analysis.get("location") or location,
            "score": score,
            "tags": merged_tags[:6],
            "description": scene_analysis.get("description") or f"这张照片适合表现{scene_description}。",
            "reviewSuggestion": scene_analysis.get("reviewSuggestion") or review_hint,
            "canAddToReview": True,
            "provider": scene_analysis.get("provider") or get_settings().model_provider,
            "fallback": bool(scene_analysis.get("fallback", False)),
        }
    return {
        "width": width,
        "height": height,
        "orientation": orientation,
        "location": location,
        "score": score,
        "tags": tags,
        "description": f"这张旅拍画面呈现出{scene_description}，适合放进旅行记录里承担环境交代和情绪铺垫的作用。",
        "reviewSuggestion": f"{review_hint}；复盘时可以围绕这张图写下当时的停留原因、同行互动或现场心情。",
        "canAddToReview": True,
        "provider": "local_image_features",
        "fallback": False,
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


def _ensure_real_provider_copy_labels(result: dict[str, object], provider_name: str) -> None:
    if provider_name not in {"openai_compatible", "lanxin"}:
        return
    labels = {
        "moments": "朋友圈",
        "xiaohongshu": "小红书",
        "diary": "旅行日记",
        "vlogNarration": "Vlog 旁白",
    }
    for key, label in labels.items():
        value = result.get(key)
        if isinstance(value, str) and value.strip() and label not in value:
            result[key] = f"{label}：{value.strip()}"


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
    _ensure_real_provider_copy_labels(result, provider.name)
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
    location_label = _safe_photo_location_label(session, effective_user_id, payload.tripId, candidate_id, payload.location)
    item = session.get(PhotoCandidateRecord, candidate_id)
    if item:
        item.user_id = effective_user_id
        item.trip_id = payload.tripId
        item.local_uri = None
        item.remote_url = payload.remoteUrl
        item.location_label = location_label
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
            location_label=location_label,
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


@router.post("/analyze")
def analyze_photo_preview(
    payload: PhotoAnalyzeRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> dict[str, object]:
    resolve_effective_user_id(payload.userId, current_user)
    try:
        return _analyze_image_bytes(payload)
    except ValueError as exc:
        return {
            "width": 0,
            "height": 0,
            "orientation": "未知方向",
            "location": "待确认照片",
            "score": 6.5,
            "tags": ["真实图片分析失败", "可重试"],
            "description": "图片预览数据暂时无法解析，请重新拍摄或重新选择后再试。",
            "reviewSuggestion": "分析失败时先不要加入复盘高光，可重试获取真实图片特征。",
            "canAddToReview": False,
            "provider": "local_image_features",
            "fallback": True,
            "errorType": "invalid_image_preview",
            "fallbackReason": str(exc),
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
