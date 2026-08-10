from typing import Any

from evals.schema import ExpectedOutcome


def score_case(expected: ExpectedOutcome, actual: dict[str, Any]) -> tuple[dict[str, bool], list[str]]:
    actual_tools = set(actual.get("tools") or [])
    expected_tools = set(expected.tools)
    checks = {
        "intent": actual.get("intent") == expected.intent,
        "tools": actual_tools == expected_tools,
        "excludedTools": all(tool not in actual_tools for tool in expected.excludedTools),
        "destination": expected.destination is None or actual.get("destination") == expected.destination,
        "memoryTitles": set(expected.memoryTitles).issubset(set(actual.get("memoryTitles") or [])),
        "sensitiveConsent": set(expected.sensitiveMemoryTitles).issubset(
            set(actual.get("sensitiveConsentTitles") or [])
        ),
        "plannerFallback": actual.get("plannerFallback") is expected.plannerFallback,
        "schema": bool(actual.get("schemaValid")),
    }
    differences = [name for name, passed in checks.items() if not passed]
    return checks, differences
