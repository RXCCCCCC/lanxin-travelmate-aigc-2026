from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
ANDROID_MANIFEST = REPO_ROOT / "apps" / "mobile" / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
IOS_INFO_PLIST = REPO_ROOT / "apps" / "mobile" / "ios" / "Runner" / "Info.plist"


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


def test_ios_info_plist_declares_permission_usage_descriptions():
    source = IOS_INFO_PLIST.read_text(encoding="utf-8")

    for key in [
        "NSCameraUsageDescription",
        "NSPhotoLibraryUsageDescription",
        "NSMicrophoneUsageDescription",
        "NSLocationWhenInUseUsageDescription",
    ]:
        assert key in source
    assert "蓝心同行" in source