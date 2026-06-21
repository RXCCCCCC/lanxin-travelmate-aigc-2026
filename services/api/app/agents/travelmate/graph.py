from collections.abc import Callable

from langgraph.graph import END, START, StateGraph

from app.agents.travelmate.nodes.registry import NODE_SEQUENCE, NODE_TABLE
from app.agents.travelmate.state import TravelMateState


class TravelMateGraph:
    def __init__(self) -> None:
        workflow = StateGraph(TravelMateState)
        for name in NODE_SEQUENCE:
            workflow.add_node(name, NODE_TABLE[name])

        workflow.add_edge(START, NODE_SEQUENCE[0])
        for current_name, next_name in zip(NODE_SEQUENCE, NODE_SEQUENCE[1:]):
            workflow.add_edge(current_name, next_name)
        workflow.add_edge(NODE_SEQUENCE[-1], END)
        self._app = workflow.compile()

    def invoke(self, state: TravelMateState) -> TravelMateState:
        return self._app.invoke(state)


TravelMateNode = Callable[[TravelMateState], TravelMateState]
