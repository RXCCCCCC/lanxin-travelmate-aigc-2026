import importlib.util
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPT_PATH = REPO_ROOT / "scripts" / "android_device_readiness_report.py"


def _load_device_module():
    spec = importlib.util.spec_from_file_location("android_device_readiness_report", SCRIPT_PATH)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _result(stdout="", stderr="", returncode=0):
    return subprocess.CompletedProcess(args=["adb"], returncode=returncode, stdout=stdout, stderr=stderr)


def test_device_report_treats_missing_adb_as_manual_not_success():
    module = _load_device_module()

    def missing_adb(_args):
        raise FileNotFoundError("adb")

    report = module.collect_android_device_readiness(REPO_ROOT, adb_runner=missing_adb)
    checks = report["checks"]

    assert report["ok"] is True
    assert checks["manifest_declares_runtime_permissions"]["ok"] is True
    assert checks["adb_available"]["ok"] is False
    assert checks["adb_available"]["manual"] is True
    assert "adb executable not found" in checks["adb_available"]["detail"]


def test_device_report_collects_connected_vivo_device_and_permissions():
    module = _load_device_module()
    calls = []

    def fake_adb(args):
        calls.append(args)
        if args == ["devices", "-l"]:
            return _result("List of devices attached\nabc123 device product:vivo model:V2301 device:PD2301\n")
        if args[-2:] == ["getprop", "ro.build.version.sdk"]:
            return _result("35\n")
        if args[-2:] == ["getprop", "ro.product.brand"]:
            return _result("vivo\n")
        if args[-2:] == ["getprop", "ro.product.manufacturer"]:
            return _result("vivo\n")
        if args[-2:] == ["getprop", "ro.product.model"]:
            return _result("V2301A\n")
        if args[-2:] == ["getprop", "ro.product.device"]:
            return _result("PD2301\n")
        if args[-3:] == ["pm", "path", "com.lanxin.lanxin_travelmate"]:
            return _result("package:/data/app/~~abc/base.apk\n")
        if args[-2:] == ["reverse", "--list"]:
            return _result("abc123 tcp:8000 tcp:8000\n")
        if args[-3:] == ["dumpsys", "package", "com.lanxin.lanxin_travelmate"]:
            permissions = "\n".join(
                f"    {permission}\n    {permission}: granted=true"
                for permission in module.RUNTIME_PERMISSIONS
            )
            return _result(
                "versionCode=7 targetSdk=35\n"
                "versionName=0.7.0\n"
                "android.intent.action.MAIN\n"
                "android.intent.category.LAUNCHER\n"
                "    android.permission.INTERNET\n"
                f"{permissions}\n"
            )
        if "query-activities" in args:
            return _result("ActivityInfo{camera}\n")
        if "query-services" in args:
            return _result("ServiceInfo{service}\n")
        return _result("", returncode=1)

    report = module.collect_android_device_readiness(REPO_ROOT, adb_runner=fake_adb)
    checks = report["checks"]

    assert report["deviceSerial"] == "abc123"
    assert checks["single_online_device"]["ok"] is True
    assert checks["android_sdk_compatible"]["detail"]["sdkInt"] == 35
    assert checks["app_installed"]["ok"] is True
    assert checks["installed_package_metadata"]["detail"]["versionCode"] == 7
    assert checks["installed_package_metadata"]["detail"]["versionName"] == "0.7.0"
    assert checks["device_package_matches_manifest_permissions"]["detail"]["manifestOnly"] == []
    assert checks["runtime_permissions_granted_or_exercised"]["detail"]["missing"] == []
    assert checks["launch_activity_declared"]["ok"] is True
    assert checks["system_capabilities_queryable"]["ok"] is True
    assert any(call[-2:] == ["reverse", "--list"] for call in calls)


def test_device_report_surfaces_missing_runtime_grants_as_manual():
    module = _load_device_module()

    def fake_adb(args):
        if args == ["devices", "-l"]:
            return _result("List of devices attached\nabc123 device product:vivo model:V2301 device:PD2301\n")
        if args[-2:] == ["getprop", "ro.build.version.sdk"]:
            return _result("35\n")
        if args[-2:] == ["getprop", "ro.product.brand"]:
            return _result("vivo\n")
        if args[-2:] == ["getprop", "ro.product.manufacturer"]:
            return _result("vivo\n")
        if args[-2:] == ["getprop", "ro.product.model"]:
            return _result("V2301A\n")
        if args[-2:] == ["getprop", "ro.product.device"]:
            return _result("PD2301\n")
        if args[-3:] == ["pm", "path", "com.lanxin.lanxin_travelmate"]:
            return _result("package:/data/app/~~abc/base.apk\n")
        if args[-2:] == ["reverse", "--list"]:
            return _result("")
        if args[-3:] == ["dumpsys", "package", "com.lanxin.lanxin_travelmate"]:
            return _result(
                "versionCode=7 targetSdk=35\n"
                "versionName=0.7.0\n"
                "android.intent.action.MAIN\n"
                "android.intent.category.LAUNCHER\n"
                "    android.permission.ACCESS_FINE_LOCATION\n"
                "    android.permission.CAMERA: granted=true\n"
            )
        if "query-activities" in args:
            return _result("ActivityInfo{camera}\n")
        if "query-services" in args:
            return _result("ServiceInfo{service}\n")
        return _result("")

    report = module.collect_android_device_readiness(REPO_ROOT, adb_runner=fake_adb)
    permission_check = report["checks"]["runtime_permissions_granted_or_exercised"]

    assert permission_check["ok"] is False
    assert permission_check["manual"] is True
    assert "android.permission.ACCESS_FINE_LOCATION" in permission_check["detail"]["missing"]
