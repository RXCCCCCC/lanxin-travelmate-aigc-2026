from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
MOBILE_LIB = REPO_ROOT / "apps" / "mobile" / "lib"


def _dart_sources() -> list[Path]:
    return sorted(MOBILE_LIB.rglob("*.dart"))


def test_mock_data_is_not_imported_by_mobile_runtime_pages():
    offenders: list[str] = []
    for path in _dart_sources():
        if path.name == "mock_data.dart":
            continue
        text = path.read_text(encoding="utf-8")
        if "mock_data.dart" in text or "mockTrip" in text or "mockMemory" in text:
            offenders.append(str(path.relative_to(REPO_ROOT)))

    assert offenders == []


def test_mobile_runtime_has_no_fixed_demo_trip_ids():
    offenders: list[str] = []
    for path in _dart_sources():
        if path.name == "mock_data.dart":
            continue
        text = path.read_text(encoding="utf-8")
        if "demo-chongqing-weekend" in text:
            offenders.append(str(path.relative_to(REPO_ROOT)))

    assert offenders == []


def test_mobile_runtime_has_no_fixed_review_fixture_content():
    fixture_markers = ["重庆夜景", "洪崖洞", "游客照", "成都慢节奏", "长沙夜景"]
    offenders: list[str] = []
    for path in _dart_sources():
        if path.name == "mock_data.dart":
            continue
        text = path.read_text(encoding="utf-8")
        if any(marker in text for marker in fixture_markers):
            offenders.append(str(path.relative_to(REPO_ROOT)))

    assert offenders == []

def test_mobile_runtime_has_no_fake_device_photo_uri():
    fixture_markers = ["device://selected-photo", "manual-night-photo.jpg"]
    offenders: list[str] = []
    for path in _dart_sources():
        if path.name == "mock_data.dart":
            continue
        text = path.read_text(encoding="utf-8")
        if any(marker in text for marker in fixture_markers):
            offenders.append(str(path.relative_to(REPO_ROOT)))

    assert offenders == []


def test_demo_agent_state_is_only_cross_page_agent_cache():
    text = (MOBILE_LIB / "data" / "demo_agent_state.dart").read_text(encoding="utf-8")

    assert "ValueNotifier<AgentChatResponse?>" in text
    assert "mock" not in text.lower()
    assert "demo-chongqing-weekend" not in text