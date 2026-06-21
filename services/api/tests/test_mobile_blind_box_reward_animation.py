from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
PHOTO_PAGE = (
    REPO_ROOT / "apps" / "mobile" / "lib" / "features" / "photo" / "photo_page.dart"
)


def test_photo_page_animates_blind_box_reward_deltas():
    source = PHOTO_PAGE.read_text(encoding="utf-8")
    task_card_source = source.split("class _TaskCard", 1)[1].split(
        "class _TaskStatusPill", 1
    )[0]
    reward_card_source = source.split("class _RewardPulseCard", 1)[1].split(
        "class _TaskCard", 1
    )[0]

    assert "rewardDeltas" in task_card_source
    assert "AnimatedSwitcher" in task_card_source
    assert "_RewardPulseCard" in task_card_source
    assert "TweenAnimationBuilder" in reward_card_source
    assert "Transform.scale" in reward_card_source