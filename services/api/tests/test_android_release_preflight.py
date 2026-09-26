import importlib.util
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPT_PATH = REPO_ROOT / "scripts" / "android_release_preflight.py"
WORKFLOW = REPO_ROOT / ".github" / "workflows" / "ci.yml"


def _load_preflight_module():
    spec = importlib.util.spec_from_file_location("android_release_preflight", SCRIPT_PATH)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_android_release_preflight_checks_android_only_and_release_metadata():
    module = _load_preflight_module()
    report = module.collect_android_release_preflight(REPO_ROOT)
    checks = report["checks"]

    assert checks["android_only_platform_shell"]["ok"] is True
    assert checks["android_project_exists"]["ok"] is True
    assert checks["application_id"]["detail"] == "com.lanxin.lanxin_travelmate"
    assert checks["namespace"]["detail"] == "com.lanxin.lanxin_travelmate"
    assert checks["version_code"]["ok"] is True
    assert checks["version_name"]["ok"] is True
    assert checks["release_signing_not_final"]["manual"] is True


def test_ci_android_apk_job_installs_sdk_35_and_runs_preflight():
    workflow = WORKFLOW.read_text(encoding="utf-8")

    assert "Android debug APK build" in workflow
    assert "android-actions/setup-android@v3" in workflow
    assert 'sdkmanager "platforms;android-35" "build-tools;35.0.0"' in workflow
    assert "python scripts/android_release_preflight.py --strict" in workflow
