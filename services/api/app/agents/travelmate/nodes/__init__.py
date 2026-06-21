"""TravelMate LangGraph 节点。

提供三套节点实现：
- real_nodes：LLM 驱动，自动降级到规则实现
- fallback_nodes：纯关键词规则实现
- mock_nodes：向后兼容，等同于 fallback_nodes
"""

from app.agents.travelmate.nodes.common import NODE_SEQUENCE
from app.agents.travelmate.nodes.fallback_nodes import FALLBACK_NODE_TABLE
from app.agents.travelmate.nodes.real_nodes import REAL_NODE_TABLE

__all__ = ["NODE_SEQUENCE", "FALLBACK_NODE_TABLE", "REAL_NODE_TABLE"]
