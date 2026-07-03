import importlib.util
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPT_PATH = REPO_ROOT / "scripts" / "submission_readiness_report.py"


def _load_submission_readiness_module():
    spec = importlib.util.spec_from_file_location("submission_readiness_report", SCRIPT_PATH)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_submission_readiness_report_aggregates_release_docs_and_preflights():
    module = _load_submission_readiness_module()
    report = module.collect_submission_readiness(
        REPO_ROOT,
        run_git=False,
        run_docker_config=False,
    )
    checks = report["checks"]

    assert checks["handoff_docs_present"]["ok"] is True
    assert checks["android_only_platform_shell"]["ok"] is True
    assert checks["todo_keeps_manual_scope"]["ok"] is True
    assert checks["shared_state_has_current_next_step"]["ok"] is True
    assert checks["submission_checklist_covers_real_capabilities"]["ok"] is True
    assert checks["prd_p0_demo_loop_covered"]["ok"] is True
    assert checks["competition_submission_materials_covered"]["ok"] is True
    assert checks["avatar_assets_transparent"]["ok"] is True
    assert checks["android_release_preflight"]["ok"] is True
    assert checks["android_device_readiness"]["manual"] is True
    assert "manifest_declares_runtime_permissions" in checks["android_device_readiness"]["detail"]
    assert checks["docker_compose_preflight"]["ok"] is True


def test_submission_readiness_report_covers_prd_and_competition_markers():
    module = _load_submission_readiness_module()
    report = module.collect_submission_readiness(
        REPO_ROOT,
        run_git=False,
        run_docker_config=False,
    )

    assert report["checks"]["prd_p0_demo_loop_covered"]["detail"] == {}
    assert report["checks"]["competition_submission_materials_covered"]["detail"] == {}


def test_submission_readiness_report_keeps_human_blockers_explicit():
    module = _load_submission_readiness_module()
    report = module.collect_submission_readiness(
        REPO_ROOT,
        run_git=False,
        run_docker_config=False,
    )
    blockers = "\n".join(report["manualBlockers"])

    assert "真实模型效果质量" in blockers
    assert "vivo/Android 真机" in blockers
    assert "release 正式签名" in blockers
    assert "比赛平台上传" in blockers
