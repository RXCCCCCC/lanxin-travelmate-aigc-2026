import importlib.util
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPT_PATH = REPO_ROOT / "scripts" / "public_submission_hygiene.py"


def _load_hygiene_module():
    spec = importlib.util.spec_from_file_location("public_submission_hygiene", SCRIPT_PATH)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_public_submission_hygiene_blocks_secret_and_privacy_leaks():
    module = _load_hygiene_module()
    report = module.collect_public_submission_hygiene(REPO_ROOT)
    checks = report["checks"]

    expected_checks = {
        "env_files_not_tracked",
        "gitignore_blocks_local_secrets",
        "env_example_uses_placeholders",
        "tracked_text_has_no_secret_markers",
        "public_material_privacy_reviewed",
    }

    assert expected_checks.issubset(checks)
    assert all(checks[name]["ok"] is True for name in expected_checks)
    assert report["ok"] is True


def test_public_submission_hygiene_scans_authoritative_materials():
    module = _load_hygiene_module()
    report = module.collect_public_submission_hygiene(REPO_ROOT)
    scanned = "\n".join(report["scannedPublicMaterials"])

    assert "README.md" in scanned
    assert "docs/handoff/submission-checklist.md" in scanned
    assert "docs/handoff/demo-evidence-pack.md" in scanned
    assert "docs/handoff/presentation-outline.md" in scanned
