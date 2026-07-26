from collections.abc import Callable
from functools import lru_cache

from langgraph.graph import END, START, StateGraph

from app.agents.travelmate.nodes.registry import (
    CHAT_ONLY_NODE_SEQUENCE,
    NODE_SEQUENCE,
    NODE_TABLE,
    PLAN_ONLY_NODE_SEQUENCE,
    REVIEW_ONLY_NODE_SEQUENCE,
)
from app.agents.travelmate.state import TravelMateState


@lru_cache(maxsize=3)
def _compile_sequence(sequence: tuple[str, ...]):
    workflow = StateGraph(TravelMateState)
    for name in sequence:
        workflow.add_node(name, NODE_TABLE[name])

    workflow.add_edge(START, sequence[0])
    for current_name, next_name in zip(sequence, sequence[1:]):
        workflow.add_edge(current_name, next_name)
    workflow.add_edge(sequence[-1], END)
    return workflow.compile()


_SEQUENCE_BY_MODE = {
    "full": NODE_SEQUENCE,
    "plan": PLAN_ONLY_NODE_SEQUENCE,
    "review": REVIEW_ONLY_NODE_SEQUENCE,
    "chat": CHAT_ONLY_NODE_SEQUENCE,
}


class TravelMateGraph:
    def __init__(self) -> None:
        pass

    def invoke(self, state: TravelMateState) -> TravelMateState:
        return _compile_sequence(tuple(NODE_SEQUENCE)).invoke(state)

    def invoke_plan_only(self, state: TravelMateState) -> TravelMateState:
        return _compile_sequence(tuple(PLAN_ONLY_NODE_SEQUENCE)).invoke(state)

    def invoke_review_only(self, state: TravelMateState) -> TravelMateState:
        return _compile_sequence(tuple(REVIEW_ONLY_NODE_SEQUENCE)).invoke(state)

    def invoke_chat_only(self, state: TravelMateState) -> TravelMateState:
        return _compile_sequence(tuple(CHAT_ONLY_NODE_SEQUENCE)).invoke(state)

    def stream_nodes(self, state: TravelMateState, mode: str = "full"):
        """逐节点流式执行，产出 (节点名, 节点执行后的完整状态)。"""
        sequence = _SEQUENCE_BY_MODE.get(mode, NODE_SEQUENCE)
        compiled = _compile_sequence(tuple(sequence))
        for update in compiled.stream(state, stream_mode="updates"):
            for node_name, node_state in update.items():
                yield node_name, node_state


TravelMateNode = Callable[[TravelMateState], TravelMateState]
