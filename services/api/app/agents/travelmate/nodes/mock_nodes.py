"""向后兼容层：重新导出 fallback_nodes 的全部符号。

原有代码 `from app.agents.travelmate.nodes.mock_nodes import NODE_TABLE, NODE_SEQUENCE`
无需修改即可继续工作。新代码应直接从 fallback_nodes 或 real_nodes 导入。
"""

from app.agents.travelmate.nodes.common import (
    NODE_SEQUENCE,
    avatar_state_mapper,
    error_fallback,
    input_normalizer,
    memory_confirm_interrupt,
    profile_updater,
    response_composer,
    tool_executor,
)
from app.agents.travelmate.nodes.fallback_nodes import (
    FALLBACK_NODE_TABLE as NODE_TABLE,
    context_loader,
    copywriter,
    intent_router,
    memory_extractor,
    memory_writer,
    photo_analyzer,
    reminder_checker,
    review_generator,
    tool_planner,
    trip_adjuster,
    trip_context_builder,
    trip_planner,
)

__all__ = [
    "NODE_SEQUENCE",
    "NODE_TABLE",
    "input_normalizer",
    "context_loader",
    "intent_router",
    "memory_extractor",
    "memory_confirm_interrupt",
    "memory_writer",
    "profile_updater",
    "trip_context_builder",
    "tool_planner",
    "tool_executor",
    "trip_planner",
    "trip_adjuster",
    "reminder_checker",
    "photo_analyzer",
    "copywriter",
    "review_generator",
    "avatar_state_mapper",
    "response_composer",
    "error_fallback",
]
