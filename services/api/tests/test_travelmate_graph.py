from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.nodes import real_nodes
from app.agents.travelmate.state import create_initial_state


def test_travelmate_graph_runs_mock_p0_flow():
    state = create_initial_state(
        message="周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜",
        session_id="demo-session",
    )

    result = TravelMateGraph().invoke(state)

    assert result["response"]["avatarState"] == "planning"
    assert "重庆" in result["response"]["replyText"]
    assert len(result["memory_candidates"]) >= 3
    assert result["avatar_status"]["rapport"] >= 13
    assert "response_composer" in result["visited_nodes"]


def test_travelmate_graph_marks_sensitive_memory_candidates():
    state = create_initial_state(
        message="我最近膝盖不舒服，住在解放碑附近，这次和妈妈一起去重庆，别安排太多爬坡",
        session_id="privacy-session",
    )

    result = TravelMateGraph().invoke(state)
    sensitive_candidates = [
        item for item in result["memory_candidates"] if item.get("sensitivity") == "sensitive"
    ]

    assert sensitive_candidates
    assert all(item["requiresExplicitConsent"] is True for item in sensitive_candidates)
    assert all(item["recommendedScope"] in {"currentTrip", "temporary", "ignore"} for item in sensitive_candidates)
    assert any(item.get("category") == "health" for item in sensitive_candidates)
    assert any(suggestion["type"] == "sensitiveMemoryConfirmation" for suggestion in result["sync_suggestions"])

def test_travelmate_graph_requires_explicit_consent_for_dietary_restrictions():
    state = create_initial_state(
        message="周末去重庆两天，我不吃香菜，喜欢夜景",
        session_id="dietary-privacy-session",
    )

    result = TravelMateGraph().invoke(state)
    dietary = next(
        item for item in result["memory_candidates"] if item["id"] == "mem-cilantro"
    )

    assert dietary["category"] == "dietary_preference"
    assert dietary["sensitivity"] == "personal"
    assert dietary["requiresExplicitConsent"] is True
    assert dietary["recommendedScope"] == "longTerm"
    assert "longTerm" in dietary["scopeOptions"]


def test_trip_context_builder_uses_requested_destination_instead_of_fixture():
    state = create_initial_state(
        message="周末想去杭州两天，不想太累，喜欢夜景",
        context={"planningInputs": {"destination": "杭州"}},
    )
    normalized = real_nodes.input_normalizer(state)

    result = real_nodes.trip_context_builder(normalized)

    assert result["trip_context"]["destination"] == "杭州"


def test_trip_context_builder_extracts_destination_from_message_without_fixture():
    state = create_initial_state(
        message="\u5468\u672b\u60f3\u53bb\u676d\u5dde\u4e24\u5929\uff0c\u4e0d\u60f3\u592a\u7d2f\uff0c\u559c\u6b22\u591c\u666f",
    )
    normalized = real_nodes.input_normalizer(state)

    result = real_nodes.trip_context_builder(normalized)

    assert result["trip_context"]["destination"] == "\u676d\u5dde"
    assert result["trip_context"]["pace"] == "\u8f7b\u677e"
    assert "\u591c\u666f" in result["trip_context"]["mustKeep"]
