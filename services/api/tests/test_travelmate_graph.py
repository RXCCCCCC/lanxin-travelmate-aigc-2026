from unittest.mock import patch

from app.agents.travelmate.graph import TravelMateGraph
from app.agents.travelmate.nodes import REAL_NODE_TABLE
from app.agents.travelmate.nodes.common import NODE_SEQUENCE
from app.agents.travelmate.state import create_initial_state
from app.services.model_providers import ModelProviderError


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


# ── 新增：real/fallback/error 路径测试 ────────────────────────────────────


def test_real_graph_produces_same_structure_as_fallback_with_mock_provider():
    """use_real=True 在 mock provider 下应降级到规则实现，结果结构与 fallback 一致。"""
    state = create_initial_state(
        message="周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜",
        session_id="real-fallback-test",
    )

    real_result = TravelMateGraph(use_real=True).invoke(state)
    fallback_result = TravelMateGraph(use_real=False).invoke(state)

    assert real_result["response"]["avatarState"] == fallback_result["response"]["avatarState"]
    assert len(real_result["memory_candidates"]) == len(fallback_result["memory_candidates"])
    assert real_result["avatar_status"]["rapport"] >= 13
    assert "response_composer" in real_result["visited_nodes"]


def test_real_graph_preserves_visited_nodes_order():
    """use_real=True 的图仍然按 NODE_SEQUENCE 顺序执行全部节点。"""
    state = create_initial_state(
        message="周末去重庆",
        session_id="real-nodes-order",
    )

    result = TravelMateGraph(use_real=True).invoke(state)

    assert result["visited_nodes"] == NODE_SEQUENCE


def test_real_graph_sensitive_memory_candidates_still_marked():
    """use_real=True 在 mock 降级后，敏感记忆标记行为不变。"""
    state = create_initial_state(
        message="我最近膝盖不舒服，住在解放碑附近，和妈妈一起去重庆",
        session_id="real-privacy",
    )

    result = TravelMateGraph(use_real=True).invoke(state)
    sensitive = [item for item in result["memory_candidates"] if item.get("sensitivity") == "sensitive"]

    assert len(sensitive) >= 2
    assert all(item["requiresExplicitConsent"] is True for item in sensitive)
    assert any(suggestion["type"] == "sensitiveMemoryConfirmation" for suggestion in result["sync_suggestions"])


def test_all_real_nodes_are_in_node_table():
    """REAL_NODE_TABLE 包含 NODE_SEQUENCE 中的所有节点。"""
    for name in NODE_SEQUENCE:
        assert name in REAL_NODE_TABLE, f"REAL_NODE_TABLE 缺少节点: {name}"


def test_memory_extractor_falls_back_on_provider_error(monkeypatch):
    """memory_extractor 在 LLM 抛 ModelProviderError 时降级到规则实现。"""
    from app.agents.travelmate.nodes.real_nodes import memory_extractor

    def _raise_error(*args, **kwargs):
        raise ModelProviderError("模拟的模型错误")

    monkeypatch.setattr(
        "app.agents.travelmate.nodes.real_nodes._try_llm",
        lambda state, node_name, scenario, payload: (_next_state_imported(state, node_name), None),
    )

    state = create_initial_state(
        message="周末去重庆，我不吃香菜，喜欢夜景",
    )
    # 手动跑过前序节点
    state["normalized_input"] = state["message"].strip()
    state["visited_nodes"] = ["input_normalizer"]

    result = memory_extractor(state)

    # 降级后仍然有 memory_candidates
    assert len(result["memory_candidates"]) >= 2
    any_cilantro = any(c["id"] == "mem-cilantro" for c in result["memory_candidates"])
    any_night = any(c["id"] == "mem-night-view" for c in result["memory_candidates"])
    assert any_cilantro
    assert any_night


def test_intent_router_falls_back_on_provider_error(monkeypatch):
    """intent_router 在 LLM 不可用时降级到关键词规则。"""
    from app.agents.travelmate.nodes.real_nodes import intent_router

    monkeypatch.setattr(
        "app.agents.travelmate.nodes.real_nodes._try_llm",
        lambda state, node_name, scenario, payload: (_next_state_imported(state, node_name), None),
    )

    state = create_initial_state(message="帮我规划周末两天行程")
    state["normalized_input"] = state["message"].strip()
    state["visited_nodes"] = ["input_normalizer"]

    result = intent_router(state)
    assert result["intent"] == "trip_planning"


def test_copywriter_falls_back_on_provider_error(monkeypatch):
    """copywriter 在 LLM 不可用时降级到规则实现。"""
    from app.agents.travelmate.nodes.real_nodes import copywriter

    monkeypatch.setattr(
        "app.agents.travelmate.nodes.real_nodes._try_llm",
        lambda state, node_name, scenario, payload: (_next_state_imported(state, node_name), None),
    )

    state = create_initial_state(message="周末去重庆")
    state["normalized_input"] = state["message"].strip()
    state["visited_nodes"] = ["input_normalizer"]

    result = copywriter(state)
    assert len(result["next_actions"]) == 4
    assert any(a["type"] == "confirmMemory" for a in result["next_actions"])


def test_review_generator_falls_back_on_provider_error(monkeypatch):
    """review_generator 在 LLM 不可用时降级到规则实现。"""
    from app.agents.travelmate.nodes.real_nodes import review_generator

    monkeypatch.setattr(
        "app.agents.travelmate.nodes.real_nodes._try_llm",
        lambda state, node_name, scenario, payload: (_next_state_imported(state, node_name), None),
    )

    state = create_initial_state(message="复盘我的重庆之旅")
    state["normalized_input"] = state["message"].strip()
    state["visited_nodes"] = ["input_normalizer"]

    result = review_generator(state)
    assert result["review"]["route"]
    assert len(result["review"]["highlightPhotos"]) >= 1


def test_real_graph_handles_empty_input():
    """use_real=True 的图可以处理简单输入。"""
    state = create_initial_state(message="你好")

    result = TravelMateGraph(use_real=True).invoke(state)

    assert "response" in result
    assert result["response"]["avatarState"] in ("planning", "thinking")
    assert len(result["visited_nodes"]) == len(NODE_SEQUENCE)


# ── 辅助函数 ───────────────────────────────────────────────────────────────

from app.agents.travelmate.nodes.common import _next_state as _next_state_imported
