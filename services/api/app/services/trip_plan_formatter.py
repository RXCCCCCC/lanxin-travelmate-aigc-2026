import re
from typing import Any


_CN_VALUE_MAP = {
    "medium": "中等预算",
    "low": "低预算",
    "high": "高预算",
    "transit": "公共交通",
    "walking": "步行",
    "taxi": "打车",
    "self_drive": "自驾",
    "slow pace": "慢节奏",
    "relaxed pace": "轻松节奏",
    "balanced_slow": "偏慢的均衡节奏",
    "low_first": "优先控制预算",
    "night view": "夜景",
    "night views": "夜景",
    "less walking": "少走路",
    "indoor": "室内活动",
    "weather_risk": "天气风险",
    "mother": "妈妈",
    "child": "孩子",
    "family_relaxed": "家庭轻松游",
    "affection": "好感度",
    "rapport": "默契值",
}

_GENERIC_BEST_FOR = {
    "适合在原计划拥挤，天气变化或体力不足时切换",
    "适合在原计划拥挤、天气变化或体力不足时切换",
    "适合在原计划拥挤，天气变化或体力不足时切换。",
    "适合在原计划拥挤、天气变化或体力不足时切换。",
}


def cn_value(value: object) -> str:
    text = str(value)
    return _CN_VALUE_MAP.get(text, text)


def _looks_like_date_fragment(text: str) -> bool:
    candidate = text.strip()
    if not candidate:
        return False
    if re.fullmatch(r"[0-9]{1,2}号", candidate):
        return True
    if re.fullmatch(r"[一二三四五六七八九十两]{1,3}号", candidate):
        return True
    if re.fullmatch(r"(?:[一二三四五六七八九十]|十[一二三四五六七八九]?|[0-9]{1,2})月", candidate):
        return True
    return False


def _strip_planning_instruction_noise(text: str) -> str:
    cleaned = text.strip()
    cleaned = re.sub(r"^(?:帮我|请|麻烦你|给我|能不能|可以)?(?:规划|安排|定制|做|生成)", "", cleaned)
    cleaned = re.sub(r"(?:行程|路线|旅游|旅行|游玩|攻略)$", "", cleaned)
    cleaned = re.sub(r"(?:一|两|二|三|四|五|六|七|八|九|十|[0-9]{1,2})天.*$", "", cleaned)
    cleaned = re.sub(r"(?:[一二三四五六七八九十两0-9]{1,3})号.*$", "", cleaned)
    return cleaned.strip(" ，。,.!！？?：:")


def extract_destination_from_message(message: str) -> str | None:
    text = message.strip()
    if not text:
        return None
    explicit_patterns = [
        "^([\\u4e00-\\u9fffA-Za-z]{2,20})(?:行程|路线|旅行|旅游|攻略|周末游|轻松游|慢游|citywalk)",
        "目的地(?:是|为|:|：)?\\s*([\\u4e00-\\u9fffA-Za-z]{2,20})",
        "(?:规划|安排|定制)\\s*([\\u4e00-\\u9fffA-Za-z]{2,20}?)(?:行程|路线|旅游|旅行|游玩|攻略|一天|两天|三天|四天|五天|周末|，|。|,|\\.|!|！|\\?|？|\\s|$)",
        "为\\s*([\\u4e00-\\u9fffA-Za-z]{2,20}?)(?:规划|安排|定制)",
        "(?:去|到)\\s*([\\u4e00-\\u9fffA-Za-z]{2,20}?)(?:两天|三天|四天|五天|一天|一周|周末|旅游|旅行|玩|逛|出差|，|。|,|\\.|!|！|\\?|？|\\s|$)",
    ]
    for pattern in explicit_patterns:
        match = re.search(pattern, text)
        if match:
            destination = _strip_planning_instruction_noise(match.group(1))
            if len(destination) >= 2 and not _looks_like_date_fragment(destination):
                return destination
    return None


def _looks_internal(text: str) -> bool:
    normalized = text.lower()
    return (
        "真实模型" in text
        or "模型返回" in text
        or "路线规划工具" in text
        or "缺少坐标" in text
        or "坐标信息" in text
        or "手动规划" in text
        or "虚手动" in text
        or "天气接口" in text
        or "poi数据存在偏差" in normalized
        or "返回北京点位" in text
        or "fallback model" in normalized
        or "model fallback" in normalized
        or "route_tool" in normalized
        or "model_provider" in normalized
        or "provider=" in normalized
    )


def _localize_text(value: object, fallback: str) -> str:
    text = str(value or "").strip()
    if not text:
        return fallback
    for source, target in sorted(_CN_VALUE_MAP.items(), key=lambda item: len(item[0]), reverse=True):
        text = text.replace(source, target)
    english_letters = sum(1 for char in text if ("a" <= char.lower() <= "z"))
    chinese_chars = sum(1 for char in text if "\u4e00" <= char <= "\u9fff")
    if english_letters and not chinese_chars:
        return fallback
    return text


def _localize_product_text(value: object, fallback: str) -> str:
    text = _localize_text(value, fallback)
    return fallback if _looks_internal(text) else text


