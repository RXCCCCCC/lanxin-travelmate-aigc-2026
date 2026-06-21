from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
REVIEW_PAGE = (
    REPO_ROOT / "apps" / "mobile" / "lib" / "features" / "review" / "review_page.dart"
)


def test_review_page_renders_deep_review_fields_as_detail_cards():
    source = REVIEW_PAGE.read_text(encoding="utf-8")
    review_view_source = source.split("class _AgentReviewView", 1)[1].split(
        "String _avatarStateEventText", 1
    )[0]

    assert "reminderHighlights" in review_view_source
    assert "_ReviewDetailCard" in review_view_source
    assert "_reviewTaskDetails" in review_view_source
    assert "_reviewReminderDetails" in review_view_source
    assert "_reviewPromotionDetails" in review_view_source
    assert "completedAt" in review_view_source
    assert "suggestedScope" in review_view_source