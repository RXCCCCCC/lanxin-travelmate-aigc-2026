from pathlib import Path

from evals.runner import build_report, evaluate_case, load_cases, write_report


def test_deterministic_agent_eval_has_at_least_thirty_passing_cases(tmp_path: Path):
    cases = load_cases(Path(__file__).parents[1] / "evals" / "cases")

    results = [evaluate_case(case) for case in cases]
    report = build_report(results)
    json_path, markdown_path = write_report(report, tmp_path)

    assert len(cases) >= 30
    assert report["summary"]["failed"] == 0
    assert report["summary"]["intentAccuracy"] == 1.0
    assert report["summary"]["toolSelectionAccuracy"] == 1.0
    assert report["summary"]["schemaPassRate"] == 1.0
    assert json_path.exists()
    assert markdown_path.exists()
