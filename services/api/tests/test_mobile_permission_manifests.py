from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
ANDROID_MANIFEST = REPO_ROOT / "apps" / "mobile" / "android" / "app" / "src" / "main" / "AndroidManifest.xml"


def test_android_release_manifest_declares_runtime_permissions_needed_by_prd():
    source = ANDROID_MANIFEST.read_text(encoding="utf-8")

    for permission in [
        "android.permission.INTERNET",
        "android.permission.ACCESS_COARSE_LOCATION",
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.CAMERA",
        "android.permission.RECORD_AUDIO",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.READ_MEDIA_IMAGES",
    ]:
        assert permission in source
    assert "android.permission.READ_EXTERNAL_STORAGE" in source
    assert "android:maxSdkVersion=\"32\"" in source