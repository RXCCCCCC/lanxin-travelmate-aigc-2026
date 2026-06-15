from fastapi import APIRouter
from pydantic import BaseModel, Field


router = APIRouter(prefix="/photo", tags=["photo"])


class CopywritingRequest(BaseModel):
    photoIds: list[str] = Field(default_factory=list)
    persona: str = "活泼向导"
    style: str = "轻松"


@router.get("/candidates")
def photo_candidates_placeholder() -> dict[str, list[dict[str, object]]]:
    return {
        "items": [
            {
                "id": "photo-night",
                "location": "洪崖洞",
                "score": 9.3,
                "description": "夜景灯光层次明显，适合做今日高光。",
                "tags": ["夜景", "山城", "高光照片"],
                "canAddToReview": True,
            },
            {
                "id": "photo-street",
                "location": "山城步道",
                "score": 8.8,
                "description": "街巷纵深感强，适合做慢节奏旅行日记封面。",
                "tags": ["街巷", "步道", "慢旅行"],
                "canAddToReview": True,
            },
        ]
    }


@router.post("/copywriting")
def create_photo_copywriting(payload: CopywritingRequest) -> dict[str, object]:
    persona_hint = f"蓝小心以{payload.persona}语气"
    return {
        "photoIds": payload.photoIds or ["photo-night"],
        "persona": payload.persona,
        "style": payload.style,
        "moments": f"朋友圈文案：重庆的夜色刚刚好，慢慢走、慢慢看，今天被山城温柔接住了。{persona_hint}提醒你记得休息。",
        "xiaohongshu": "小红书文案：重庆两天一夜轻松夜景线｜不赶路也能收获洪崖洞高光机位。",
        "diary": "旅行日记：今天从解放碑慢慢走到洪崖洞，夜景、江风和不用赶场的节奏都刚刚好。",
        "vlogNarration": "Vlog 旁白：这一站，我们把重庆留给傍晚。灯亮起来的时候，蓝小心说，这就是今天的高光。",
        "reviewSuggestion": "建议加入今日复盘的高光照片区。",
    }
