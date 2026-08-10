from concurrent.futures import Future, ThreadPoolExecutor
from time import monotonic
from typing import Any, Protocol


class ToolRegistryProtocol(Protocol):
    def call(self, name: str, payload: dict[str, Any]) -> dict[str, Any]: ...


def _blocked_trace(step: dict[str, Any]) -> dict[str, Any]:
    return {
        "stepId": step["stepId"],
        "tool": step["tool"],
        "reason": step["reason"],
        "input": step["input"],
        "output": {},
        "provider": "executor",
        "fallback": True,
        "fallbackReason": "依赖步骤执行失败，当前步骤未调用。",
        "sourceTime": None,
        "errorType": "dependency_failed",
        "retryCount": 0,
        "cacheHit": False,
        "circuitOpen": False,
        "mock": False,
        "elapsedMs": 0,
        "dependencyStatus": "blocked",
    }


def _run_step(
    registry: ToolRegistryProtocol,
    step: dict[str, Any],
) -> tuple[dict[str, Any], int]:
    started = monotonic()
    try:
        output = registry.call(str(step["tool"]), dict(step["input"]))
        if not isinstance(output, dict):
            raise TypeError("工具返回值必须是对象。")
    except Exception as exc:  # noqa: BLE001 - 单步异常必须隔离为结构化 Trace
        output = {
            "provider": "executor",
            "fallback": True,
            "fallbackReason": str(exc)[:240],
            "errorType": "tool_execution_error",
        }
    return output, int((monotonic() - started) * 1000)


def _step_trace(
    step: dict[str, Any],
    output: dict[str, Any],
    elapsed_ms: int,
) -> dict[str, Any]:
    return {
        "stepId": step["stepId"],
        "tool": step["tool"],
        "reason": step["reason"],
        "input": step["input"],
        "output": output,
        "provider": output.get("provider"),
        "fallback": bool(output.get("fallback")),
        "fallbackReason": output.get("fallbackReason"),
        "sourceTime": output.get("sourceTime"),
        "errorType": output.get("errorType"),
        "retryCount": int(output.get("retryCount") or 0),
        "cacheHit": bool(output.get("cacheHit")),
        "circuitOpen": bool(output.get("circuitOpen")),
        "mock": output.get("provider") == "mock",
        "elapsedMs": elapsed_ms,
        "dependencyStatus": "satisfied",
    }


def execute_tool_plan(
    steps: list[dict[str, Any]],
    registry: ToolRegistryProtocol,
    *,
    max_workers: int = 4,
) -> list[dict[str, Any]]:
    ordered_steps = [dict(step) for step in steps]
    pending = {str(step["stepId"]): step for step in ordered_steps}
    completed: dict[str, dict[str, Any]] = {}
    traces: dict[str, dict[str, Any]] = {}

    with ThreadPoolExecutor(max_workers=max(1, min(max_workers, len(ordered_steps) or 1))) as executor:
        while pending:
            progressed = False
            blocked_ids = []
            for step_id, step in pending.items():
                dependencies = [str(item) for item in step.get("dependsOn", [])]
                if not dependencies or not all(dependency in completed for dependency in dependencies):
                    continue
                if any(bool(completed[dependency].get("fallback")) for dependency in dependencies):
                    traces[step_id] = _blocked_trace(step)
                    completed[step_id] = traces[step_id]["output"]
                    blocked_ids.append(step_id)
                    progressed = True
            for step_id in blocked_ids:
                pending.pop(step_id)

            ready = [
                (step_id, step)
                for step_id, step in pending.items()
                if all(str(dependency) in completed for dependency in step.get("dependsOn", []))
            ]
            if ready:
                futures: dict[str, Future[tuple[dict[str, Any], int]]] = {
                    step_id: executor.submit(_run_step, registry, step)
                    for step_id, step in ready
                }
                for step_id, step in ready:
                    output, elapsed_ms = futures[step_id].result()
                    completed[step_id] = output
                    traces[step_id] = _step_trace(step, output, elapsed_ms)
                    pending.pop(step_id)
                progressed = True

            if not progressed:
                for step_id, step in list(pending.items()):
                    trace = _blocked_trace(step)
                    trace["fallbackReason"] = "工具计划依赖无法解析，当前步骤未调用。"
                    trace["errorType"] = "dependency_unresolved"
                    traces[step_id] = trace
                    completed[step_id] = trace["output"]
                    pending.pop(step_id)

    return [traces[str(step["stepId"])] for step in ordered_steps]
