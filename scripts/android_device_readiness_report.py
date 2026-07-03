"""Read-only Android/vivo device readiness report.

The script only queries adb/device state. It never installs APKs, starts the
app, grants permissions, or changes device settings.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

ANDROID_NS = "{http://schemas.android.com/apk/res/android}"
DEFAULT_PACKAGE_NAME = "com.lanxin.lanxin_travelmate"
RUNTIME_PERMISSIONS = (
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.CAMERA",
    "android.permission.RECORD_AUDIO",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.READ_MEDIA_IMAGES",
    "android.permission.READ_EXTERNAL_STORAGE",
)
DEVICE_MARKERS = ("vivo", "Vivo", "VIVO", "iQOO", "IQOO", "PD")
SYSTEM_CAPABILITY_QUERIES = {
    "camera_capture_intent": [
        "cmd",
        "package",
        "query-activities",
        "-a",
        "android.media.action.IMAGE_CAPTURE",
    ],
    "image_pick_intent": [
        "cmd",
        "package",
        "query-activities",
        "-a",
        "android.intent.action.GET_CONTENT",
        "-t",
        "image/*",
    ],
    "speech_recognition_service": [
        "cmd",
        "package",
        "query-services",
        "-a",
        "android.speech.RecognitionService",
    ],
    "tts_service": [
        "cmd",
        "package",
        "query-services",
        "-a",
        "android.intent.action.TTS_SERVICE",
    ],
}

PLATFORM_FILTERED_PERMISSIONS = {
    "android.permission.READ_EXTERNAL_STORAGE": {
        "minSdk": 33,
        "reason": "Android 13+ replaces legacy external storage reads with scoped media permissions.",
    },
}


def _run_adb(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["adb", *args],
        capture_output=True,
        text=True,
        check=False,
    )


def _manual(ok: bool, detail: Any) -> dict[str, Any]:
    return {"ok": ok, "manual": True, "detail": detail}


def _check(ok: bool, detail: Any) -> dict[str, Any]:
    return {"ok": ok, "detail": detail}


def _trim_output(text: str, *, max_chars: int = 800) -> str:
    clean = text.strip()
    if len(clean) <= max_chars:
        return clean
    return clean[:max_chars].rstrip() + "...[truncated]"


def _manifest_permissions(repo_root: Path) -> list[str]:
    manifest = repo_root / "apps" / "mobile" / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest.exists():
        return []
    root = ET.fromstring(manifest.read_text(encoding="utf-8"))
    permissions = []
    for item in root.findall("uses-permission"):
        name = item.attrib.get(f"{ANDROID_NS}name")
        if name:
            permissions.append(name)
    return permissions


def _parse_devices(output: str) -> list[dict[str, str]]:
    devices: list[dict[str, str]] = []
    for line in output.splitlines()[1:]:
        line = line.strip()
        if not line:
            continue
        parts = line.split(None, 1)
        serial = parts[0]
        rest = parts[1] if len(parts) > 1 else ""
        state = rest.split(None, 1)[0] if rest else ""
        devices.append({"serial": serial, "state": state, "raw": line})
    return devices


def _granted_permissions(dumpsys_output: str) -> set[str]:
    granted: set[str] = set()
    for line in dumpsys_output.splitlines():
        line = line.strip()
        match = re.match(r"(android\.permission\.[A-Z0-9_]+):\s+granted=(true|false)", line)
        if match and match.group(2) == "true":
            granted.add(match.group(1))
    return granted


def _requested_permissions(dumpsys_output: str) -> set[str]:
    requested: set[str] = set()
    for line in dumpsys_output.splitlines():
        text = line.strip()
        if text.startswith("android.permission."):
            requested.add(text.split(":", 1)[0])
    return requested


def _parse_package_metadata(dumpsys_output: str) -> dict[str, Any]:
    metadata: dict[str, Any] = {}
    patterns = {
        "versionCode": r"versionCode=(\d+)",
        "versionName": r"versionName=([^\s]+)",
        "targetSdk": r"targetSdk=(\d+)",
        "firstInstallTime": r"firstInstallTime=([^\n\r]+)",
        "lastUpdateTime": r"lastUpdateTime=([^\n\r]+)",
    }
    for key, pattern in patterns.items():
        match = re.search(pattern, dumpsys_output)
        if match:
            value = match.group(1).strip()
            metadata[key] = int(value) if value.isdigit() else value
    metadata["debuggable"] = "DEBUGGABLE" in dumpsys_output or "debuggable=true" in dumpsys_output
    return metadata


def _parse_sdk_int(output: str) -> int | None:
    text = output.strip()
    return int(text) if text.isdigit() else None


def _platform_filtered_permissions(
    permissions: list[str],
    *,
    sdk_int: int | None,
) -> dict[str, str]:
    filtered: dict[str, str] = {}
    for permission in permissions:
        rule = PLATFORM_FILTERED_PERMISSIONS.get(permission)
        if rule and sdk_int and sdk_int >= rule["minSdk"]:
            filtered[permission] = rule["reason"]
    return filtered


def collect_android_device_readiness(
    repo_root: Path,
    *,
    package_name: str = DEFAULT_PACKAGE_NAME,
    adb_runner=_run_adb,
) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    manifest_permissions = _manifest_permissions(repo_root)
    checks: dict[str, dict[str, Any]] = {
        "manifest_declares_runtime_permissions": _check(
            all(permission in manifest_permissions for permission in RUNTIME_PERMISSIONS),
            {
                "declared": manifest_permissions,
                "required": list(RUNTIME_PERMISSIONS),
            },
        )
    }

    try:
        devices_result = adb_runner(["devices", "-l"])
    except FileNotFoundError:
        checks["adb_available"] = _manual(False, "adb executable not found")
        return {
            "repoRoot": str(repo_root),
            "packageName": package_name,
            "checks": checks,
            "manualActions": _manual_actions(package_name),
            "ok": all(item["ok"] or item.get("manual") for item in checks.values()),
        }

    checks["adb_available"] = _check(devices_result.returncode == 0, devices_result.stderr.strip())
    devices = _parse_devices(devices_result.stdout)
    online_devices = [device for device in devices if device["state"] == "device"]
    checks["single_online_device"] = _manual(
        len(online_devices) == 1,
        {"online": online_devices, "all": devices},
    )

    if len(online_devices) != 1:
        return {
            "repoRoot": str(repo_root),
            "packageName": package_name,
            "checks": checks,
            "manualActions": _manual_actions(package_name),
            "ok": all(item["ok"] or item.get("manual") for item in checks.values()),
        }

    serial = online_devices[0]["serial"]
    shell_prefix = ["-s", serial, "shell"]

    sdk_result = adb_runner([*shell_prefix, "getprop", "ro.build.version.sdk"])
    sdk_int = _parse_sdk_int(sdk_result.stdout)
    checks["android_sdk_compatible"] = _manual(
        bool(sdk_int and sdk_int >= 23),
        {"sdkInt": sdk_int, "stderr": sdk_result.stderr.strip()},
    )

    device_props = {
        "brand": "ro.product.brand",
        "manufacturer": "ro.product.manufacturer",
        "model": "ro.product.model",
        "device": "ro.product.device",
    }
    device_info: dict[str, str] = {}
    for key, prop_name in device_props.items():
        prop_result = adb_runner([*shell_prefix, "getprop", prop_name])
        device_info[key] = prop_result.stdout.strip()
    combined_device_text = " ".join(device_info.values())
    checks["vivo_or_android_device_identified"] = _manual(
        any(marker in combined_device_text for marker in DEVICE_MARKERS) or bool(combined_device_text.strip()),
        device_info,
    )

    package_result = adb_runner([*shell_prefix, "pm", "path", package_name])
    app_installed = package_result.returncode == 0 and f"package:" in package_result.stdout
    checks["app_installed"] = _manual(
        app_installed,
        {"package": package_name, "stdout": package_result.stdout.strip(), "stderr": package_result.stderr.strip()},
    )

    reverse_result = adb_runner(["-s", serial, "reverse", "--list"])
    reverse_entries = [line for line in reverse_result.stdout.splitlines() if line.strip()]
    checks["adb_reverse_visible"] = _manual(
        reverse_result.returncode == 0,
        {"entries": reverse_entries, "stderr": reverse_result.stderr.strip()},
    )

    if app_installed:
        dumpsys_result = adb_runner([*shell_prefix, "dumpsys", "package", package_name])
        granted = _granted_permissions(dumpsys_result.stdout)
        requested = _requested_permissions(dumpsys_result.stdout)
        package_metadata = _parse_package_metadata(dumpsys_result.stdout)
        expected_runtime = [permission for permission in RUNTIME_PERMISSIONS if permission in manifest_permissions]
        platform_filtered = _platform_filtered_permissions(
            list(dict.fromkeys([*manifest_permissions, *expected_runtime])),
            sdk_int=sdk_int,
        )
        missing_grants = [
            permission
            for permission in expected_runtime
            if permission not in granted and permission not in platform_filtered
        ]
        missing_requested = [
            permission
            for permission in manifest_permissions
            if permission not in requested and permission not in platform_filtered
        ]
        checks["runtime_permissions_queryable"] = _manual(
            dumpsys_result.returncode == 0,
            {"stderr": dumpsys_result.stderr.strip()},
        )
        checks["installed_package_metadata"] = _manual(
            bool(package_metadata.get("versionCode") and package_metadata.get("versionName")),
            package_metadata,
        )
        checks["device_package_matches_manifest_permissions"] = _manual(
            not missing_requested,
            {
                "requested": sorted(requested),
                "manifestOnly": missing_requested,
                "ignoredByPlatform": sorted(platform_filtered),
                "ignoredReasons": platform_filtered,
            },
        )
        checks["runtime_permissions_granted_or_exercised"] = _manual(
            not missing_grants,
            {
                "granted": sorted(granted),
                "missing": missing_grants,
                "ignoredByPlatform": sorted(platform_filtered),
                "ignoredReasons": platform_filtered,
            },
        )
        checks["launch_activity_declared"] = _manual(
            "android.intent.action.MAIN" in dumpsys_result.stdout
            and "android.intent.category.LAUNCHER" in dumpsys_result.stdout,
            "MAIN/LAUNCHER in dumpsys package output",
        )
        capability_details: dict[str, Any] = {}
        for name, query in SYSTEM_CAPABILITY_QUERIES.items():
            result = adb_runner([*shell_prefix, *query])
            capability_details[name] = {
                "ok": result.returncode == 0 and bool(result.stdout.strip()),
                "stdout": _trim_output(result.stdout),
                "stderr": _trim_output(result.stderr),
            }
        checks["system_capabilities_queryable"] = _manual(
            all(item["ok"] for item in capability_details.values()),
            capability_details,
        )

    return {
        "repoRoot": str(repo_root),
        "packageName": package_name,
        "deviceSerial": serial,
        "checks": checks,
        "manualActions": _manual_actions(package_name),
        "ok": all(item["ok"] or item.get("manual") for item in checks.values()),
    }


def _manual_actions(package_name: str) -> list[str]:
    return [
        f"Install a signed/debug APK on the target vivo/Android device and confirm package {package_name}.",
        "Exercise gallery, camera, location, microphone, notification, speech recognition, and TTS flows on-device.",
        "Confirm appops/permission denial behavior through real UI interactions; the script only reads current state.",
        "Capture screenshots/video that show permission denial states do not white-screen or crash.",
        "Keep secret values, private locations, team privacy, and unauthorized media out of demo recordings.",
    ]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=Path(__file__).resolve().parents[1])
    parser.add_argument("--package-name", default=DEFAULT_PACKAGE_NAME)
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = collect_android_device_readiness(
        Path(args.repo_root),
        package_name=args.package_name,
    )
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"Android device readiness for {report['packageName']}")
        for name, item in report["checks"].items():
            status = "OK" if item["ok"] else ("MANUAL" if item.get("manual") else "FAIL")
            print(f"[{status}] {name}: {item['detail']}")
        print("Manual actions:")
        for action in report["manualActions"]:
            print(f"- {action}")

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
