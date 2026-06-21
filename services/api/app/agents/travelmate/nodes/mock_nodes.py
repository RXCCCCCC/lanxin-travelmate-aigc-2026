"""Compatibility exports for the former mock node module.

Runtime graph nodes now live in real_nodes.py and are registered through registry.py.
Keep this module so older imports do not break while tests and app code migrate.
"""

from app.agents.travelmate.nodes.real_nodes import *  # noqa: F403
from app.agents.travelmate.nodes.registry import NODE_SEQUENCE, NODE_TABLE