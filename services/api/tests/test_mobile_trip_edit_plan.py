from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
TRIP_PAGE = (
    REPO_ROOT / "apps" / "mobile" / "lib" / "features" / "trip" / "trip_page.dart"
)


def test_trip_page_can_return_from_plan_view_to_edit_form_with_existing_inputs():
    source = TRIP_PAGE.read_text(encoding="utf-8")
    state_source = source.split("class _TripPageState", 1)[1].split(
        "class _NoPlanStateCard", 1
    )[0]
    plan_view_source = source.split("class _AgentTripPlanView", 1)[1].split(
        "bool _hasExternalToolContext", 1
    )[0]

    assert "bool _editingPlan" in state_source
    assert "void _editCurrentPlan" in state_source
    assert "planningInputs" in state_source
    assert "_setCoordinateText" in state_source
    assert "_joinInputList" in state_source
    assert "visiblePlan = _editingPlan ? null : livePlan" in state_source
    assert "onEditPlan" in plan_view_source
    assert "trip-edit-current-plan" in source
    assert "_PlanEditActionCard" in source