def _localize_risk_text(value: object, fallback: str, destination: str) -> str:
    text = _localize_text(value, fallback)
    normalized = text.lower()
    if "天气接口" in text:
        city = destination or "当地"
        return f"{city}当天的天气变化可能影响户外安排，建议出发前再确认一次天气并准备室内备选。"
    if "poi数据存在偏差" in normalized or "返回北京点位" in text:
        city = destination or "目的地"
        return f"{city}个别热门点位的名称或定位可能有偏差，出发前可再核对一次地图和营业信息。"
    if _looks_internal(text):
        return "点位间的详细步行和换乘路线建议出发前在地图 App 再确认一次，避免现场绕路。"
    return text


def _has_displayable_days(value: object) -> bool:
    if not isinstance(value, list):
        return False
    for day in value:
        if not isinstance(day, dict):
            continue
        items = day.get("items")
        if isinstance(items, list) and any(isinstance(item, dict) for item in items):
            return True
    return False


def _digest_items_from_summary(summary: str, destination: str) -> list[dict[str, str]]:
    fragments = [
        fragment.strip(" ，。,.!！？?；;")
        for fragment in re.split(r"[，。,.!！？?；;]+", summary)
        if fragment.strip(" ，。,.!！？?；;")
    ]
    fallback_times = ["上午", "下午", "晚上", "机动"]
    items: list[dict[str, str]] = []
    for index, fragment in enumerate(fragments[:4]):
        time_match = re.match(r"^(上午|中午|下午|傍晚|晚上|夜间|早上|清晨|午后|全天)", fragment)
        time = time_match.group(1) if time_match else fallback_times[min(index, len(fallback_times) - 1)]
        location = re.sub(
            r"^(上午|中午|下午|傍晚|晚上|夜间|早上|清晨|午后|全天)?(?:逛|去|到|看|游览|打卡|体验|安排|前往)?",
            "",
            fragment,
        ).strip(" ，。,.!！？?；;")
        items.append(
            {
                "time": time,
                "location": location or destination,
                "activity": fragment,
            }
        )
    return items


def _add_digest_days_if_missing(plan: dict[str, Any], destination: str) -> None:
    if _has_displayable_days(plan.get("days")):
        return
    summary = str(plan.get("summary") or "").strip()
    if not summary:
        return
    items = _digest_items_from_summary(summary, destination)
    if not items:
        return
    plan["days"] = [
        {
            "dayLabel": "核心安排",
            "items": items,
        }
    ]


def _resolve_destination(
    plan: dict[str, Any],
    planning_inputs: dict[str, Any] | None,
    requested_destination: str | None,
    message: str | None,
) -> str:
    for candidate in (
        requested_destination,
        planning_inputs.get("destination") if isinstance(planning_inputs, dict) else None,
        extract_destination_from_message(message or ""),
        plan.get("destination"),
    ):
        text = str(candidate or "").strip()
        if text and text != "待确认目的地":
            return text
    return "这次旅行"


def sanitize_trip_plan_for_client(
    plan: dict[str, Any],
    *,
    planning_inputs: dict[str, Any] | None = None,
    requested_destination: str | None = None,
    message: str | None = None,
) -> dict[str, Any]:
    localized = dict(plan)
    destination = _resolve_destination(localized, planning_inputs, requested_destination, message)
    original_destination = str(localized.get("destination") or "").strip()
    localized["destination"] = destination
    for key in ("title", "summary"):
        value = localized.get(key)
        if isinstance(value, str):
            updated = value.replace("待确认目的地", destination)
            if original_destination and original_destination != destination:
                updated = updated.replace(original_destination, destination)
            localized[key] = updated
    localized["title"] = _localize_product_text(localized.get("title"), f"{destination}行程建议")
    localized["summary"] = _localize_product_text(
        localized.get("summary"),
        f"我先按{destination}整理了一版更稳妥的路线，方便你继续细化预算、节奏和想去的点。",
    )
    localized["profileMatches"] = [
        _localize_text(item, f"已根据你的旅行画像调整安排{index + 1}。")
        for index, item in enumerate(localized.get("profileMatches") or [])
    ]
    localized["risks"] = [
        _localize_risk_text(item, f"已识别一项需要留意的行程风险{index + 1}。", destination)
        for index, item in enumerate(localized.get("risks") or [])
    ]
    dynamic_adjustment = localized.get("dynamicAdjustment")
    if isinstance(dynamic_adjustment, dict):
        trigger = _localize_product_text(dynamic_adjustment.get("trigger"), f"{destination}实时拥挤或天气变化")
        suggestion = _localize_product_text(
            dynamic_adjustment.get("suggestion"),
            "已准备更稳妥的路线调整，建议现场结合天气、排队情况和体力灵活切换。",
        )
        localized["dynamicAdjustment"] = {
            **dynamic_adjustment,
            "trigger": trigger.replace("待确认目的地", destination),
            "suggestion": suggestion,
        }
    alternatives = []
    for item in localized.get("alternatives") or []:
        if not isinstance(item, dict):
            continue
        best_for = _localize_product_text(item.get("bestFor"), "")
        if best_for in _GENERIC_BEST_FOR:
            best_for = ""
        alternatives.append(
            {
                **item,
                "title": _localize_product_text(item.get("title"), "备选方案"),
                "summary": _localize_product_text(item.get("summary"), "这条备选适合在天气、拥挤度或体力变化时切换。"),
                "reason": _localize_product_text(item.get("reason"), ""),
                "bestFor": best_for,
            }
        )
    localized["alternatives"] = alternatives
    _add_digest_days_if_missing(localized, destination)
    localized.pop("toolTrace", None)
    localized.pop("externalContext", None)
    return localized
