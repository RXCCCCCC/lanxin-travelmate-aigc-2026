from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
MOBILE_LIB = REPO_ROOT / "apps" / "mobile" / "lib"
ANDROID_MAIN = (
    REPO_ROOT
    / "apps"
    / "mobile"
    / "android"
    / "app"
    / "src"
    / "main"
    / "kotlin"
    / "com"
    / "lanxin"
    / "lanxin_travelmate"
    / "MainActivity.kt"
)
PHOTO_PAGE = MOBILE_LIB / "features" / "photo" / "photo_page.dart"
PHOTO_SERVICE = MOBILE_LIB / "features" / "photo" / "data" / "photo_selection_service.dart"


def test_flutter_photo_selection_service_uses_platform_channel():
    text = PHOTO_SERVICE.read_text(encoding="utf-8")

    assert "MethodChannel('lanxin_travelmate/photo_picker')" in text
    assert "Future<SelectedPhoto?> pickFromGallery()" in text
    assert "Future<SelectedPhoto?> takePhoto()" in text
    assert "localUri" in text


def test_photo_page_registers_real_selected_photo_without_uploading_local_path():
    text = PHOTO_PAGE.read_text(encoding="utf-8")

    assert "PhotoSelectionService" in text
    assert "pickFromGallery()" in text
    assert "takePhoto()" in text
    assert "Icons.photo_camera_rounded" in text
    assert "selected.localUri" in text
    assert "localPath:" not in text


def test_android_main_activity_handles_photo_picker_channel():
    text = ANDROID_MAIN.read_text(encoding="utf-8")

    assert "lanxin_travelmate/photo_picker" in text
    assert "pickFromGallery" in text
    assert "takePhoto" in text
    assert "Intent.ACTION_OPEN_DOCUMENT" in text
    assert "MediaStore.ACTION_IMAGE_CAPTURE" in text
    assert "contentResolver.getType" in text