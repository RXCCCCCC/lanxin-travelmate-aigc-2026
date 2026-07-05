import json
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlmodel import Session, select

from app.agents.travelmate.graph import TravelMateGraph
from app.core.security import CurrentUser, get_current_user, resolve_effective_user_id
from app.agents.travelmate.state import create_initial_state
from app.db.models import AvatarStateEventRecord, BlindBoxTaskRecord, CloudMemory, CloudTrip, CloudTripReview, GroupCoordinationRecord, PhotoCandidateRecord, ReminderEvent, TripRoutePointRecord, utc_now
from app.db.session import get_session
from app.services.model_audit import persist_model_call_logs


router = APIRouter(prefix="/trip", tags=["trip"])


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
}


def _cn_value(value: object) -> str:
    text = str(value)
    return _CN_VALUE_MAP.get(text, text)


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


def _localize_risk_text(value: object, fallback: str) -> str:
    text = _localize_text(value, fallback)
    normalized = text.lower()
    if (
        "路线规划工具" in text
        or "缺少坐标" in text
        or "坐标信息" in text
        or "手动规划" in text
        or "虚手动" in text
        or ("tool" in normalized and ("route" in normalized or "planning" in normalized))
    ):
        return "点位间的详细步行和换乘路线建议出发前在地图 App 再确认一次，避免现场绕路。"
    return text


def _localize_product_text(value: object, fallback: str) -> str:
    text = _localize_text(value, fallback)
    normalized = text.lower()
    if (
        "真实模型" in text
        or "模型返回" in text
        or "路线规划工具" in text
        or "缺少坐标" in text
        or "手动规划" in text
        or "fallback model" in normalized
        or "model fallback" in normalized
        or "route_tool" in normalized
        or "model_provider" in normalized
        or "provider=" in normalized
    ):
        return fallback
    return text


def _localize_list(values: object, fallback: str) -> list[str]:
    result = []
    for index, item in enumerate(values or []):
        result.append(_localize_text(item, f"{fallback}{index + 1}。"))
    return result


def _localize_risk_list(values: object, fallback: str) -> list[str]:
    result = []
    for index, item in enumerate(values or []):
        result.append(_localize_risk_text(item, f"{fallback}{index + 1}。"))
    return result


def _localize_trip_plan_text(plan: dict[str, object]) -> None:
    plan["profileMatches"] = _localize_list(plan.get("profileMatches"), "已根据你的旅行画像调整安排")
    plan["risks"] = _localize_risk_list(plan.get("risks"), "已识别一项需要留意的行程风险")
    alternatives = []
    for item in plan.get("alternatives") or []:
        if not isinstance(item, dict):
            alternatives.append(item)
            continue
        localized = dict(item)
        if "summary" in localized:
            localized["summary"] = _localize_product_text(
                localized.get("summary"),
                "这条备选适合在天气、拥挤度或体力变化时切换。",
            )
        if "reason" in localized:
            localized["reason"] = _localize_product_text(
                localized.get("reason"),
                "这条备选用于应对节奏、天气或交通变化。",
            )
        if "bestFor" in localized:
            localized["bestFor"] = _localize_product_text(
                localized.get("bestFor"),
                "适合在原计划拥挤、天气变化或体力不足时切换。",
            )
        alternatives.append(localized)
    plan["alternatives"] = alternatives


class TripPlanRequest(BaseModel):
    message: str
    userId: str = "guest"
    tripId: str | None = None
    destination: str | None = None
    originCoordinate: dict[str, float] = Field(default_factory=dict)
    destinationCoordinate: dict[str, float] = Field(default_factory=dict)
    startDate: str | None = None
    endDate: str | None = None
    budget: str | None = None
    companions: list[str] = Field(default_factory=list)
    preferences: list[str] = Field(default_factory=list)
    transportMode: str | None = None
    tripStyle: str | None = None
    replanReason: str | None = None
    groupCoordination: dict[str, object] = Field(default_factory=dict)


class TripReviewRequest(BaseModel):
    message: str = "生成今天旅行复盘"
    userId: str = "guest"
    tripId: str | None = None
    completedTasks: list[dict[str, object]] = Field(default_factory=list)
    temporaryMemories: list[dict[str, object]] = Field(default_factory=list)
    profileContext: dict[str, object] = Field(default_factory=dict)


class ReminderTriggerRequest(BaseModel):
    userId: str = "guest"
    tripId: str | None = None
    triggerType: str
    location: str | None = None
    eventPayload: dict[str, object] = Field(default_factory=dict)


class ReminderEvaluateRequest(BaseModel):
    userId: str = "guest"
    tripId: str | None = None
    proactivityLevel: str = "standard"
    currentTime: str | None = None
    location: str | None = None
    status: dict[str, object] = Field(default_factory=dict)
    external: dict[str, object] = Field(default_factory=dict)


class TripRoutePointPayload(BaseModel):
    label: str
    latitude: float
    longitude: float
    source: str = "device"
    recordedAt: str | None = None


class TripRoutePointsRequest(BaseModel):
    userId: str = "guest"
    tripId: str
    points: list[TripRoutePointPayload] = Field(min_length=1)


class AvatarStateEventRequest(BaseModel):
    userId: str = "guest"
    tripId: str
    eventType: str
    title: str
    deltas: dict[str, int | float] = Field(default_factory=dict)
    reason: str = ""

class GroupMemberPayload(BaseModel):
    memberId: str
    displayName: str
    preferences: dict[str, object] = Field(default_factory=dict)
    sensitivePreferences: dict[str, object] = Field(default_factory=dict)


class GroupCoordinationRequest(BaseModel):
    userId: str = "guest"
    tripId: str
    destination: str | None = None
    members: list[GroupMemberPayload] = Field(min_length=2)


