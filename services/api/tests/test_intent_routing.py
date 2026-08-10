from app.agents.travelmate.intent_routing import decide_intent
from app.agents.travelmate.nodes import real_nodes
from app.agents.travelmate.state import create_initial_state


def test_chinese_and_english_planning_messages_share_plan_mode():
    chinese = decide_intent("帮我规划杭州两天行程")
    english = decide_intent("Plan a two-day Hangzhou itinerary")

    assert chinese["intent"] == "trip_planning"
    assert english["intent"] == "trip_planning"
    assert chinese["mode"] == english["mode"] == "plan"


def test_review_and_chat_intents_are_structured():
    review = decide_intent("帮我复盘这次旅行")
    chat = decide_intent("今天心情一般，陪我聊聊")

    assert review["intent"] == "trip_review"
    assert review["mode"] == "review"
    assert chat["intent"] == "companion_chat"
    assert chat["mode"] == "chat"


def test_graph_intent_router_reuses_existing_decision_and_emits_trace():
    state = create_initial_state(message="这条文本本身不包含规划关键词")
    state["intent_decision"] = decide_intent("推荐广州夜景")

    result = real_nodes.intent_router(state)

    assert result["intent"] == "trip_planning"
    assert result["intent_decision"]["mode"] == "plan"
    trace = next(item for item in result["tool_trace"] if item["tool"] == "intent_router")
    assert trace["decision"] == "trip_planning"
    assert trace["fallback"] is True
