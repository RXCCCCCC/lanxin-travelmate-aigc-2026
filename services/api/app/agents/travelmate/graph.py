from collections.abc import Callable

from langgraph.graph import END, START, StateGraph

from app.agents.travelmate.nodes.common import NODE_SEQUENCE
from app.agents.travelmate.nodes.fallback_nodes import FALLBACK_NODE_TABLE
from app.agents.travelmate.nodes.real_nodes import REAL_NODE_TABLE
from app.agents.travelmate.state import TravelMateState


class TravelMateGraph:
    """TravelMate Agent 图。

    use_real: 为 True 时使用 LLM 驱动的真实节点（REAL_NODE_TABLE），
             每个真实节点内部会在 LLM 不可用时自动降级到规则实现；
             为 False 时直接使用纯规则降级节点（FALLBACK_NODE_TABLE）。
    """

    def __init__(self, use_real: bool = False) -> None:
        self._use_real = use_real
        node_table = REAL_NODE_TABLE if use_real else FALLBACK_NODE_TABLE
        workflow = StateGraph(TravelMateState)
        for name in NODE_SEQUENCE:
            workflow.add_node(name, node_table[name])

        workflow.add_edge(START, NODE_SEQUENCE[0])
        for current_name, next_name in zip(NODE_SEQUENCE, NODE_SEQUENCE[1:]):
            workflow.add_edge(current_name, next_name)
        workflow.add_edge(NODE_SEQUENCE[-1], END)
        self._app = workflow.compile()

    def invoke(self, state: TravelMateState) -> TravelMateState:
        return self._app.invoke(state)


TravelMateNode = Callable[[TravelMateState], TravelMateState]
