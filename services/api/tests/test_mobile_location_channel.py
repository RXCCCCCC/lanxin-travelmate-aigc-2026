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
TRIP_PAGE = MOBILE_LIB / "features" / "trip" / "trip_page.dart"
LOCATION_SERVICE = MOBILE_LIB / "features" / "trip" / "data" / "location_selection_service.dart"


def test_flutter_location_selection_service_uses_platform_channel():
    text = LOCATION_SERVICE.read_text(encoding="utf-8")

    assert "MethodChannel('lanxin_travelmate/location')" in text
    assert "Future<SelectedLocation?> currentLocation()" in text
    assert "latitude" in text
    assert "longitude" in text
    assert "accuracyMeters" in text
    assert "lastFailureMessage" in text
    assert "location_permission_denied" in text
    assert "location_unavailable" in text


def test_trip_page_can_fill_origin_coordinate_from_current_location():
    text = TRIP_PAGE.read_text(encoding="utf-8")

    assert "LocationSelectionService" in text
    assert "currentLocation()" in text
    assert "originCoordinateController.text" in text
    assert "Icons.my_location_rounded" in text
    assert "真实定位" in text
    assert "_locationService.lastFailureMessage" in text


def test_android_main_activity_handles_location_channel():
    text = ANDROID_MAIN.read_text(encoding="utf-8")

    assert "lanxin_travelmate/location" in text
    assert "getCurrentLocation" in text
    assert "LocationManager" in text
    assert "ACCESS_FINE_LOCATION" in text
    assert "requestPermissions" in text
    assert "onRequestPermissionsResult" in text
    assert "location_permission_denied" in text
