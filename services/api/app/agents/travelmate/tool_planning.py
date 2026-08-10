import re
from typing import Any

from pydantic import ValidationError

from app.agents.travelmate.schemas.tool_plan import ToolPlan, ToolStep
from app.agents.travelmate.state import TravelMateState
from app.core.config import get_settings
from app.services.model_providers import ModelProviderError, build_model_provider
from app.tools.registry import build_tool_registry


MAX_TOOL_STEPS = 4


def _coordinate_to_location(value: object) -> str | None:
    if not isinstance(value, dict):
        return None
    latitude = value.get("latitude")
    longitude = value.get("longitude")
    if latitude is None or longitude is None:
        return None
    return f"{longitude},{latitude}"


def _planning_inputs(state: TravelMateState) -> dict[str, Any]:
    context = state.get("context") if isinstance(state.get("context"), dict) else {}
    values = context.get("planningInputs")
    return values if isinstance(values, dict) else {}


def _destination(state: TravelMateState) -> str:
    planning_inputs = _planning_inputs(state)
    explicit = str(
        planning_inputs.get("destination")
        or state.get("trip_context", {}).get("destination")
        or ""
    ).strip()
    if explicit:
        return explicit
    from app.agents.travelmate.nodes.real_nodes import _extract_trip_destination

    parsed = _extract_trip_destination(state)
    if parsed != "待确认目的地":
        return re.sub(r"(今天|明天|后天)$", "", parsed).strip() or parsed
    text = str(state.get("normalized_input") or state.get("message") or "")
    match = re.search(r"^([\u4e00-\u9fff]{2,10}?)(?:今天|明天|后天)?(?:天气|气温)", text)
    return match.group(1) if match else parsed


def validate_tool_plan(plan: ToolPlan, allowed_tools: set[str]) -> ToolPlan:
    if len(plan.steps) > min(plan.maxSteps, MAX_TOOL_STEPS):
        raise ValueError("ToolPlan 超过单轮最大步骤数。")
    step_ids = {step.stepId for step in plan.steps}
    if len(step_ids) != len(plan.steps):
        raise ValueError("ToolPlan stepId 必须唯一。")
    for step in plan.steps:
        if step.tool not in allowed_tools:
            raise ValueError(f"ToolPlan 使用了未注册工具：{step.tool}")
        if any(dependency not in step_ids for dependency in step.dependsOn):
            raise ValueError(f"ToolPlan 依赖了不存在的步骤：{step.stepId}")
        if step.stepId in step.dependsOn:
            raise ValueError(f"ToolPlan 步骤不能依赖自身：{step.stepId}")

    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(step_id: str) -> None:
        if step_id in visiting:
            raise ValueError("ToolPlan 依赖关系存在循环。")
        if step_id in visited:
            return
        visiting.add(step_id)
        step = next(item for item in plan.steps if item.stepId == step_id)
        for dependency in step.dependsOn:
            visit(dependency)
        visiting.remove(step_id)
        visited.add(step_id)

    for step in plan.steps:
        visit(step.stepId)
    return plan


def _deterministic_plan(state: TravelMateState, *, reason: str) -> dict[str, Any]:
    text = str(state.get("normalized_input") or state.get("message") or "")
    lowered = text.lower()
    destination = _destination(state)
    planning_inputs = _planning_inputs(state)
    has_coordinates = bool(
        _coordinate_to_location(planning_inputs.get("originCoordinate"))
        and _coordinate_to_location(planning_inputs.get("destinationCoordinate"))
    )
    weather_requested = any(word in text for word in ("天气", "气温", "下雨", "雨天")) or any(
        word in lowered for word in ("weather", "temperature")
    )
    poi_requested = any(word in text for word in ("景点", "夜景", "推荐", "好玩", "从当前位置")) or any(
        word in lowered for word in ("poi", "attraction", "night view", "recommend")
    )
    route_requested = any(word in text for word in ("路线", "行程", "规划", "导航", "从当前位置")) or any(
        word in lowered for word in ("route", "itinerary", "plan", "weekend")
    )
    steps: list[ToolStep] = []
    if weather_requested or poi_requested or route_requested:
        steps.append(
            ToolStep(
                stepId="weather",
                tool="weather_tool",
                reason="获取目的地天气，帮助判断是否需要调整户外安排。",
                input={"city": destination},
            )
        )
    if poi_requested or route_requested:
        steps.append(
            ToolStep(
                stepId="poi",
                tool="poi_tool",
                reason="查询与用户需求匹配的目的地景点候选。",
                input={"city": destination, "keyword": "夜景" if "夜景" in text else "旅行景点"},
            )
        )
    if route_requested and has_coordinates:
        steps.append(
            ToolStep(
                stepId="route",
                tool="route_tool",
                reason="已有起终点坐标，计算可执行的出行路线。",
                input={
                    "city": destination,
                    "destination": destination,
                    "originLocation": _coordinate_to_location(planning_inputs.get("originCoordinate")),
                    "destinationLocation": _coordinate_to_location(planning_inputs.get("destinationCoordinate")),
                    "mode": str(planning_inputs.get("transportMode") or "walking"),
                    "pace": str(state.get("trip_context", {}).get("pace") or "轻松"),
                },
            )
        )
    return ToolPlan(
        goal=text or "旅行助手工具查询",
        steps=steps,
        maxSteps=MAX_TOOL_STEPS,
        plannerProvider="deterministic",
        fallback=True,
        fallbackReason=reason,
    ).model_dump()


def build_constrained_tool_plan(state: TravelMateState) -> dict[str, Any]:
    allowed_tools = set(build_tool_registry().tool_names())
    provider = None
    try:
        provider = build_model_provider(get_settings())
        payload = provider.generate_json(
            scenario="tool_planning",
            system_prompt="Return a constrained ToolPlan JSON only.",
            user_prompt=str(
                {
                    "message": state.get("normalized_input") or state.get("message"),
                    "intent": state.get("intent"),
                    "tripContext": state.get("trip_context", {}),
                    "planningInputs": _planning_inputs(state),
                    "allowedTools": sorted(allowed_tools),
                }
            ),
            schema={"task": "toolPlan"},
        )
        raw = payload.get("toolPlan") if isinstance(payload, dict) else None
        if not isinstance(raw, dict):
            raise ValueError("模型未返回 toolPlan。")
        plan = validate_tool_plan(ToolPlan.model_validate(raw), allowed_tools)
        plan.fallback = False
        plan.plannerProvider = provider.name
        return plan.model_dump()
    except (AttributeError, ModelProviderError, ValidationError, TypeError, ValueError) as exc:
        provider_name = provider.name if provider is not None else get_settings().model_provider
        return _deterministic_plan(
            state,
            reason=f"结构化工具规划不可用（{provider_name}）：{str(exc)[:160]}",
        )