class BlindBoxTaskStatusRequest(BaseModel):
    userId: str = "guest"
    tripId: str
    status: str
    note: str | None = None


def _trip_response(trip: CloudTrip) -> dict[str, object]:
    return {
        "tripId": trip.id,
        "userId": trip.user_id,
        "destination": trip.destination,
        "destinationType": trip.destination_type,
        "status": trip.status,
        "startDate": trip.start_date,
        "endDate": trip.end_date,
        "budget": trip.budget,
        "companions": json.loads(trip.companions_json),
        "tripStyle": trip.trip_style,
        "plan": json.loads(trip.plan_json),
        "createdAt": trip.created_at.isoformat(),
        "updatedAt": trip.updated_at.isoformat(),
    }


def _review_response(record: CloudTripReview) -> dict[str, object]:
    return {
        "reviewId": record.id,
        "tripId": record.trip_id,
        "review": json.loads(record.review_json),
        "createdAt": record.created_at.isoformat(),
    }


def _memory_response(memory: CloudMemory) -> dict[str, object]:
    return {
        'id': memory.id,
        'userId': memory.user_id,
        'title': memory.title,
        'content': memory.content,
        'scope': memory.scope,
        'category': memory.category,
        'status': memory.status,
        'sourceText': memory.source_text,
        'confidence': memory.confidence,
        'createdAt': memory.created_at.isoformat(),
        'updatedAt': memory.updated_at.isoformat(),
    }


def _photo_candidate_response(record: PhotoCandidateRecord) -> dict[str, object]:
    return {
        'id': record.id,
        'userId': record.user_id,
        'tripId': record.trip_id,
        'localUri': None,
        'remoteUrl': record.remote_url,
        'location': record.location_label,
        'score': record.share_score,
        'description': record.description,
        'tags': json.loads(record.content_tags_json),
        'canAddToReview': record.can_add_to_review,
        'copywriting': json.loads(record.copywriting_json),
        'createdAt': record.created_at.isoformat(),
        'updatedAt': record.updated_at.isoformat(),
    }


def _reminder_response(record: ReminderEvent) -> dict[str, object]:
    return {
        "historyId": record.id,
        "userId": record.user_id,
        "tripId": record.trip_id,
        "triggerType": record.trigger_type,
        "location": record.location,
        "eventPayload": json.loads(record.event_payload_json),
        "items": json.loads(record.reminders_json),
        "createdAt": record.created_at.isoformat(),
    }

def _member_public_view(member: GroupMemberPayload) -> dict[str, object]:
    preferences = dict(member.preferences)
    return {
        "memberId": member.memberId,
        "displayName": member.displayName,
        "preferences": preferences,
        "hasSensitivePreferences": bool(member.sensitivePreferences),
    }


def _as_list(value: object) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value if str(item)]
    if value is None or value == "":
        return []
    return [str(value)]


def _detect_group_conflicts(members: list[GroupMemberPayload]) -> list[dict[str, object]]:
    paces = {str(member.preferences.get("pace")) for member in members if member.preferences.get("pace")}
    budgets = {str(member.preferences.get("budget")) for member in members if member.preferences.get("budget")}
    dietary_sets = [set(_as_list(member.preferences.get("dietary"))) for member in members]
    conflicts: list[dict[str, object]] = []
    if len(paces) > 1:
        conflicts.append({
            "type": "pace",
            "title": "节奏偏好不一致",
            "summary": "同行成员对行程强度的期待不同，建议按较慢节奏安排主线，并保留可选加餐点。",
            "values": sorted(paces),
        })
    if len(budgets) > 1:
        conflicts.append({
            "type": "budget",
            "title": "预算偏好不一致",
            "summary": "预算期待存在差异，建议主方案控制在较低预算，体验型项目作为可选项。",
            "values": sorted(budgets),
        })
    dietary_union = sorted(set().union(*dietary_sets)) if dietary_sets else []
    if len(dietary_union) > 1:
        conflicts.append({
            "type": "dietary",
            "title": "饮食偏好需要兼容",
            "summary": "点餐和餐厅选择需要同时照顾忌口与想尝试的食物。",
            "values": dietary_union,
        })
    return conflicts


def _build_compromise_plan(destination: str | None, members: list[GroupMemberPayload]) -> dict[str, object]:
    paces = {str(member.preferences.get("pace")) for member in members if member.preferences.get("pace")}
    budgets = {str(member.preferences.get("budget")) for member in members if member.preferences.get("budget")}
    shared_interests = None
    for member in members:
        interests = set(_as_list(member.preferences.get("interests")))
        shared_interests = interests if shared_interests is None else shared_interests & interests
    all_interests = sorted({interest for member in members for interest in _as_list(member.preferences.get("interests"))})
    dietary_notes = sorted({note for member in members for note in _as_list(member.preferences.get("dietary"))})
    return {
        "destination": destination,
        "pace": "balanced_slow" if "slow" in paces and len(paces) > 1 else (sorted(paces)[0] if paces else "balanced"),
        "budget": "low_first" if "low" in budgets else (sorted(budgets)[0] if budgets else "balanced"),
        "sharedInterests": sorted(shared_interests or []) or all_interests[:3],
        "optionalInterests": [interest for interest in all_interests if interest not in (shared_interests or set())],
        "dietaryStrategy": "提前备注餐厅和菜品忌口" if dietary_notes else "无特殊饮食冲突",
        "routeStrategy": "主线按低强度串联，体力好的成员增加附近可选点。",
    }


def _privacy_summary(members: list[GroupMemberPayload]) -> dict[str, object]:
    sensitive_count = sum(1 for member in members if member.sensitivePreferences)
    return {
        "sensitiveMemberDetailsHidden": sensitive_count > 0,
        "sensitiveMemberCount": sensitive_count,
        "publicRule": "多人模式默认只展示汇总后的协调依据，不暴露个人敏感偏好原文。",
    }


