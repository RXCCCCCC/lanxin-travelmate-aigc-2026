import importlib.util
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPT_PATH = REPO_ROOT / "scripts" / "submission_package_manifest.py"


def _load_manifest_module():
    spec = importlib.util.spec_from_file_location("submission_package_manifest", SCRIPT_PATH)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_submission_package_manifest_tracks_required_competition_artifacts():
    module = _load_manifest_module()
    report = module.collect_submission_package_manifest(REPO_ROOT)
    checks = report["checks"]

    expected_slots = {
        "code_repository",
        "android_apk",
        "presentation_deck",
        "demo_video",
        "app_screenshots",
        "api_evidence",
        "privacy_and_material_review",
        "platform_upload",
        "competition_scoring_narrative",
    }

    assert expected_slots.issubset(checks)
    assert checks["code_repository"]["ok"] is True
    assert checks["android_apk"]["manual"] is True
    assert checks["presentation_deck"]["manual"] is True
    assert checks["demo_video"]["manual"] is True
    assert checks["privacy_and_material_review"]["manual"] is True
    assert checks["platform_upload"]["manual"] is True
    assert report["ok"] is True


def test_submission_package_manifest_links_to_authoritative_handoff_docs():
    module = _load_manifest_module()
    report = module.collect_submission_package_manifest(REPO_ROOT)
    docs = "\n".join(report["authoritativeDocs"])

    assert "docs/handoff/submission-checklist.md" in docs
    assert "docs/handoff/demo-evidence-pack.md" in docs
    assert "docs/handoff/presentation-outline.md" in docs
    assert "docs/todo.md" in docs


def test_submission_package_manifest_checks_competition_scoring_narrative():
    module = _load_manifest_module()
    report = module.collect_submission_package_manifest(REPO_ROOT)
    check = report["checks"]["competition_scoring_narrative"]

    expected_dimensions = {
        "innovation",
        "application_value",
        "completion",
        "large_model_usage",
        "technical_feasibility",
        "demo_storyline",
    }

    assert check["ok"] is True
    assert check["manual"] is True
    assert set(check["detail"]["covered"]) == expected_dimensions
    assert check["detail"]["missing"] == {}
