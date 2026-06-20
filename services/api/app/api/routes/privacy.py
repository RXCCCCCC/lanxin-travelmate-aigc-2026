from typing import Any

from fastapi import APIRouter


router = APIRouter(prefix="/privacy", tags=["privacy"])


@router.get("/summary")
def privacy_summary() -> dict[str, Any]:
    return {
        "version": "2026-06-19",
        "principles": [
            "记忆保存前必须由用户确认范围。",
            "Mock 或降级数据不得伪装成真实外部数据。",
            "云端请求只发送完成当前任务所需的最少信息。",
        ],
        "permissions": [
            {
                "permission": "location",
                "label": "定位",
                "purpose": "用于当前位置路线、附近提醒和天气风险判断。",
                "required": False,
                "fallback": "用户拒绝时使用手动城市或地点输入。",
            },
            {
                "permission": "photos",
                "label": "照片选择",
                "purpose": "仅在用户主动选择照片后加入旅拍候选集和复盘。",
                "required": False,
                "fallback": "不授权时可继续使用聊天、规划和文字复盘。",
            },
            {
                "permission": "camera",
                "label": "相机",
                "purpose": "用于应用内拍照并由用户确认是否加入候选集。",
                "required": False,
                "fallback": "不授权时可改用系统照片选择器或跳过旅拍。",
            },
            {
                "permission": "microphone",
                "label": "麦克风",
                "purpose": "用于语音输入；真实 ASR 未配置时回退文字输入。",
                "required": False,
                "fallback": "关闭后保留文字聊天。",
            },
            {
                "permission": "notifications",
                "label": "通知",
                "purpose": "用于饭点、行程节点、天气变化等主动提醒。",
                "required": False,
                "fallback": "关闭后只在应用内展示提醒。",
            },
        ],
        "memoryRules": [
            {
                "scope": "longTerm",
                "label": "长期记忆",
                "description": "跨旅行复用，例如稳定兴趣或饮食偏好；保存前必须确认。",
            },
            {
                "scope": "currentTrip",
                "label": "本次旅行",
                "description": "仅影响当前行程，例如临时体力、同行人、酒店附近路线。",
            },
            {
                "scope": "temporary",
                "label": "当前会话",
                "description": "只在本次对话中使用，不写入长期画像。",
            },
            {
                "scope": "ignore",
                "label": "不记忆",
                "description": "用户可拒绝保存，Agent 只完成当前回复。",
            },
        ],
        "sensitivityLevels": [
            {
                "level": "normal",
                "label": "普通偏好",
                "examples": ["喜欢夜景", "慢节奏旅行"],
                "defaultScopes": ["longTerm", "currentTrip", "temporary", "ignore"],
            },
            {
                "level": "personal",
                "label": "个人偏好",
                "examples": ["不吃香菜", "饮食忌口"],
                "defaultScopes": ["longTerm", "currentTrip", "temporary", "ignore"],
                "requiresExplicitConsent": True,
            },
            {
                "level": "sensitive",
                "label": "敏感信息",
                "examples": ["身体状态", "住址/酒店附近", "同行人信息"],
                "defaultScopes": ["currentTrip", "temporary", "ignore"],
                "requiresExplicitConsent": True,
            },
        ],
        "userControls": {
            "canExportData": True,
            "canDeleteAllMemories": True,
            "canClearCurrentTrip": True,
            "canDisableSync": True,
            "canUseGuestMode": True,
        },
    }