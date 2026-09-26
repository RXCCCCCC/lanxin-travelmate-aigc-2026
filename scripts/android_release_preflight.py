"""Android release/build preflight checks for the Android-only Flutter app.

The script is intentionally read-only. It verifies repository invariants and
the local/CI Android SDK environment before running an APK build.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any


ANDROID_PLATFORM = "android-35"
ANDROID_BUILD_TOOLS = "35.0.0"
NON_ANDROID_PLATFORMS = ("ios", "macos", "windows", "linux", "web")


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def _extract_string_value(source: str, key: str) -> str | None:
    match = re.search(rf'{re.escape(key)}\s*=\s*"([^"]+)"', source)
    return match.group(1) if match else None


def _extract_gradle_value(source: str, key: str) -> str | None:
    match = re.search(rf"{re.escape(key)}\s*=\s*([^\n\r]+)", source)
    return match.group(1).strip() if match else None


def _sdk_root(repo_root: Path) -> Path | None:
    for env_name in ("ANDROID_HOME", "ANDROID_SDK_ROOT"):
        value = os.environ.get(env_name)
        if value:
            return Path(value)

    local_properties = repo_root / "apps" / "mobile" / "android" / "local.properties"
    for line in _read_text(local_properties).splitlines():
        if line.startswith("sdk.dir="):
            return Path(line.removeprefix("sdk.dir=").replace("\\\\", "\\"))
    return None


def collect_android_release_preflight(repo_root: Path) -> dict[str, Any]:
    mobile_root = repo_root / "apps" / "mobile"
    android_root = mobile_root / "android"
    build_gradle = android_root / "app" / "build.gradle.kts"
    local_properties = android_root / "local.properties"
    workflow = repo_root / ".github" / "workflows" / "ci.yml"

    gradle_source = _read_text(build_gradle)
    workflow_source = _read_text(workflow)
    sdk_root = _sdk_root(repo_root)

    non_android_dirs = [
        platform
        for platform in NON_ANDROID_PLATFORMS
        if (mobile_root / platform).exists()
    ]
    sdk_platform = sdk_root / "platforms" / ANDROID_PLATFORM if sdk_root else None
    build_tools = sdk_root / "build-tools" / ANDROID_BUILD_TOOLS if sdk_root else None

    checks = {
        "android_only_platform_shell": {
            "ok": not non_android_dirs,
            "detail": non_android_dirs,
        },
        "android_project_exists": {
            "ok": android_root.exists(),
            "detail": str(android_root),
        },
        "application_id": {
            "ok": _extract_string_value(gradle_source, "applicationId") is not None,
            "detail": _extract_string_value(gradle_source, "applicationId"),
        },
        "namespace": {
            "ok": _extract_string_value(gradle_source, "namespace") is not None,
            "detail": _extract_string_value(gradle_source, "namespace"),
        },
        "version_code": {
            "ok": _extract_gradle_value(gradle_source, "versionCode") is not None,
            "detail": _extract_gradle_value(gradle_source, "versionCode"),
        },
        "version_name": {
            "ok": _extract_gradle_value(gradle_source, "versionName") is not None,
            "detail": _extract_gradle_value(gradle_source, "versionName"),
        },
        "release_signing_not_final": {
            "ok": "signingConfigs.getByName(\"debug\")" in gradle_source,
            "detail": "release still uses debug signing; replace before final public release",
            "manual": True,
        },
        "local_properties_present": {
            "ok": local_properties.exists(),
            "detail": str(local_properties),
            "manual": True,
        },
        "sdk_root_resolved": {
            "ok": sdk_root is not None,
            "detail": str(sdk_root) if sdk_root else None,
        },
        "sdk_platform_35_installed": {
            "ok": bool(sdk_platform and sdk_platform.exists()),
            "detail": str(sdk_platform) if sdk_platform else None,
        },
        "build_tools_35_installed": {
            "ok": bool(build_tools and build_tools.exists()),
            "detail": str(build_tools) if build_tools else None,
        },
        "ci_apk_job_installs_sdk_35": {
            "ok": f'"platforms;{ANDROID_PLATFORM}"' in workflow_source
            and f'"build-tools;{ANDROID_BUILD_TOOLS}"' in workflow_source
            and "Android debug APK build" in workflow_source,
            "detail": ".github/workflows/ci.yml",
        },
        "ci_apk_job_runs_preflight": {
            "ok": "python scripts/android_release_preflight.py --strict" in workflow_source,
            "detail": ".github/workflows/ci.yml",
        },
    }
    return {
        "repoRoot": str(repo_root),
        "androidPlatform": ANDROID_PLATFORM,
        "androidBuildTools": ANDROID_BUILD_TOOLS,
        "checks": checks,
        "ok": all(item["ok"] or item.get("manual") for item in checks.values()),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=Path(__file__).resolve().parents[1])
    parser.add_argument("--strict", action="store_true", help="Return non-zero when any non-manual check fails.")
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON.")
    args = parser.parse_args()

    report = collect_android_release_preflight(Path(args.repo_root).resolve())
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"Android preflight for {report['repoRoot']}")
        for name, item in report["checks"].items():
            status = "OK" if item["ok"] else ("MANUAL" if item.get("manual") else "FAIL")
            print(f"[{status}] {name}: {item['detail']}")

    if args.strict:
        failed = [
            name
            for name, item in report["checks"].items()
            if not item["ok"] and not item.get("manual")
        ]
        if failed:
            print("Failed checks: " + ", ".join(failed), file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
