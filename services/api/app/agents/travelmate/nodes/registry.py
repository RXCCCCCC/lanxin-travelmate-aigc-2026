from app.agents.travelmate.nodes import real_nodes


NODE_SEQUENCE = [
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

PLAN_ONLY_NODE_SEQUENCE = [
    "input_normalizer",
    "context_loader",
    "intent_router",
    "trip_context_builder",
    "tool_planner",
    "tool_executor",
    "trip_planner",
    "trip_adjuster",
]

REVIEW_ONLY_NODE_SEQUENCE = [
    "input_normalizer",
    "context_loader",
    "intent_router",
    "review_generator",
]

CHAT_ONLY_NODE_SEQUENCE = [
    "input_normalizer",
    "context_loader",
    "intent_router",
    "fast_chat_response",
    "error_fallback",
]


NODE_TABLE = {
    "input_normalizer": real_nodes.input_normalizer,
    "context_loader": real_nodes.context_loader,
    "intent_router": real_nodes.intent_router,
    "memory_extractor": real_nodes.memory_extractor,
    "memory_confirm_interrupt": real_nodes.memory_confirm_interrupt,
    "memory_writer": real_nodes.memory_writer,
    "profile_updater": real_nodes.profile_updater,
    "trip_context_builder": real_nodes.trip_context_builder,
    "tool_planner": real_nodes.tool_planner,
    "tool_executor": real_nodes.tool_executor,
    "trip_planner": real_nodes.trip_planner,
    "trip_adjuster": real_nodes.trip_adjuster,
    "reminder_checker": real_nodes.reminder_checker,
    "photo_analyzer": real_nodes.photo_analyzer,
    "copywriter": real_nodes.copywriter,
    "review_generator": real_nodes.review_generator,
    "avatar_state_mapper": real_nodes.avatar_state_mapper,
    "fast_chat_response": real_nodes.fast_chat_response,
    "response_composer": real_nodes.response_composer,
    "error_fallback": real_nodes.error_fallback,
}
