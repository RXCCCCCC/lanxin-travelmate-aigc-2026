from time import monotonic, sleep

from app.agents.travelmate.tool_execution import execute_tool_plan


class SlowRegistry:
    def __init__(self, failing: set[str] | None = None):
        self.failing = failing or set()
        self.calls: list[str] = []

    def call(self, name: str, payload: dict[str, object]) -> dict[str, object]:
        self.calls.append(name)
        sleep(0.12)
        if name in self.failing:
            raise RuntimeError(f"{name} failed")
        return {"provider": "test", "fallback": False, "value": name}


def _step(step_id: str, tool: str, depends_on: list[str] | None = None) -> dict[str, object]:
    return {
        "stepId": step_id,
        "tool": tool,
        "reason": f"调用 {tool}",
        "input": {"city": "杭州"},
        "dependsOn": depends_on or [],
    }


def test_independent_tools_execute_in_parallel_and_trace_order_is_stable():
    registry = SlowRegistry()
    started = monotonic()

    trace = execute_tool_plan(
        [_step("weather", "weather_tool"), _step("poi", "poi_tool")],
        registry,
        max_workers=2,
    )

    elapsed = monotonic() - started
    assert elapsed < 0.21
    assert [item["stepId"] for item in trace] == ["weather", "poi"]
    assert all(item["dependencyStatus"] == "satisfied" for item in trace)
    assert all(item["elapsedMs"] >= 100 for item in trace)


def test_one_tool_failure_does_not_cancel_independent_tool():
    registry = SlowRegistry({"weather_tool"})

    trace = execute_tool_plan(
        [_step("weather", "weather_tool"), _step("poi", "poi_tool")],
        registry,
        max_workers=2,
    )

    assert [item["stepId"] for item in trace] == ["weather", "poi"]
    failed = trace[0]
    succeeded = trace[1]
    assert failed["fallback"] is True
    assert failed["errorType"] == "tool_execution_error"
    assert succeeded["output"]["value"] == "poi_tool"


def test_dependent_tool_waits_for_dependency_and_is_blocked_after_failure():
    registry = SlowRegistry({"weather_tool"})

    trace = execute_tool_plan(
        [
            _step("weather", "weather_tool"),
            _step("route", "route_tool", ["weather"]),
        ],
        registry,
        max_workers=2,
    )

    assert [item["stepId"] for item in trace] == ["weather", "route"]
    assert trace[1]["dependencyStatus"] == "blocked"
    assert trace[1]["errorType"] == "dependency_failed"
    assert "route_tool" not in registry.calls