def _group_coordination_response(record: GroupCoordinationRecord) -> dict[str, object]:
    return {
        "coordinationId": record.id,
        "userId": record.user_id,
        "tripId": record.trip_id,
        "destination": record.destination,
        "members": json.loads(record.members_json),
        "conflicts": json.loads(record.conflicts_json),
        "compromisePlan": json.loads(record.compromise_plan_json),
        "privacySummary": json.loads(record.privacy_summary_json),
        "createdAt": record.created_at.isoformat(),
        "updatedAt": record.updated_at.isoformat(),
    }


@router.get("/current")
def read_current_trip(
    userId: str | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    trip = session.exec(
        select(CloudTrip).where(CloudTrip.user_id == effective_user_id).order_by(CloudTrip.updated_at.desc())
    ).first()
    if not trip:
        return {"tripId": None, "userId": effective_user_id, "status": "empty", "plan": {}}
    return _trip_response(trip)

@router.get('/dashboard')
def read_trip_dashboard(
    userId: str | None = Query(default=None),
    tripId: str | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    trip = None
    if tripId:
        candidate = session.get(CloudTrip, tripId)
        if candidate and candidate.user_id == effective_user_id:
            trip = candidate
    if trip is None:
        trip = session.exec(
            select(CloudTrip).where(CloudTrip.user_id == effective_user_id).order_by(CloudTrip.updated_at.desc())
        ).first()

    resolved_trip_id = trip.id if trip else tripId
    current_trip: dict[str, object] = _trip_response(trip) if trip else {
        'tripId': resolved_trip_id,
        'userId': effective_user_id,
        'status': 'empty',
        'plan': {},
    }
    route_points = _route_points_payload(_stored_route_points(session, effective_user_id, resolved_trip_id)) if resolved_trip_id else {'points': [], 'route': ''}

    reminder_statement = select(ReminderEvent).where(ReminderEvent.user_id == effective_user_id)
    if resolved_trip_id:
        reminder_statement = reminder_statement.where(ReminderEvent.trip_id == resolved_trip_id)
    reminders = session.exec(reminder_statement.order_by(ReminderEvent.created_at.desc())).all()

    reviews = session.exec(
        select(CloudTripReview)
        .where(CloudTripReview.user_id == effective_user_id)
        .where(CloudTripReview.trip_id == resolved_trip_id)
        .order_by(CloudTripReview.created_at.desc())
    ).all() if resolved_trip_id else []
    photos = session.exec(
        select(PhotoCandidateRecord)
        .where(PhotoCandidateRecord.user_id == effective_user_id)
        .where(PhotoCandidateRecord.trip_id == resolved_trip_id)
        .order_by(PhotoCandidateRecord.updated_at.desc())
    ).all() if resolved_trip_id else []
    memories = session.exec(
        select(CloudMemory)
        .where(CloudMemory.user_id == effective_user_id)
        .where(CloudMemory.source_text == resolved_trip_id)
        .order_by(CloudMemory.updated_at.desc())
    ).all() if resolved_trip_id else []

    task_records_by_id: dict[str, BlindBoxTaskRecord] = {}
    if resolved_trip_id:
        task_records = session.exec(
            select(BlindBoxTaskRecord)
            .where(BlindBoxTaskRecord.user_id == effective_user_id)
            .where(BlindBoxTaskRecord.trip_id == resolved_trip_id)
            .order_by(BlindBoxTaskRecord.updated_at.desc())
        ).all()
        task_records_by_id = {record.task_id: record for record in task_records}
    blind_box_tasks: list[dict[str, object]] = []
    for task in BLIND_BOX_TASKS:
        item = dict(task)
        record = task_records_by_id.get(str(task['id']))
        item.update({
            'status': record.status if record else 'available',
            'note': record.note if record else None,
            'rewardApplied': record.reward_applied if record else False,
            'acceptedAt': record.accepted_at.isoformat() if record and record.accepted_at else None,
            'completedAt': record.completed_at.isoformat() if record and record.completed_at else None,
        })
        blind_box_tasks.append(item)

    avatar_events = _stored_avatar_state_events(session, effective_user_id, resolved_trip_id) if resolved_trip_id else []
    return {
        'userId': effective_user_id,
        'tripId': resolved_trip_id,
        'currentTrip': current_trip,
        'routePoints': route_points,
        'reminderHistory': {'items': [_reminder_response(record) for record in reminders]},
        'blindBoxTasks': {'items': blind_box_tasks},
        'avatarStateEvents': {'items': [_avatar_state_event_response(record) for record in avatar_events]},
        'latestReview': _review_response(reviews[0]) if reviews else {'reviewId': None, 'tripId': resolved_trip_id, 'review': {}},
        'photoCandidates': {'items': [_photo_candidate_response(record) for record in photos]},
        'memories': {'items': [_memory_response(memory) for memory in memories]},
    }

def _apply_planning_input_explanations(plan: dict[str, object], planning_inputs: dict[str, object]) -> None:
    profile_matches = list(plan.get("profileMatches") or [])
    risks = list(plan.get("risks") or [])
    budget = planning_inputs.get("budget")
    transport_mode = planning_inputs.get("transportMode")
    companions = planning_inputs.get("companions") or []
    preferences = planning_inputs.get("preferences") or []
    replan_reason = planning_inputs.get("replanReason")
    group_coordination = planning_inputs.get("groupCoordination")
    if budget:
        profile_matches.append(f"已参考预算偏好：{_cn_value(budget)}。")
    if transport_mode:
        profile_matches.append(f"已参考交通方式：{_cn_value(transport_mode)}。")
    if companions:
        profile_matches.append(f"已参考同行人需求：{'、'.join(_cn_value(item) for item in companions)}。")
    if preferences:
        profile_matches.append(f"已参考本次旅行偏好：{'、'.join(_cn_value(item) for item in preferences)}。")
    if replan_reason:
        risks.append(f"已应用重规划原因：{_cn_value(replan_reason)}。")
    if isinstance(group_coordination, dict) and group_coordination:
        compromise = group_coordination.get("compromisePlan")
        coordination_id = group_coordination.get("coordinationId")
        if isinstance(compromise, dict):
            pace = _cn_value(compromise.get("pace") or "均衡节奏")
            budget_hint = _cn_value(compromise.get("budget") or "均衡预算")
            profile_matches.append(
                f"已应用群体协同方案（{coordination_id or '当前方案'}）：节奏 {pace}，预算 {budget_hint}。"
            )
    plan["profileMatches"] = profile_matches
    plan["risks"] = risks
    _localize_trip_plan_text(plan)


@router.post("/plan")
def create_trip_plan(
    payload: TripPlanRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    trip_id = payload.tripId or f"current-{effective_user_id}-trip"
    planning_inputs: dict[str, object] = {
        "destination": payload.destination,
        "originCoordinate": payload.originCoordinate,
        "destinationCoordinate": payload.destinationCoordinate,
        "dateRange": {"startDate": payload.startDate, "endDate": payload.endDate},
        "budget": payload.budget,
        "companions": payload.companions,
        "preferences": payload.preferences,
        "transportMode": payload.transportMode,
        "tripStyle": payload.tripStyle,
        "replanReason": payload.replanReason,
        "groupCoordination": payload.groupCoordination,
    }
    state = create_initial_state(
        message=payload.message,
        session_id=f"trip-plan-{effective_user_id}-{trip_id}",
        user_id=effective_user_id,
        trip_id=trip_id,
        context={"planningInputs": planning_inputs},
    )
    result = TravelMateGraph().invoke_plan_only(state)
    persist_model_call_logs(session, result.get("model_call_logs", []))
    plan = result["trip_plan"]
    plan["tripId"] = trip_id
    plan["planningInputs"] = planning_inputs
    _apply_planning_input_explanations(plan, planning_inputs)
    now = utc_now()
    trip = session.get(CloudTrip, trip_id)
    destination = payload.destination or str(plan.get("destination") or "Unnamed destination")
    if trip:
        trip.destination = destination
        trip.status = "planning"
        trip.start_date = payload.startDate
        trip.end_date = payload.endDate
        trip.budget = payload.budget
        trip.companions_json = json.dumps(payload.companions, ensure_ascii=False)
        trip.trip_style = payload.tripStyle
        trip.plan_json = json.dumps(plan, ensure_ascii=False)
        trip.updated_at = now
    else:
        trip = CloudTrip(
            id=trip_id,
            user_id=effective_user_id,
            destination=destination,
            status="planning",
            start_date=payload.startDate,
            end_date=payload.endDate,
            budget=payload.budget,
            companions_json=json.dumps(payload.companions, ensure_ascii=False),
            trip_style=payload.tripStyle,
            plan_json=json.dumps(plan, ensure_ascii=False),
            created_at=now,
            updated_at=now,
        )
    session.add(trip)
    session.commit()
    return plan


@router.delete("/current")
def clear_current_trip(
    userId: str | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    trip = session.exec(
        select(CloudTrip).where(CloudTrip.user_id == effective_user_id).order_by(CloudTrip.updated_at.desc())
    ).first()
    count = 1 if trip else 0
    if trip:
        session.delete(trip)
    session.commit()
    return {"deleted": count, "userId": effective_user_id}


@router.post("/review")
def create_trip_review(
    payload: TripReviewRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    trip_id = payload.tripId or f"current-{effective_user_id}-trip"
    route = _review_route(session, effective_user_id, trip_id)
    state = create_initial_state(
        message=payload.message,
        session_id=f"trip-review-{effective_user_id}-{trip_id}",
        user_id=effective_user_id,
        trip_id=trip_id,
        context={
            "completedTasks": payload.completedTasks or _completed_blind_box_tasks(session, effective_user_id, trip_id),
            "temporaryMemories": payload.temporaryMemories or _review_temporary_memories(session, effective_user_id, trip_id),
            "newMemories": _review_new_memories(session, effective_user_id, trip_id),
            "highlightPhotos": _review_photo_highlights(session, effective_user_id, trip_id),
            "reminderHighlights": _review_reminder_highlights(session, effective_user_id, trip_id),
            "avatarStatusChanges": _review_avatar_status_changes(session, effective_user_id, trip_id),
            "route": route,
            "nextTripSuggestions": _review_next_trip_suggestions(session, effective_user_id, trip_id),
            "profileContext": payload.profileContext,
        },
    )
    result = TravelMateGraph().invoke_review_only(state)
    persist_model_call_logs(session, result.get("model_call_logs", []))
    review = _normalized_trip_review(result["review"], route)
    record = CloudTripReview(
        id=f"review-{uuid4().hex}",
        user_id=effective_user_id,
        trip_id=trip_id,
        review_json=json.dumps(review, ensure_ascii=False),
    )
    session.add(record)
    session.commit()
    session.refresh(record)
    response = dict(review)
    response["reviewId"] = record.id
    response["tripId"] = record.trip_id
    return response


@router.get("/review")
def read_trip_review(
    tripId: str = Query(...),
    userId: str | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    trip = session.get(CloudTrip, tripId)
    if trip and trip.user_id != effective_user_id:
        return {"reviewId": None, "tripId": tripId, "review": {}}
    record = session.exec(
        select(CloudTripReview)
        .where(CloudTripReview.user_id == effective_user_id)
        .where(CloudTripReview.trip_id == tripId)
        .order_by(CloudTripReview.created_at.desc())
    ).first()
    if not record:
        return {"reviewId": None, "tripId": tripId, "review": {}}
    return _review_response(record)


@router.post("/reminders/trigger")
def trigger_reminders(
    payload: ReminderTriggerRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    state = create_initial_state(
        message=f"触发提醒：{payload.triggerType} {payload.location or ''}",
        session_id=f"reminder-{effective_user_id}-{payload.tripId or payload.triggerType}",
        user_id=effective_user_id,
        trip_id=payload.tripId,
        context={
            "triggerType": payload.triggerType,
            "location": payload.location,
            "eventPayload": payload.eventPayload,
        },
    )
    result = TravelMateGraph().invoke(state)
    reminders = result["reminders"]
    record = ReminderEvent(
        id=f"reminder-{uuid4().hex}",
        user_id=effective_user_id,
        trip_id=payload.tripId,
        trigger_type=payload.triggerType,
        location=payload.location,
        event_payload_json=json.dumps(payload.eventPayload, ensure_ascii=False),
        reminders_json=json.dumps(reminders, ensure_ascii=False),
        created_at=utc_now(),
    )
    session.add(record)
    session.commit()
    session.refresh(record)
    return {"historyId": record.id, "items": reminders}


def _parse_hour(value: str | None) -> int | None:
    if not value:
        return None
    try:
        return int(value[11:13])
    except (TypeError, ValueError):
        return None


def _reminder_cooldown_remaining(session: Session, user_id: str, trip_id: str | None) -> int:
    statement = select(ReminderEvent).where(ReminderEvent.user_id == user_id)
    if trip_id:
        statement = statement.where(ReminderEvent.trip_id == trip_id)
    latest = session.exec(statement.order_by(ReminderEvent.created_at.desc())).first()
    if latest is None:
        return 0
    created_at = latest.created_at
    now = utc_now()
    if created_at.tzinfo is None:
        created_at = created_at.replace(tzinfo=now.tzinfo)
    elapsed = (now - created_at).total_seconds()
    cooldown_seconds = 45 * 60
    return max(0, int(cooldown_seconds - elapsed))


def _evaluate_reminder_triggers(payload: ReminderEvaluateRequest) -> list[dict[str, object]]:
    level = payload.proactivityLevel
    hour = _parse_hour(payload.currentTime)
    energy = payload.status.get("energy")
    try:
        energy_value = float(energy) if energy is not None else None
    except (TypeError, ValueError):
        energy_value = None

    candidates: list[dict[str, object]] = []
    if hour is not None and 17 <= hour <= 19:
        candidates.append({
            "id": "auto-dinner-time",
            "title": "Dinner timing reminder",
            "triggerType": "time",
            "description": "It is dinner time; reserve a lighter meal before the evening route.",
            "cooldownMinutes": 45,
        })
    if payload.location:
        candidates.append({
            "id": "auto-location-nearby",
            "title": "Nearby route reminder",
            "triggerType": "location",
            "description": f"You are near {payload.location}; check the next stop before walking further.",
            "cooldownMinutes": 45,
        })
    if energy_value is not None and energy_value <= 40:
        candidates.append({
            "id": "auto-low-energy",
            "title": "Low energy reminder",
            "triggerType": "status",
            "description": "Energy is low; switch to a shorter or indoor alternative.",
            "cooldownMinutes": 45,
            "energy": energy_value,
        })
    if payload.external.get("weatherWarning") or payload.external.get("queueLevel") == "high":
        candidates.append({
            "id": "auto-external-risk",
            "title": "External risk reminder",
            "triggerType": "external",
            "description": "Weather or queue conditions changed; keep a backup plan ready.",
            "cooldownMinutes": 45,
            "event": payload.external,
        })

    if level == "quiet":
        return [item for item in candidates if item["triggerType"] == "status"]
    if level == "active":
        return candidates
    return candidates[:4]


@router.post("/reminders/evaluate")
def evaluate_reminders(
    payload: ReminderEvaluateRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    remaining = _reminder_cooldown_remaining(session, effective_user_id, payload.tripId)
    if remaining > 0:
        return {
            "triggered": False,
            "historyId": None,
            "items": [],
            "suppressedReason": "cooldown",
            "cooldownRemainingSeconds": remaining,
        }

    reminders = _evaluate_reminder_triggers(payload)
    if not reminders:
        return {
            "triggered": False,
            "historyId": None,
            "items": [],
            "suppressedReason": "no_trigger",
            "cooldownRemainingSeconds": 0,
        }

    record = ReminderEvent(
        id=f"reminder-{uuid4().hex}",
        user_id=effective_user_id,
        trip_id=payload.tripId,
        trigger_type="auto",
        location=payload.location,
        event_payload_json=json.dumps({
            "proactivityLevel": payload.proactivityLevel,
            "currentTime": payload.currentTime,
            "status": payload.status,
            "external": payload.external,
        }, ensure_ascii=False),
        reminders_json=json.dumps(reminders, ensure_ascii=False),
        created_at=utc_now(),
    )
    session.add(record)
    session.commit()
    session.refresh(record)
    return {
        "triggered": True,
        "historyId": record.id,
        "items": reminders,
        "suppressedReason": None,
        "cooldownRemainingSeconds": 0,
    }


@router.get("/reminders/history")
def read_reminder_history(
    userId: str | None = Query(default=None),
    tripId: str | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, list[dict[str, object]]]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    statement = select(ReminderEvent).where(ReminderEvent.user_id == effective_user_id)
    if tripId:
        statement = statement.where(ReminderEvent.trip_id == tripId)
    records = session.exec(statement.order_by(ReminderEvent.created_at.desc())).all()
    return {"items": [_reminder_response(record) for record in records]}


@router.post("/group/coordinate")
def create_group_coordination(
    payload: GroupCoordinationRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    now = utc_now()
    members = [_member_public_view(member) for member in payload.members]
    conflicts = _detect_group_conflicts(payload.members)
    compromise_plan = _build_compromise_plan(payload.destination, payload.members)
    privacy_summary = _privacy_summary(payload.members)
    record = GroupCoordinationRecord(
        id=f"group-{uuid4().hex}",
        user_id=effective_user_id,
        trip_id=payload.tripId,
        destination=payload.destination,
        members_json=json.dumps(members, ensure_ascii=False),
        conflicts_json=json.dumps(conflicts, ensure_ascii=False),
        compromise_plan_json=json.dumps(compromise_plan, ensure_ascii=False),
        privacy_summary_json=json.dumps(privacy_summary, ensure_ascii=False),
        created_at=now,
        updated_at=now,
    )
    session.add(record)
    trip = session.get(CloudTrip, payload.tripId)
    if trip:
        trip.companions_json = json.dumps(members, ensure_ascii=False)
        trip.updated_at = now
        session.add(trip)
    session.commit()
    session.refresh(record)
    return _group_coordination_response(record)


@router.get("/group/coordination")
def read_group_coordination(
    tripId: str = Query(...),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    records = session.exec(
        select(GroupCoordinationRecord).where(GroupCoordinationRecord.trip_id == tripId).order_by(GroupCoordinationRecord.updated_at.desc())
    ).all()
    if not records:
        return {"coordinationId": None, "tripId": tripId, "members": [], "conflicts": [], "compromisePlan": {}, "privacySummary": {}}
    return _group_coordination_response(records[0])


def _route_point_response(record: TripRoutePointRecord) -> dict[str, object]:
    return {
        "id": record.id,
        "userId": record.user_id,
        "tripId": record.trip_id,
        "sequence": record.sequence,
        "label": record.label,
        "latitude": record.latitude,
        "longitude": record.longitude,
        "source": record.source,
        "recordedAt": record.recorded_at,
        "createdAt": record.created_at.isoformat(),
    }


def _route_from_points(points: list[dict[str, object]]) -> str:
    return " \u2192 ".join(str(point["label"]) for point in points if point.get("label"))


def _stored_route_points(session: Session, user_id: str, trip_id: str) -> list[TripRoutePointRecord]:
    return session.exec(
        select(TripRoutePointRecord)
        .where(TripRoutePointRecord.user_id == user_id)
        .where(TripRoutePointRecord.trip_id == trip_id)
        .order_by(TripRoutePointRecord.sequence.asc())
    ).all()


def _route_points_payload(records: list[TripRoutePointRecord]) -> dict[str, object]:
    points = [_route_point_response(record) for record in records]
    return {"points": points, "route": _route_from_points(points)}


def _review_route(session: Session, user_id: str, trip_id: str) -> str | None:
    records = _stored_route_points(session, user_id, trip_id)
    if not records:
        return None
    return str(_route_points_payload(records)["route"])


def _normalized_trip_review(review: dict[str, object], route: str | None) -> dict[str, object]:
    normalized = dict(review)
    normalized["route"] = route or ""
    return normalized


def _review_next_trip_suggestions(session: Session, user_id: str, trip_id: str) -> list[str]:
    memories = _trip_memories(session, user_id, trip_id)
    route_points = _stored_route_points(session, user_id, trip_id)
    photos = session.exec(
        select(PhotoCandidateRecord)
        .where(PhotoCandidateRecord.user_id == user_id)
        .where(PhotoCandidateRecord.trip_id == trip_id)
        .where(PhotoCandidateRecord.can_add_to_review == True)  # noqa: E712
        .order_by(PhotoCandidateRecord.share_score.desc())
    ).all()
    reminders = session.exec(
        select(ReminderEvent)
        .where(ReminderEvent.user_id == user_id)
        .where(ReminderEvent.trip_id == trip_id)
        .order_by(ReminderEvent.created_at.desc())
    ).all()

    suggestions: list[str] = []
    if memories and route_points:
        suggestions.append(
            f"Plan a route like {route_points[0].label} next time because '{memories[0].title}' was confirmed."
        )
    if reminders:
        location = reminders[0].location or (route_points[-1].label if route_points else "the last stop")
        suggestions.append(
            f"Keep a lighter backup near {location} when {reminders[0].trigger_type} context appears again."
        )
    if photos:
        suggestions.append(
            f"Reserve another highlight photo stop around {photos[0].location_label} based on this trip's saved photos."
        )
    if memories and not any(memory.title in " ".join(suggestions) for memory in memories):
        suggestions.append(f"Reuse confirmed preference '{memories[0].title}' when creating the next plan.")
    return suggestions[:3]


@router.post("/route-points")
def create_trip_route_points(
    payload: TripRoutePointsRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    existing = _stored_route_points(session, effective_user_id, payload.tripId)
    for record in existing:
        session.delete(record)
    now = utc_now()
    records: list[TripRoutePointRecord] = []
    for index, point in enumerate(payload.points):
        record = TripRoutePointRecord(
            id=f"route-point-{uuid4().hex}",
            user_id=effective_user_id,
            trip_id=payload.tripId,
            sequence=index,
            label=point.label,
            latitude=point.latitude,
            longitude=point.longitude,
            source=point.source,
            recorded_at=point.recordedAt,
            created_at=now,
        )
        session.add(record)
        records.append(record)
    session.commit()
    for record in records:
        session.refresh(record)
    response = _route_points_payload(records)
    response["saved"] = len(records)
    return response


@router.get("/route-points")
def read_trip_route_points(
    userId: str | None = Query(default=None),
    tripId: str = Query(...),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    return _route_points_payload(_stored_route_points(session, effective_user_id, tripId))
BLIND_BOX_TASKS: list[dict[str, object]] = [
    {
        "id": "task-photo-night",
        "type": "photo",
        "title": "拍一张不是游客照的夜景",
        "reward": "好感度 +2",
        "reviewImpact": "进入今日高光照片。",
    },
    {
        "id": "task-food-no-cilantro",
        "type": "food",
        "title": "找到一家不放香菜也好吃的小店",
        "reward": "默契值 +1",
        "reviewImpact": "强化餐饮避雷记忆。",
    },
    {
        "id": "task-route-slow",
        "type": "route",
        "title": "主动选择一次少走路的路线",
        "reward": "精力 +5",
        "reviewImpact": "沉淀慢节奏旅行偏好。",
    },
    {
        "id": "task-interaction",
        "type": "interaction",
        "title": "让蓝小心推荐一个附近小发现",
        "reward": "好奇心 +3",
        "reviewImpact": "记录一次搭子共同发现。",
    },
    {
        "id": "task-story",
        "type": "story",
        "title": "给今天的高光照片写一句标题",
        "reward": "默契值 +2",
        "reviewImpact": "用于复盘卡标题和分享文案。",
    },
]

_ALLOWED_BLIND_BOX_STATUSES = {"accepted", "skipped", "completed"}


def _blind_box_task_definition(task_id: str) -> dict[str, object] | None:
    return next((task for task in BLIND_BOX_TASKS if task["id"] == task_id), None)


def _blind_box_response(record: BlindBoxTaskRecord) -> dict[str, object]:
    return {
        "id": record.id,
        "taskId": record.task_id,
        "userId": record.user_id,
        "tripId": record.trip_id,
        "status": record.status,
        "note": record.note,
        "rewardApplied": record.reward_applied,
        "rewardDeltas": {"affection": 2, "rapport": 1} if record.reward_applied else {},
        "acceptedAt": record.accepted_at.isoformat() if record.accepted_at else None,
        "completedAt": record.completed_at.isoformat() if record.completed_at else None,
        "createdAt": record.created_at.isoformat(),
        "updatedAt": record.updated_at.isoformat(),
    }


def _blind_box_task_for_review(record: BlindBoxTaskRecord) -> dict[str, object]:
    task = dict(_blind_box_task_definition(record.task_id) or {"id": record.task_id, "title": record.task_id})
    task["status"] = record.status
    task["note"] = record.note
    task["rewardApplied"] = record.reward_applied
    task["completedAt"] = record.completed_at.isoformat() if record.completed_at else None
    return task


def _completed_blind_box_tasks(session: Session, user_id: str, trip_id: str) -> list[dict[str, object]]:
    records = session.exec(
        select(BlindBoxTaskRecord)
        .where(BlindBoxTaskRecord.user_id == user_id)
        .where(BlindBoxTaskRecord.trip_id == trip_id)
        .where(BlindBoxTaskRecord.status == "completed")
        .order_by(BlindBoxTaskRecord.updated_at.desc())
    ).all()
    return [_blind_box_task_for_review(record) for record in records]


def _trip_memories(session: Session, user_id: str, trip_id: str) -> list[CloudMemory]:
    return session.exec(
        select(CloudMemory)
        .where(CloudMemory.user_id == user_id)
        .where(CloudMemory.status == "confirmed")
        .where(CloudMemory.source_text == trip_id)
        .order_by(CloudMemory.updated_at.desc())
    ).all()


def _review_new_memories(session: Session, user_id: str, trip_id: str) -> list[str]:
    return [
        memory.title
        for memory in _trip_memories(session, user_id, trip_id)
        if memory.scope in {"currentTrip", "longTerm"}
    ]


def _review_temporary_memories(session: Session, user_id: str, trip_id: str) -> list[dict[str, object]]:
    return [
        {
            "id": memory.id,
            "title": memory.title,
            "content": memory.content,
            "category": memory.category,
            "confidence": memory.confidence,
        }
        for memory in _trip_memories(session, user_id, trip_id)
        if memory.scope == "temporary"
    ]

def _review_photo_highlights(session: Session, user_id: str, trip_id: str) -> list[str]:
    records = session.exec(
        select(PhotoCandidateRecord)
        .where(PhotoCandidateRecord.user_id == user_id)
        .where(PhotoCandidateRecord.trip_id == trip_id)
        .where(PhotoCandidateRecord.can_add_to_review == True)  # noqa: E712
        .order_by(PhotoCandidateRecord.share_score.desc())
    ).all()
    return [record.location_label for record in records if record.location_label]


def _review_reminder_highlights(session: Session, user_id: str, trip_id: str) -> list[dict[str, object]]:
    records = session.exec(
        select(ReminderEvent)
        .where(ReminderEvent.user_id == user_id)
        .where(ReminderEvent.trip_id == trip_id)
        .order_by(ReminderEvent.created_at.desc())
    ).all()
    highlights: list[dict[str, object]] = []
    for record in records:
        reminders = json.loads(record.reminders_json)
        first_reminder = reminders[0] if reminders else {}
        highlights.append({
            "historyId": record.id,
            "triggerType": record.trigger_type,
            "location": record.location,
            "title": first_reminder.get("title") if isinstance(first_reminder, dict) else None,
            "createdAt": record.created_at.isoformat(),
        })
    return highlights



def _avatar_state_event_response(record: AvatarStateEventRecord) -> dict[str, object]:
    return {
        "eventId": record.id,
        "userId": record.user_id,
        "tripId": record.trip_id,
        "eventType": record.event_type,
        "title": record.title,
        "deltas": json.loads(record.deltas_json),
        "reason": record.reason,
        "createdAt": record.created_at.isoformat(),
    }


def _create_avatar_state_event(
    session: Session,
    *,
    user_id: str,
    trip_id: str,
    event_type: str,
    title: str,
    deltas: dict[str, int | float],
    reason: str,
) -> AvatarStateEventRecord:
    record = AvatarStateEventRecord(
        id=f"avatar-event-{uuid4().hex}",
        user_id=user_id,
        trip_id=trip_id,
        event_type=event_type,
        title=title,
        deltas_json=json.dumps(deltas, ensure_ascii=False),
        reason=reason,
        created_at=utc_now(),
    )
    session.add(record)
    return record


def _stored_avatar_state_events(session: Session, user_id: str, trip_id: str) -> list[AvatarStateEventRecord]:
    return session.exec(
        select(AvatarStateEventRecord)
        .where(AvatarStateEventRecord.user_id == user_id)
        .where(AvatarStateEventRecord.trip_id == trip_id)
        .order_by(AvatarStateEventRecord.created_at.desc())
    ).all()


def _review_avatar_status_changes(session: Session, user_id: str, trip_id: str) -> list[str]:
    changes: list[str] = []
    for record in _stored_avatar_state_events(session, user_id, trip_id):
        deltas = json.loads(record.deltas_json)
        delta_text = "、".join(f"{key} {value:+g}" for key, value in deltas.items())
        changes.append(f"{record.title}" + (f"（{delta_text}）" if delta_text else ""))
    return changes


@router.post("/avatar-state/events")
def create_avatar_state_event(
    payload: AvatarStateEventRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    record = _create_avatar_state_event(
        session,
        user_id=effective_user_id,
        trip_id=payload.tripId,
        event_type=payload.eventType,
        title=payload.title,
        deltas=payload.deltas,
        reason=payload.reason,
    )
    session.commit()
    session.refresh(record)
    return _avatar_state_event_response(record)


@router.get("/avatar-state/events")
def read_avatar_state_events(
    userId: str | None = Query(default=None),
    tripId: str = Query(...),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, list[dict[str, object]]]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    return {"items": [_avatar_state_event_response(record) for record in _stored_avatar_state_events(session, effective_user_id, tripId)]}
@router.get("/blind-box/tasks")
def read_blind_box_tasks(
    userId: str | None = Query(default=None),
    tripId: str | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, list[dict[str, object]]]:
    effective_user_id = resolve_effective_user_id(userId, current_user)
    records_by_task_id: dict[str, BlindBoxTaskRecord] = {}
    if effective_user_id and tripId:
        records = session.exec(
            select(BlindBoxTaskRecord)
            .where(BlindBoxTaskRecord.user_id == effective_user_id)
            .where(BlindBoxTaskRecord.trip_id == tripId)
            .order_by(BlindBoxTaskRecord.updated_at.desc())
        ).all()
        records_by_task_id = {record.task_id: record for record in records}

    items: list[dict[str, object]] = []
    for task in BLIND_BOX_TASKS:
        item = dict(task)
        record = records_by_task_id.get(str(task["id"]))
        if record:
            item.update({
                "status": record.status,
                "note": record.note,
                "rewardApplied": record.reward_applied,
                "acceptedAt": record.accepted_at.isoformat() if record.accepted_at else None,
                "completedAt": record.completed_at.isoformat() if record.completed_at else None,
                "updatedAt": record.updated_at.isoformat(),
            })
        else:
            item.update({
                "status": "available",
                "note": None,
                "rewardApplied": False,
                "acceptedAt": None,
                "completedAt": None,
            })
        items.append(item)
    return {"items": items}


@router.post("/blind-box/tasks/{task_id}/status")
def update_blind_box_task_status(
    task_id: str,
    payload: BlindBoxTaskStatusRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, object]:
    effective_user_id = resolve_effective_user_id(payload.userId, current_user)
    if task_id not in {str(task["id"]) for task in BLIND_BOX_TASKS}:
        raise HTTPException(status_code=404, detail="Blind box task not found")
    if payload.status not in _ALLOWED_BLIND_BOX_STATUSES:
        raise HTTPException(status_code=400, detail="Unsupported blind box task status")

    now = utc_now()
    record = session.exec(
        select(BlindBoxTaskRecord)
        .where(BlindBoxTaskRecord.user_id == effective_user_id)
        .where(BlindBoxTaskRecord.trip_id == payload.tripId)
        .where(BlindBoxTaskRecord.task_id == task_id)
    ).first()
    if record is None:
        record = BlindBoxTaskRecord(
            id=f"blind-box-{uuid4().hex}",
            user_id=effective_user_id,
            trip_id=payload.tripId,
            task_id=task_id,
            created_at=now,
        )

    record.status = payload.status
    record.note = payload.note
    record.updated_at = now
    if payload.status == "accepted":
        record.accepted_at = record.accepted_at or now
        record.completed_at = None
        record.reward_applied = False
    if payload.status == "completed":
        record.accepted_at = record.accepted_at or now
        record.completed_at = record.completed_at or now
        record.reward_applied = True
        existing_event = session.exec(
            select(AvatarStateEventRecord)
            .where(AvatarStateEventRecord.user_id == effective_user_id)
            .where(AvatarStateEventRecord.trip_id == payload.tripId)
            .where(AvatarStateEventRecord.event_type == "blind_box_completed")
            .where(AvatarStateEventRecord.reason == task_id)
        ).first()
        if existing_event is None:
            task = _blind_box_task_definition(task_id) or {}
            _create_avatar_state_event(
                session,
                user_id=effective_user_id,
                trip_id=payload.tripId,
                event_type="blind_box_completed",
                title=f"完成盲盒任务：{task.get('reward', '状态奖励')}",
                deltas={"affection": 2, "rapport": 1},
                reason=task_id,
            )
    if payload.status == "skipped":
        record.completed_at = None
        record.reward_applied = False

    session.add(record)
    session.commit()
    session.refresh(record)
    return _blind_box_response(record)
