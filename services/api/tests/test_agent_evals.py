from pathlib import Path

from evals.runner import build_report, evaluate_case, load_cases, write_report


REPO_ROOT = Path(__file__).resolve().parents[3]


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


def test_ci_runs_deterministic_agent_eval_and_uploads_reports():
    workflow = (REPO_ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")

    assert "Run deterministic Agent eval" in workflow
    assert "uv run python -m evals.runner --output-dir artifacts/evals" in workflow
    assert "actions/upload-artifact@v4" in workflow
    assert "services/api/artifacts/evals" in workflow
    assert "if: always()" in workflow
