from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
TRIP_PAGE = REPO_ROOT / "apps" / "mobile" / "lib" / "features" / "trip" / "trip_page.dart"


def test_group_coordination_result_card_surfaces_privacy_summary_without_raw_sensitive_text():
    source = TRIP_PAGE.read_text(encoding="utf-8")
    card_source = source.split("class _GroupCoordinationResultCard", 1)[1].split("class _TripPlanInputCard", 1)[0]

    assert "sensitiveMemberDetailsHidden" in card_source
    assert "sensitiveMemberCount" in card_source
    assert "publicRule" in card_source
    assert "sensitivePreferences" not in card_source