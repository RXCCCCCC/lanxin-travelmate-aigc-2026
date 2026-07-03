import importlib.util
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPT_PATH = REPO_ROOT / "scripts" / "demo_evidence_readiness.py"


def _load_demo_evidence_module():
    spec = importlib.util.spec_from_file_location("demo_evidence_readiness", SCRIPT_PATH)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_demo_evidence_readiness_tracks_required_capture_plan():
    module = _load_demo_evidence_module()
    report = module.collect_demo_evidence_readiness(REPO_ROOT)
    checks = report["checks"]

    assert checks["required_docs_present"]["ok"] is True
    assert checks["demo_storyboard_covers_p0_loop"]["ok"] is True
    assert checks["capture_manifest_covers_app_and_api"]["ok"] is True
    assert checks["privacy_review_markers_present"]["ok"] is True
    assert checks["real_capability_markers_present"]["ok"] is True
    assert checks["manual_capture_status_explicit"]["ok"] is True
    assert checks["artifact_placeholders_present"]["manual"] is True
    assert report["ok"] is True


def test_demo_evidence_readiness_keeps_manual_artifacts_explicit():
    module = _load_demo_evidence_module()
    report = module.collect_demo_evidence_readiness(REPO_ROOT)

    manual_items = "\n".join(report["manualItems"])
    assert "真机截图" in manual_items
    assert "Demo 视频" in manual_items
    assert "PPT" in manual_items
    assert "比赛平台上传" in manual_items
