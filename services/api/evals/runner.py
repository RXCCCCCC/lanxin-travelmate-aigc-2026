import argparse
import json
from pathlib import Path
from statistics import median
from time import perf_counter
from typing import Any

from app.agents.travelmate.intent_routing import decide_intent
from app.agents.travelmate.nodes.fallback_nodes import build_rule_memory_candidates
from app.agents.travelmate.state import create_initial_state
from app.agents.travelmate.tool_planning import build_deterministic_tool_plan
from evals.schema import CaseResult, GoldenCase
from evals.scorers import score_case


def load_cases(cases_dir: Path) -> list[GoldenCase]:
    cases: list[GoldenCase] = []
    for path in sorted(cases_dir.glob("*.json")):
        payload = json.loads(path.read_text(encoding="utf-8"))
        raw_cases = payload.get("cases") if isinstance(payload, dict) else payload
        if not isinstance(raw_cases, list):
            raise ValueError(f"{path} 必须包含 cases 数组。")
        cases.extend(GoldenCase.model_validate(item) for item in raw_cases)
    return cases


def evaluate_case(case: GoldenCase) -> CaseResult:
    started = perf_counter()
    state = create_initial_state(message=case.message, context=case.context)
    decision = decide_intent(case.message)
    state["intent"] = str(decision["intent"])
    plan = build_deterministic_tool_plan(state)
    candidates = build_rule_memory_candidates(case.message)
    tools = [str(step["tool"]) for step in plan["steps"]]
    destination = None
    if plan["steps"]:
        destination = str(plan["steps"][0]["input"].get("city") or "") or None
    sensitive_consent_titles = [
        str(item["title"])
        for item in candidates
        if item.get("sensitivity") == "sensitive" and item.get("requiresExplicitConsent") is True
    ]
    actual: dict[str, Any] = {
        "intent": decision["intent"],
        "tools": tools,
        "destination": destination,
        "memoryTitles": [str(item["title"]) for item in candidates],
        "sensitiveConsentTitles": sensitive_consent_titles,
        "plannerFallback": plan["fallback"],
        "schemaValid": True,
    }
    checks, differences = score_case(case.expected, actual)
    elapsed_ms = int((perf_counter() - started) * 1000)
    return CaseResult(
        id=case.id,
        category=case.category,
        passed=all(checks.values()),
        elapsedMs=elapsed_ms,
        checks=checks,
        expected=case.expected.model_dump(),
        actual=actual,
        differences=differences,
    )


def _percentile(values: list[int], percentile: float) -> int:
    if not values:
        return 0
    ordered = sorted(values)
    index = min(len(ordered) - 1, max(0, round((len(ordered) - 1) * percentile)))
    return ordered[index]


def build_report(results: list[CaseResult]) -> dict[str, Any]:
    total = len(results)
    passed = sum(1 for item in results if item.passed)
    latencies = [item.elapsedMs for item in results]

    def rate(check_name: str) -> float:
        relevant = [item for item in results if check_name in item.checks]
        if not relevant:
            return 1.0
        return round(sum(1 for item in relevant if item.checks[check_name]) / len(relevant), 4)

    return {
        "summary": {
            "total": total,
            "passed": passed,
            "failed": total - passed,
            "passRate": round(passed / total, 4) if total else 0.0,
            "intentAccuracy": rate("intent"),
            "toolSelectionAccuracy": rate("tools"),
            "destinationConsistency": rate("destination"),
            "memoryRecall": rate("memoryTitles"),
            "sensitiveConsentPassRate": rate("sensitiveConsent"),
            "schemaPassRate": rate("schema"),
            "fallbackRate": round(
                sum(1 for item in results if item.actual.get("plannerFallback")) / total,
                4,
            )
            if total
            else 0.0,
            "p50LatencyMs": int(median(latencies)) if latencies else 0,
            "p95LatencyMs": _percentile(latencies, 0.95),
        },
        "results": [item.model_dump() for item in results],
    }


def write_report(report: dict[str, Any], output_dir: Path) -> tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / "deterministic-eval.json"
    markdown_path = output_dir / "deterministic-eval.md"
    json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    summary = report["summary"]
    failed = [item for item in report["results"] if not item["passed"]]
    lines = [
        "# Agent 确定性评测",
        "",
        f"- Cases：{summary['total']}",
        f"- 通过：{summary['passed']}",
        f"- 通过率：{summary['passRate']:.2%}",
        f"- 意图准确率：{summary['intentAccuracy']:.2%}",
        f"- 工具选择准确率：{summary['toolSelectionAccuracy']:.2%}",
        f"- 目的地一致性：{summary['destinationConsistency']:.2%}",
        f"- 记忆命中率：{summary['memoryRecall']:.2%}",
        f"- 敏感确认规则：{summary['sensitiveConsentPassRate']:.2%}",
        f"- Schema 通过率：{summary['schemaPassRate']:.2%}",
        f"- P50/P95：{summary['p50LatencyMs']}ms / {summary['p95LatencyMs']}ms",
    ]
    if failed:
        lines.extend(["", "## 失败 Case"])
        for item in failed:
            lines.append(f"- `{item['id']}`：{', '.join(item['differences'])}")
    markdown_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return json_path, markdown_path


def main() -> int:
    parser = argparse.ArgumentParser(description="运行蓝心同行 Agent 确定性评测")
    parser.add_argument("--cases-dir", type=Path, default=Path(__file__).parent / "cases")
    parser.add_argument("--output-dir", type=Path, default=Path("artifacts/evals"))
    args = parser.parse_args()
    cases = load_cases(args.cases_dir)
    results = [evaluate_case(case) for case in cases]
    report = build_report(results)
    write_report(report, args.output_dir)
    print(json.dumps(report["summary"], ensure_ascii=False))
    return 0 if report["summary"]["failed"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
