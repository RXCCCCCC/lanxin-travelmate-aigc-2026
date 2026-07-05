from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
TRIP_PAGE = (
    REPO_ROOT / "apps" / "mobile" / "lib" / "features" / "trip" / "trip_page.dart"
)


def test_trip_page_surfaces_external_context_and_tool_trace_metadata():
    source = TRIP_PAGE.read_text(encoding="utf-8")
    plan_view_source = source.split("class _AgentTripPlanView", 1)[1].split(
        "class _SectionHeader", 1
    )[0]

    assert "externalContext" in plan_view_source
    assert "toolTrace" in plan_view_source
    assert "_ToolContextCard" in plan_view_source
    assert "fallbackReason" in plan_view_source
    assert "errorType" in plan_view_source
    assert "cacheHit" in plan_view_source
    assert "circuitOpen" in plan_view_source
    assert "rateLimited" in plan_view_source