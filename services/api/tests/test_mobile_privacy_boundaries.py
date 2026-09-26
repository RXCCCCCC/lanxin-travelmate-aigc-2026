from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
PHOTO_SERVICE = REPO_ROOT / "apps" / "mobile" / "lib" / "features" / "photo" / "data" / "photo_experience_service.dart"


def test_photo_upload_metadata_does_not_send_device_local_path_to_backend():
    source = PHOTO_SERVICE.read_text(encoding="utf-8")

    assert "'localPath': localPath" not in source
    assert '"localPath": localPath' not in source


def test_mobile_runtime_sources_do_not_log_private_media_or_audio_values():
    offenders: list[str] = []
    forbidden = ("print(", "debugPrint(", "developer.log(", "console.log(")
    for path in (REPO_ROOT / "apps" / "mobile" / "lib").rglob("*.dart"):
        source = path.read_text(encoding="utf-8")
        if any(token in source for token in forbidden):
            offenders.append(str(path.relative_to(REPO_ROOT)))

    assert offenders == []